import 'package:flutter_test/flutter_test.dart';
import 'package:worship_app/services/sync_service.dart';

void main() {
  test('SyncOperation json round-trip', () {
    final SyncOperation operation = SyncOperation(
      id: 'op-1',
      deviceId: 'device-1',
      entityType: 'song',
      entityId: 'song-1',
      operation: 'upsert',
      payload: <String, dynamic>{'title': 'Test'},
      createdAt: DateTime.parse('2026-03-08T00:00:00Z'),
    );

    final SyncOperation restored = SyncOperation.fromJson(operation.toJson());

    expect(restored.id, operation.id);
    expect(restored.deviceId, operation.deviceId);
    expect(restored.entityType, operation.entityType);
    expect(restored.entityId, operation.entityId);
    expect(restored.operation, operation.operation);
    expect(restored.payload['title'], 'Test');
  });
}
