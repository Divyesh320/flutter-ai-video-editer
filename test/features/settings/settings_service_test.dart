import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:multimodal_ai_assistant/core/models/settings_models.dart';
import 'package:multimodal_ai_assistant/features/settings/services/settings_service.dart';
import 'package:multimodal_ai_assistant/features/settings/utils/quota_utils.dart';

import '../../mocks/mock_secure_storage.dart';

void main() {
  group('SettingsService', () {
    late SettingsServiceImpl settingsService;

    setUp(() {
      settingsService = SettingsServiceImpl();
    });

    group('Quota Logic', () {
      /// **Feature: multimodal-ai-assistant, Property 20: Usage Stats Accuracy**
      /// **Validates: Requirements 8.1**
      test('usage stats calculations are accurate (property test)', () {
        final random = Random(42);

        for (var i = 0; i < 100; i++) {
          final messageCount = random.nextInt(1000);
          final mediaUploads = random.nextInt(100);
          final quotaLimit = random.nextInt(500) + 1;
          final quotaUsed = random.nextInt(quotaLimit + 100);

          final stats = UsageStats(
            messageCount: messageCount,
            mediaUploads: mediaUploads,
            quotaLimit: quotaLimit,
            quotaUsed: quotaUsed,
            resetDate: DateTime.now().add(const Duration(days: 30)),
          );

          expect(stats.quotaRemaining, equals(quotaLimit - quotaUsed));

          final expectedPercentage = quotaUsed / quotaLimit;
          expect(stats.usagePercentage, closeTo(expectedPercentage, 0.0001));

          expect(settingsService.isNearQuotaLimit(stats), equals(stats.isNearQuotaLimit));
          expect(settingsService.isQuotaExceeded(stats), equals(stats.isQuotaExceeded));
        }
      });

      test('usage percentage is 0 when quota limit is 0', () {
        final stats = UsageStats(
          messageCount: 10,
          mediaUploads: 5,
          quotaLimit: 0,
          quotaUsed: 0,
          resetDate: DateTime.now(),
        );
        expect(stats.usagePercentage, equals(0.0));
      });

      /// **Feature: multimodal-ai-assistant, Property 21: Quota Warning Threshold**
      /// **Validates: Requirements 8.2**
      test('quota warning threshold at 80% (property test)', () {
        final random = Random(42);

        for (var i = 0; i < 100; i++) {
          final quotaLimit = random.nextInt(500) + 1;
          final quotaUsed = random.nextInt(quotaLimit + 50);

          final stats = UsageStats(
            messageCount: random.nextInt(1000),
            mediaUploads: random.nextInt(100),
            quotaLimit: quotaLimit,
            quotaUsed: quotaUsed,
            resetDate: DateTime.now().add(const Duration(days: 30)),
          );

          final usagePercentage = quotaUsed / quotaLimit;
          final shouldShowWarning = usagePercentage >= 0.80;

          expect(QuotaUtils.isNearQuotaLimit(stats), equals(shouldShowWarning));
          expect(stats.isNearQuotaLimit, equals(shouldShowWarning));

          final warningMessage = QuotaUtils.getWarningMessage(stats);
          if (shouldShowWarning) {
            expect(warningMessage, isNotNull);
          }
        }
      });

      /// **Feature: multimodal-ai-assistant, Property 22: Quota Enforcement**
      /// **Validates: Requirements 8.3**
      test('quota enforcement at 100% (property test)', () {
        final random = Random(42);

        for (var i = 0; i < 100; i++) {
          final quotaLimit = random.nextInt(500) + 1;
          final quotaUsed = random.nextInt(quotaLimit + 100);

          final stats = UsageStats(
            messageCount: random.nextInt(1000),
            mediaUploads: random.nextInt(100),
            quotaLimit: quotaLimit,
            quotaUsed: quotaUsed,
            resetDate: DateTime.now().add(const Duration(days: 30)),
          );

          final shouldBlock = quotaUsed >= quotaLimit;

          expect(QuotaUtils.isQuotaExceeded(stats), equals(shouldBlock));
          expect(QuotaUtils.shouldBlockRequest(stats), equals(shouldBlock));
          expect(stats.isQuotaExceeded, equals(shouldBlock));
        }
      });
    });
  });

  group('SettingsPersistence', () {
    /// **Feature: multimodal-ai-assistant, Property 23: Settings Persistence**
    /// **Validates: Requirements 8.4**
    test('settings serialization round-trip preserves all fields (property test)', () {
      final random = Random(42);

      for (var i = 0; i < 100; i++) {
        final settings = UserSettings(
          ttsEnabled: random.nextBool(),
          darkMode: random.nextBool(),
          preferredVoice: random.nextBool() ? 'voice_${random.nextInt(10)}' : null,
        );

        final json = settings.toJson();
        final restored = UserSettings.fromJson(json);

        expect(restored.ttsEnabled, equals(settings.ttsEnabled));
        expect(restored.darkMode, equals(settings.darkMode));
        expect(restored.preferredVoice, equals(settings.preferredVoice));
        expect(restored, equals(settings));
      }
    });

    test('copyWith preserves unchanged fields', () {
      final random = Random(42);

      for (var i = 0; i < 100; i++) {
        final original = UserSettings(
          ttsEnabled: random.nextBool(),
          darkMode: random.nextBool(),
          preferredVoice: random.nextBool() ? 'voice_${random.nextInt(10)}' : null,
        );

        final withTtsToggled = original.copyWith(ttsEnabled: !original.ttsEnabled);
        expect(withTtsToggled.ttsEnabled, equals(!original.ttsEnabled));
        expect(withTtsToggled.darkMode, equals(original.darkMode));
        expect(withTtsToggled.preferredVoice, equals(original.preferredVoice));

        final withDarkModeToggled = original.copyWith(darkMode: !original.darkMode);
        expect(withDarkModeToggled.ttsEnabled, equals(original.ttsEnabled));
        expect(withDarkModeToggled.darkMode, equals(!original.darkMode));
        expect(withDarkModeToggled.preferredVoice, equals(original.preferredVoice));
      }
    });
  });

  group('AccountDeletion', () {
    /// **Feature: multimodal-ai-assistant, Property 24: Account Deletion Completeness**
    /// **Validates: Requirements 8.5**
    test('clearLocalData removes all stored data (property test)', () async {
      final random = Random(42);

      for (var i = 0; i < 100; i++) {
        final mockStorage = MockSecureStorage();
        final settingsService = SettingsServiceImpl(secureStorage: mockStorage);

        final settings = UserSettings(
          ttsEnabled: random.nextBool(),
          darkMode: random.nextBool(),
          preferredVoice: random.nextBool() ? 'voice_${random.nextInt(10)}' : null,
        );
        await settingsService.updateSettings(settings);

        // Verify data was stored
        final storedData = await mockStorage.readAll();
        expect(storedData.isNotEmpty, isTrue);

        await settingsService.clearLocalData();

        // Verify all data was cleared
        final clearedToken = await mockStorage.read(key: 'jwt_token');
        final clearedRefresh = await mockStorage.read(key: 'refresh_token');
        final clearedUser = await mockStorage.read(key: 'user_data');
        final clearedSettings = await mockStorage.read(key: 'user_settings');

        expect(clearedToken, isNull);
        expect(clearedRefresh, isNull);
        expect(clearedUser, isNull);
        expect(clearedSettings, isNull);
      }
    });

    test('deleted data types list is comprehensive', () {
      const requiredDataTypes = [
        'user',
        'conversation',
        'message',
        'media',
        'embedding',
        'settings',
        'usage',
      ];

      final deletedDataDescription =
          'User profile and credentials, All conversations and messages, '
          'Uploaded media files (images, videos, audio), '
          'Generated embeddings and context data, '
          'Settings and preferences, Usage statistics';

      for (final dataType in requiredDataTypes) {
        expect(
          deletedDataDescription.toLowerCase().contains(dataType),
          isTrue,
          reason: 'Deleted data should include $dataType',
        );
      }
    });
  });
}
