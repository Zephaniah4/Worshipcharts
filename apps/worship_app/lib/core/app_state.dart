import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/setlist.dart';
import '../models/song.dart';
import '../services/chord_engine.dart';
import '../services/firebase_sync_api.dart';
import '../services/import_service.dart';
import '../services/local_database.dart';
import '../services/local_store.dart';
import '../services/planning_center_service.dart';
import '../services/sync_service.dart';

class AppState extends ChangeNotifier {
  AppState({
    LocalStore? store,
    ChordEngine? chordEngine,
    SyncService? syncService,
    ImportService? importService,
    PlanningCenterService? planningCenterService,
    FirebaseSyncApi? firebaseSyncApi,
  })  : _store = store ?? LocalStore(),
        _chordEngine = chordEngine ?? ChordEngine(),
        _syncService = syncService ?? SyncService(),
        _importService = importService ?? ImportService(),
        _planningCenterService = planningCenterService ?? PlanningCenterService(),
        _firebaseSyncApi = firebaseSyncApi;

  static Future<AppState> create() async {
    FirebaseSyncApi? api;
    try {
      if (Firebase.apps.isNotEmpty) {
        api = FirebaseSyncApi();
      }
    } catch (_) {
      api = null;
    }

    final LocalDatabase database = LocalDatabase();
    final LocalStore store = LocalStore(database: database);
    final SyncService syncService = SyncService(api: api, database: database);

    await store.init();
    await syncService.init();

    final AppState state = AppState(store: store, syncService: syncService, firebaseSyncApi: api);
    await state.startAutoSync();
    return state;
  }

  static Future<AppState> createForTest() async {
    final LocalDatabase database = LocalDatabase(inMemory: true);
    final LocalStore store = LocalStore(database: database);
    final SyncService syncService = SyncService(database: database);
    await store.init();
    await syncService.init();
    return AppState(store: store, syncService: syncService);
  }

  final LocalStore _store;
  final ChordEngine _chordEngine;
  final SyncService _syncService;
  final ImportService _importService;
  final PlanningCenterService _planningCenterService;
  final FirebaseSyncApi? _firebaseSyncApi;
  final Uuid _uuid = const Uuid();
  late final String _deviceId = _uuid.v4();
  bool _networkAvailable = true;
  DateTime? _lastRemoteSyncAt;
  Timer? _autoSyncTimer;

  List<Song> get songs => _store.songs;
  List<Setlist> get setlists => _store.setlists;
  int get pendingSyncCount => _syncService.queue.length;
  int get importQueueCount => _importService.requests.length;
  bool get isNetworkAvailable => _networkAvailable;
  bool get backendConfigured => _firebaseSyncApi != null;
  bool get isAuthenticated => _firebaseSyncApi?.hasSession ?? false;
  String? get currentUserEmail => _firebaseSyncApi?.currentUserEmail;

  void setNetworkAvailable(bool value) {
    _networkAvailable = value;
    notifyListeners();
  }

  Future<void> addSong({
    required String title,
    required String artist,
    required String key,
    required String lyricsWithChords,
  }) async {
    final Song song = Song(
      id: _uuid.v4(),
      title: title,
      artist: artist,
      originalKey: key,
      currentKey: key,
      lyricsWithChords: lyricsWithChords,
      updatedAt: DateTime.now().toUtc(),
    );
    await _store.upsertSong(song);
    await _syncService.enqueue(
      SyncOperation(
        id: _uuid.v4(),
        deviceId: _deviceId,
        entityType: 'song',
        entityId: song.id,
        operation: 'upsert',
        payload: <String, dynamic>{
          'title': title,
          'artist': artist,
          'key': key,
          'lyricsWithChords': lyricsWithChords,
        },
        createdAt: DateTime.now().toUtc(),
      ),
    );
    notifyListeners();
  }

  Future<void> transposeSong(String songId, int semitones) async {
    final int songIndex = songs.indexWhere((Song s) => s.id == songId);
    if (songIndex == -1) {
      return;
    }
    final Song existing = songs[songIndex];

    final Song updated = existing.copyWith(
      currentKey: _chordEngine.transposeKey(existing.currentKey, semitones),
      lyricsWithChords: _chordEngine.transposeChordLine(existing.lyricsWithChords, semitones),
      updatedAt: DateTime.now().toUtc(),
    );

    await _store.upsertSong(updated);
    await _syncService.enqueue(
      SyncOperation(
        id: _uuid.v4(),
        deviceId: _deviceId,
        entityType: 'song',
        entityId: updated.id,
        operation: 'transpose',
        payload: <String, dynamic>{'semitones': semitones},
        createdAt: DateTime.now().toUtc(),
      ),
    );
    notifyListeners();
  }

