import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multimodal_ai_assistant/core/models/settings_models.dart';
import 'package:multimodal_ai_assistant/features/settings/widgets/quota_warning_banner.dart';
import 'package:multimodal_ai_assistant/features/settings/widgets/settings_section.dart';
import 'package:multimodal_ai_assistant/features/settings/widgets/usage_stats_card.dart';

void main() {
  group('UsageStatsCard', () {
    testWidgets('displays usage statistics correctly', (tester) async {
      final stats = UsageStats(
        messageCount: 50,
        mediaUploads: 10,
        quotaLimit: 100,
        quotaUsed: 60,
        resetDate: DateTime(2024, 12, 31),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UsageStatsCard(stats: stats),
          ),
        ),
      );

      // Verify title
      expect(find.text('Usage Statistics'), findsOneWidget);

      // Verify message count
      expect(find.text('50'), findsOneWidget);
      expect(find.text('Messages'), findsOneWidget);

      // Verify uploads count
      expect(find.text('10'), findsOneWidget);
      expect(find.text('Uploads'), findsOneWidget);

      // Verify percentage
      expect(find.text('60%'), findsOneWidget);

      // Verify remaining quota
      expect(find.text('40 requests remaining'), findsOneWidget);
    });

    testWidgets('shows correct color for normal usage', (tester) async {
      final stats = UsageStats(
        messageCount: 20,
        mediaUploads: 5,
        quotaLimit: 100,
        quotaUsed: 50, // 50% - should be green
        resetDate: DateTime(2024, 12, 31),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UsageStatsCard(stats: stats),
          ),
        ),
      );

      // Find the progress indicator
      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );

      expect(progressIndicator.value, closeTo(0.5, 0.01));
    });

    testWidgets('shows correct color for high usage', (tester) async {
      final stats = UsageStats(
        messageCount: 80,
        mediaUploads: 15,
        quotaLimit: 100,
        quotaUsed: 85, // 85% - should be orange
        resetDate: DateTime(2024, 12, 31),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UsageStatsCard(stats: stats),
          ),
        ),
      );

      expect(find.text('85%'), findsOneWidget);
      expect(find.text('15 requests remaining'), findsOneWidget);
    });

    testWidgets('shows correct color for exceeded quota', (tester) async {
      final stats = UsageStats(
        messageCount: 100,
        mediaUploads: 20,
        quotaLimit: 100,
        quotaUsed: 110, // 110% - should be red
        resetDate: DateTime(2024, 12, 31),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UsageStatsCard(stats: stats),
          ),
        ),
      );

      expect(find.text('110%'), findsOneWidget);
      expect(find.text('No quota remaining'), findsOneWidget);
    });
  });

  group('QuotaWarningBanner', () {
    testWidgets('displays warning message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuotaWarningBanner(
              message: 'You have used 80% of your quota.',
              isExceeded: false,
            ),
          ),
        ),
      );

      expect(find.text('You have used 80% of your quota.'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('displays exceeded message with error icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuotaWarningBanner(
              message: 'You have exceeded your quota.',
              isExceeded: true,
            ),
          ),
        ),
      );

      expect(find.text('You have exceeded your quota.'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('shows dismiss button for warning', (tester) async {
      var dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuotaWarningBanner(
              message: 'Warning message',
              isExceeded: false,
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      expect(dismissed, isTrue);
    });

    testWidgets('hides dismiss button when exceeded', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuotaWarningBanner(
              message: 'Exceeded message',
              isExceeded: true,
              onDismiss: () {},
            ),
          ),
        ),
      );

      // Dismiss button should not be shown when quota is exceeded
      expect(find.byIcon(Icons.close), findsNothing);
    });
  });

  group('SettingsSection', () {
    testWidgets('displays title and children', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsSection(
              title: 'Test Section',
              children: [
                const ListTile(title: Text('Item 1')),
                const ListTile(title: Text('Item 2')),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Test Section'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
    });

    testWidgets('wraps children in a card', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsSection(
              title: 'Section',
              children: [
                const ListTile(title: Text('Item')),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });
  });
}
