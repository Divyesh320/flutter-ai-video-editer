import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:multimodal_ai_assistant/core/services/services.dart';

import '../../mocks/mock_secure_storage.dart';

void main() {
  group('OfflineQueueManager', () {
    late MockSecureStorage mockStorage;
    late OfflineQueueManager queueManager;

    setUp(() {
      mockStorage = MockSecureStorage();
      queueManager = OfflineQueueManager(secureStorage: mockStorage);
    });

    test('adds and retrieves requests', () async {
      final request = QueuedRequest(
        id: '1',
        method: 'POST',
        path: '/chat',
        data: {'message': 'Hello'},
        createdAt: DateTime.now(),
      );

      await queueManager.addRequest(request);
      final pending = await queueManager.getPendingRequests();

      expect(pending.length, equals(1));
      expect(pending.first.id, equals('1'));
      expect(pending.first.path, equals('/chat'));
    });

    test('removes requests by id', () async {
      final request1 = QueuedRequest(
        id: '1',
        method: 'POST',
        path: '/chat',
        createdAt: DateTime.now(),
      );
      final request2 = QueuedRequest(
        id: '2',
        method: 'POST',
        path: '/upload',
        createdAt: DateTime.now(),
      );

      await queueManager.addRequest(request1);
      await queueManager.addRequest(request2);
      await queueManager.removeRequest('1');

      final pending = await queueManager.getPendingRequests();
      expect(pending.length, equals(1));
      expect(pending.first.id, equals('2'));
    });

    test('clears all requests', () async {
      await queueManager.addRequest(QueuedRequest(
        id: '1',
        method: 'POST',
        path: '/chat',
        createdAt: DateTime.now(),
      ));
      await queueManager.addRequest(QueuedRequest(
        id: '2',
        method: 'POST',
        path: '/upload',
        createdAt: DateTime.now(),
      ));

      await queueManager.clearQueue();
      final pending = await queueManager.getPendingRequests();

      expect(pending, isEmpty);
    });

    test('preserves request order by creation time', () async {
      final now = DateTime.now();
      final request1 = QueuedRequest(
        id: '1',
        method: 'POST',
        path: '/first',
        createdAt: now,
      );
      final request2 = QueuedRequest(
        id: '2',
        method: 'POST',
        path: '/second',
        createdAt: now.add(const Duration(seconds: 1)),
      );
      final request3 = QueuedRequest(
        id: '3',
        method: 'POST',
        path: '/third',
        createdAt: now.add(const Duration(seconds: 2)),
      );

      // Add in random order
      await queueManager.addRequest(request2);
      await queueManager.addRequest(request1);
      await queueManager.addRequest(request3);

      final pending = await queueManager.getPendingRequests();
      expect(pending[0].id, equals('1'));
      expect(pending[1].id, equals('2'));
      expect(pending[2].id, equals('3'));
    });
  });


  group('Property Tests', () {
    /// **Property 29: Offline Message Queue**
    /// For any message sent while offline, the message SHALL be stored in
    /// local queue AND automatically synced to the server when connectivity
    /// is restored, preserving message order.
    group('Property 29: Offline Message Queue', () {
      test('messages are queued and preserve order (100 iterations)', () async {
        final random = Random(42);

        for (var i = 0; i < 100; i++) {
          final mockStorage = MockSecureStorage();
          final queueManager = OfflineQueueManager(secureStorage: mockStorage);

          // Generate random number of messages (1-20)
          final messageCount = random.nextInt(20) + 1;
          final baseTime = DateTime.now();
          final requests = <QueuedRequest>[];

          // Create requests with sequential timestamps
          for (var j = 0; j < messageCount; j++) {
            final request = QueuedRequest(
              id: 'msg_$j',
              method: 'POST',
              path: '/chat',
              data: {'message': 'Message $j', 'index': j},
              createdAt: baseTime.add(Duration(milliseconds: j * 100)),
            );
            requests.add(request);
          }

          // Add requests in random order
          final shuffled = List<QueuedRequest>.from(requests)..shuffle(random);
          for (final request in shuffled) {
            await queueManager.addRequest(request);
          }

          // Verify all messages are queued
          final pending = await queueManager.getPendingRequests();
          expect(pending.length, equals(messageCount),
              reason: 'All messages should be queued');

          // Verify order is preserved (sorted by createdAt)
          for (var j = 0; j < pending.length; j++) {
            expect(pending[j].id, equals('msg_$j'),
                reason: 'Messages should be in creation order');
          }

          // Clean up for next iteration
          await queueManager.clearQueue();
        }
      });


      test('queue persists across manager instances (100 iterations)', () async {
        final random = Random(42);

        for (var i = 0; i < 100; i++) {
          final mockStorage = MockSecureStorage();

          // First manager instance - add requests
          final manager1 = OfflineQueueManager(secureStorage: mockStorage);
          final messageCount = random.nextInt(10) + 1;

          for (var j = 0; j < messageCount; j++) {
            await manager1.addRequest(QueuedRequest(
              id: 'msg_$j',
              method: 'POST',
              path: '/chat',
              data: {'content': 'Test $j'},
              createdAt: DateTime.now().add(Duration(milliseconds: j)),
            ));
          }

          // Second manager instance - should see same requests
          final manager2 = OfflineQueueManager(secureStorage: mockStorage);
          final pending = await manager2.getPendingRequests();

          expect(pending.length, equals(messageCount),
              reason: 'Queue should persist across instances');

          // Clean up
          await manager2.clearQueue();
        }
      });
    });
  });

  group('QueuedRequest', () {
    test('serializes and deserializes correctly', () {
      final request = QueuedRequest(
        id: 'test-id',
        method: 'POST',
        path: '/api/chat',
        data: {'message': 'Hello', 'nested': {'key': 'value'}},
        queryParams: {'param1': 'value1'},
        createdAt: DateTime(2024, 1, 15, 10, 30, 0),
      );

      final json = request.toJson();
      final restored = QueuedRequest.fromJson(json);

      expect(restored.id, equals(request.id));
      expect(restored.method, equals(request.method));
      expect(restored.path, equals(request.path));
      expect(restored.data, equals(request.data));
      expect(restored.queryParams, equals(request.queryParams));
      expect(restored.createdAt, equals(request.createdAt));
    });
  });
}