  Future<void> createSetlist({required String name, required String teamId}) async {
    final Setlist setlist = Setlist(
      id: _uuid.v4(),
      name: name,
      songIds: const <String>[],
      teamId: teamId,
      updatedAt: DateTime.now().toUtc(),
    );

    await _store.upsertSetlist(setlist);
    await _syncService.enqueue(
      SyncOperation(
        id: _uuid.v4(),
        deviceId: _deviceId,
        entityType: 'setlist',
        entityId: setlist.id,
        operation: 'upsert',
        payload: <String, dynamic>{'name': name, 'teamId': teamId},
        createdAt: DateTime.now().toUtc(),
      ),
    );
    notifyListeners();
  }

  Future<void> addSongToSetlist({required String setlistId, required String songId}) async {
    final int setlistIndex = setlists.indexWhere((Setlist s) => s.id == setlistId);
    if (setlistIndex == -1) {
      return;
    }
    final Setlist existing = setlists[setlistIndex];

    final List<String> updatedSongIds = List<String>.from(existing.songIds);
    updatedSongIds.add(songId);
    final Setlist updated = existing.copyWith(
      songIds: updatedSongIds,
      updatedAt: DateTime.now().toUtc(),
    );

    await _store.upsertSetlist(updated);
    await _syncService.enqueue(
      SyncOperation(
        id: _uuid.v4(),
        deviceId: _deviceId,
        entityType: 'setlist',
        entityId: updated.id,
        operation: 'add-song',
        payload: <String, dynamic>{'songId': songId},
        createdAt: DateTime.now().toUtc(),
      ),
    );
    notifyListeners();
  }

  Future<void> shareSetlist({
    required String setlistId,
    required String collaborator,
    required String permission,
  }) async {
    final String normalizedCollaborator = collaborator.trim().toLowerCase();
    if (normalizedCollaborator.isEmpty) {
      return;
    }

    final int setlistIndex = setlists.indexWhere((Setlist s) => s.id == setlistId);
    if (setlistIndex == -1) {
      return;
    }

    final Setlist existing = setlists[setlistIndex];
    final Map<String, String> updatedShares = Map<String, String>.from(existing.shares);
    updatedShares[normalizedCollaborator] = permission;

    final Setlist updated = existing.copyWith(
      shares: updatedShares,
      updatedAt: DateTime.now().toUtc(),
    );

    await _store.upsertSetlist(updated);
    if (_firebaseSyncApi != null && _networkAvailable && isAuthenticated) {
      await _firebaseSyncApi.upsertSetlistShare(
        setlistId: updated.id,
        collaboratorKey: normalizedCollaborator,
        permission: permission,
      );
    }
    await _syncService.enqueue(
      SyncOperation(
        id: _uuid.v4(),
        deviceId: _deviceId,
        entityType: 'setlist_share',
        entityId: updated.id,
        operation: 'upsert-share',
        payload: <String, dynamic>{
          'collaborator': normalizedCollaborator,
          'permission': permission,
        },
        createdAt: DateTime.now().toUtc(),
      ),
    );
    notifyListeners();
  }

  Future<void> removeSetlistShare({
    required String setlistId,
    required String collaborator,
  }) async {
    final int setlistIndex = setlists.indexWhere((Setlist s) => s.id == setlistId);
    if (setlistIndex == -1) {
      return;
    }

    final Setlist existing = setlists[setlistIndex];
    final Map<String, String> updatedShares = Map<String, String>.from(existing.shares);
    if (!updatedShares.containsKey(collaborator)) {
      return;
    }

    updatedShares.remove(collaborator);
    final Setlist updated = existing.copyWith(
      shares: updatedShares,
      updatedAt: DateTime.now().toUtc(),
    );

    await _store.upsertSetlist(updated);
    if (_firebaseSyncApi != null && _networkAvailable && isAuthenticated) {
      await _firebaseSyncApi.removeSetlistShare(
        setlistId: updated.id,
        collaboratorKey: collaborator,
      );
    }
    await _syncService.enqueue(
      SyncOperation(
        id: _uuid.v4(),
        deviceId: _deviceId,
        entityType: 'setlist_share',
        entityId: updated.id,
        operation: 'remove-share',
        payload: <String, dynamic>{'collaborator': collaborator},
        createdAt: DateTime.now().toUtc(),
      ),
    );
    notifyListeners();
  }

  Future<int> flushPendingSync() async {
    if (!_networkAvailable) {
      return 0;
    }
    final int flushed = await _syncService.flushToServer();
    notifyListeners();
    return flushed;
  }

  Future<void> startAutoSync() async {
    _autoSyncTimer?.cancel();
    if (!backendConfigured || !isAuthenticated) {
      return;
    }
    await pullRemoteChanges();
    _autoSyncTimer = Timer.periodic(const Duration(seconds: 12), (Timer _) async {
      await pullRemoteChanges();
    });
  }

