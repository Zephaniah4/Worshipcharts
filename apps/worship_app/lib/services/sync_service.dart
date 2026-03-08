import 'dart:convert';

import 'firebase_sync_api.dart';
import 'local_database.dart';

class SyncOperation {
  SyncOperation({
    required this.id,
    required this.deviceId,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    required this.createdAt,
  });

  final String id;
  final String deviceId;
  final String entityType;
  final String entityId;
  final String operation;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'deviceId': deviceId,
      'entityType': entityType,
      'entityId': entityId,
      'operation': operation,
      'payload': payload,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    return SyncOperation(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as String,
      operation: json['operation'] as String,
      payload: Map<String, dynamic>.from(json['payload'] as Map? ?? <String, dynamic>{}),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '')?.toUtc() ?? DateTime.now().toUtc(),
    );
  }
}

class SyncService {
  SyncService({FirebaseSyncApi? api, LocalDatabase? database})
      : _api = api,
        _database = database ?? LocalDatabase();

  final List<SyncOperation> _queue = <SyncOperation>[];
  final FirebaseSyncApi? _api;
  final LocalDatabase _database;

  List<SyncOperation> get queue => List<SyncOperation>.unmodifiable(_queue);

  Future<void> init() async {
    await _database.init();
    final List<String> encoded = await _database.loadSyncQueuePayloads();
    _queue
      ..clear()
      ..addAll(
        encoded
            .map((String row) => jsonDecode(row) as Map<String, dynamic>)
            .map(SyncOperation.fromJson),
      );
  }

  Future<void> enqueue(SyncOperation op) async {
    _queue.add(op);
    await _database.upsertSyncQueueRow(
      id: op.id,
      payload: jsonEncode(op.toJson()),
      createdAt: op.createdAt.toIso8601String(),
    );
  }

  Future<int> flushToServer() async {
    if (_queue.isEmpty || _api == null) {
      return 0;
    }

    final List<SyncOperation> snapshot = List<SyncOperation>.from(_queue);
    await _api.pushOperations(snapshot);
    _queue.clear();
    await _database.deleteSyncQueueRows(snapshot.map((SyncOperation op) => op.id).toList());
    return snapshot.length;
  }
}
