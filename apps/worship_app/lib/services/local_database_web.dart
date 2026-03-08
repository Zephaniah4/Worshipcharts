class LocalDatabase {
  LocalDatabase({bool inMemory = false});

  final Map<String, String> _songs = <String, String>{};
  final Map<String, String> _setlists = <String, String>{};
  final Map<String, String> _syncQueue = <String, String>{};

  Future<void> init() async {}

  Future<void> upsertSongRow({required String id, required String payload, required String updatedAt}) async {
    _songs[id] = payload;
  }

  Future<void> upsertSetlistRow({required String id, required String payload, required String updatedAt}) async {
    _setlists[id] = payload;
  }

  Future<List<String>> loadSongPayloads() async => _songs.values.toList();

  Future<List<String>> loadSetlistPayloads() async => _setlists.values.toList();

  Future<void> upsertSyncQueueRow({required String id, required String payload, required String createdAt}) async {
    _syncQueue[id] = payload;
  }

  Future<List<String>> loadSyncQueuePayloads() async => _syncQueue.values.toList();

  Future<void> deleteSyncQueueRows(List<String> ids) async {
    for (final String id in ids) {
      _syncQueue.remove(id);
    }
  }
}