  Future<int> pullRemoteChanges() async {
    if (!_networkAvailable || !backendConfigured || !isAuthenticated) {
      return 0;
    }

    final FirebaseSyncApi api = _firebaseSyncApi!;
    final List<Map<String, dynamic>> songRows = await api.fetchSongDeltas(_lastRemoteSyncAt);
    final List<Map<String, dynamic>> setlistRows = await api.fetchSetlistDeltas(_lastRemoteSyncAt);

    DateTime newestTimestamp = _lastRemoteSyncAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

    for (final Map<String, dynamic> row in songRows) {
      final DateTime updatedAt =
          DateTime.tryParse((row['updated_at'] ?? '').toString())?.toUtc() ?? DateTime.now().toUtc();
      final Song song = Song(
        id: (row['id'] ?? '').toString(),
        title: (row['title'] ?? '').toString(),
        artist: (row['artist'] ?? '').toString(),
        originalKey: (row['original_key'] ?? 'C').toString(),
        currentKey: (row['current_key'] ?? 'C').toString(),
        lyricsWithChords: (row['lyrics_with_chords'] ?? '').toString(),
        updatedAt: updatedAt,
      );
      await _store.upsertSong(song);
      if (updatedAt.isAfter(newestTimestamp)) {
        newestTimestamp = updatedAt;
      }
    }

    final Map<String, Map<String, String>> shareRows = await api.fetchSetlistShareDeltas(
      setlistIds: setlistRows.map((Map<String, dynamic> row) => (row['id'] ?? '').toString()).toList(),
    );

    for (final Map<String, dynamic> row in setlistRows) {
      final DateTime updatedAt =
          DateTime.tryParse((row['updated_at'] ?? '').toString())?.toUtc() ?? DateTime.now().toUtc();
      final String setlistId = (row['id'] ?? '').toString();
      final Setlist setlist = Setlist(
        id: setlistId,
        name: (row['name'] ?? '').toString(),
        songIds: const <String>[],
        teamId: (row['team_id'] ?? 'default-team').toString(),
        updatedAt: updatedAt,
        shares: shareRows[setlistId] ?? const <String, String>{},
      );
      await _store.upsertSetlist(setlist);
      if (updatedAt.isAfter(newestTimestamp)) {
        newestTimestamp = updatedAt;
      }
    }

    if (songRows.isNotEmpty || setlistRows.isNotEmpty) {
      _lastRemoteSyncAt = newestTimestamp;
      notifyListeners();
    }

    return songRows.length + setlistRows.length;
  }

  Future<void> addTestOperation() async {
    await _syncService.enqueue(
      SyncOperation(
        id: _uuid.v4(),
        deviceId: _deviceId,
        entityType: 'diagnostic',
        entityId: _uuid.v4(),
        operation: 'test-op',
        payload: <String, dynamic>{'source': 'test-mode'},
        createdAt: DateTime.now().toUtc(),
      ),
    );
    notifyListeners();
  }

  Future<void> queueSongImport(String provider, String query) async {
    if (query.isEmpty) {
      return;
    }
    _importService.queueImport(provider: provider, query: query);
    await _syncService.enqueue(
      SyncOperation(
        id: _uuid.v4(),
        deviceId: _deviceId,
        entityType: 'import',
        entityId: _uuid.v4(),
        operation: 'queue-import',
        payload: <String, dynamic>{'provider': provider, 'query': query},
        createdAt: DateTime.now().toUtc(),
      ),
    );
    notifyListeners();
  }

  Future<String> pullPlanningCenterPlan(String planId) async {
    if (planId.isEmpty) {
      return 'Plan ID is required.';
    }

    final String message = await _planningCenterService.pullPlanStub(planId);
    await _syncService.enqueue(
      SyncOperation(
        id: _uuid.v4(),
        deviceId: _deviceId,
        entityType: 'integration',
        entityId: _uuid.v4(),
        operation: 'planning-center-pull',
        payload: <String, dynamic>{'planId': planId},
        createdAt: DateTime.now().toUtc(),
      ),
    );
    notifyListeners();
    return message;
  }

  Future<String> signIn({required String email, required String password}) async {
    if (_firebaseSyncApi == null) {
      return 'Firebase is not configured for this build.';
    }

    try {
      await _firebaseSyncApi.signInWithPassword(email: email, password: password);
      await startAutoSync();
      notifyListeners();
      return 'Signed in successfully.';
    } catch (e) {
      return 'Sign-in failed: $e';
    }
  }

  Future<String> signUp({required String email, required String password}) async {
    if (_firebaseSyncApi == null) {
      return 'Firebase is not configured for this build.';
    }

    try {
      await _firebaseSyncApi.signUpWithPassword(email: email, password: password);
      notifyListeners();
      return 'Sign-up successful.';
    } catch (e) {
      return 'Sign-up failed: $e';
    }
  }

  Future<void> signOut() async {
    if (_firebaseSyncApi == null) {
      return;
    }
    await _firebaseSyncApi.signOut();
    _autoSyncTimer?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    super.dispose();
  }
}
