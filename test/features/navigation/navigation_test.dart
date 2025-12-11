import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multimodal_ai_assistant/features/navigation/navigation.dart';

void main() {
  group('Navigation Providers', () {
    test('navigationIndexProvider defaults to 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(navigationIndexProvider), equals(0));
    });

    test('navigationIndexProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(navigationIndexProvider.notifier).state = 1;
      expect(container.read(navigationIndexProvider), equals(1));

      container.read(navigationIndexProvider.notifier).state = 2;
      expect(container.read(navigationIndexProvider), equals(2));
    });

    test('deepLinkConversationProvider defaults to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(deepLinkConversationProvider), isNull);
    });

    test('deepLinkConversationProvider can store conversation ID', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(deepLinkConversationProvider.notifier).state = 'conv-123';
      expect(container.read(deepLinkConversationProvider), equals('conv-123'));
    });
  });

  group('HomeScreen', () {
    testWidgets('displays quick action buttons', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: HomeScreen()),
        ),
      );
      // Use pump with duration to allow initial frame to render
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('New Chat'), findsOneWidget);
      expect(find.text('Voice'), findsOneWidget);
      expect(find.text('Image'), findsOneWidget);
      expect(find.text('Video'), findsOneWidget);
    });

    testWidgets('displays recent conversations header', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: HomeScreen()),
        ),
      );
      // Use pump with duration to allow initial frame to render
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Recent Conversations'), findsOneWidget);
      expect(find.text('See All'), findsOneWidget);
    });
  });

  group('RadialFabMenu', () {
    testWidgets('renders FAB widget', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              floatingActionButton: RadialFabMenu(),
            ),
          ),
        ),
      );
      await tester.pump();

      // FAB should be present
      expect(find.byType(FloatingActionButton), findsWidgets);
      expect(find.byType(RadialFabMenu), findsOneWidget);
    });

    testWidgets('contains add icon initially', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              floatingActionButton: RadialFabMenu(),
            ),
          ),
        ),
      );
      await tester.pump();

      // Should show add icon
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });

  group('EmptyStateWidget', () {
    testWidgets('displays icon, title, and subtitle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.chat_bubble_outline,
              title: 'No conversations',
              subtitle: 'Start a new conversation',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
      expect(find.text('No conversations'), findsOneWidget);
      expect(find.text('Start a new conversation'), findsOneWidget);
    });

    testWidgets('displays action button when provided', (tester) async {
      var actionCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.error_outline,
              title: 'Error',
              subtitle: 'Something went wrong',
              actionLabel: 'Retry',
              onAction: () => actionCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      expect(actionCalled, isTrue);
    });
  });

  group('SkeletonLoader', () {
    testWidgets('renders list tile skeleton', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonLoader(type: SkeletonType.listTile),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SkeletonLoader), findsOneWidget);
    });

    testWidgets('renders card skeleton', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonLoader(type: SkeletonType.card),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SkeletonLoader), findsOneWidget);
    });
  });

  group('QuickActionButton', () {
    testWidgets('displays icon and label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickActionButton(
              icon: Icons.chat,
              label: 'Chat',
              color: Colors.blue,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.chat), findsOneWidget);
      expect(find.text('Chat'), findsOneWidget);
    });

    testWidgets('calls onTap when pressed', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickActionButton(
              icon: Icons.chat,
              label: 'Chat',
              color: Colors.blue,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(QuickActionButton));
      expect(tapped, isTrue);
    });
  });
}


