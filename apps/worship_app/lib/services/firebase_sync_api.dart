import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'sync_service.dart';

class FirebaseSyncApi {
  FirebaseSyncApi({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  bool get hasSession => _auth.currentUser != null;

  String? get currentUserEmail => _auth.currentUser?.email;

  Future<void> signInWithPassword({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signUpWithPassword({required String email, required String password}) async {
    await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> pushOperations(List<SyncOperation> operations) async {
    if (operations.isEmpty) {
      return;
    }

    final WriteBatch batch = _firestore.batch();
    for (final SyncOperation op in operations) {
      final DocumentReference<Map<String, dynamic>> ref = _firestore.collection('sync_operations').doc(op.id);
      batch.set(ref, <String, dynamic>{
        'id': op.id,
        'entity_type': op.entityType,
        'entity_id': op.entityId,
        'operation': op.operation,
        'payload': op.payload,
        'client_created_at': op.createdAt.toIso8601String(),
        'device_id': op.deviceId,
        'operation_hash': op.id,
        'user_id': _auth.currentUser?.uid,
        'server_received_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<List<Map<String, dynamic>>> fetchSongDeltas(DateTime? sinceUtc) async {
    Query<Map<String, dynamic>> query = _firestore.collection('songs').orderBy('updated_at').limit(200);
    if (sinceUtc != null) {
      query = query.where('updated_at', isGreaterThan: Timestamp.fromDate(sinceUtc));
    }

    final QuerySnapshot<Map<String, dynamic>> snapshot = await query.get();
    return snapshot.docs
        .map(
          (QueryDocumentSnapshot<Map<String, dynamic>> doc) => _songDocToRow(doc),
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchSetlistDeltas(DateTime? sinceUtc) async {
    Query<Map<String, dynamic>> query = _firestore.collection('setlists').orderBy('updated_at').limit(200);
    if (sinceUtc != null) {
      query = query.where('updated_at', isGreaterThan: Timestamp.fromDate(sinceUtc));
    }

    final QuerySnapshot<Map<String, dynamic>> snapshot = await query.get();
    return snapshot.docs
        .map(
          (QueryDocumentSnapshot<Map<String, dynamic>> doc) => _setlistDocToRow(doc),
        )
        .toList();
  }

  Future<void> upsertSetlistShare({
    required String setlistId,
    required String collaboratorKey,
    required String permission,
  }) async {
    await _firestore.collection('setlists').doc(setlistId).collection('shares').doc(collaboratorKey).set(
      <String, dynamic>{
        'setlist_id': setlistId,
        'collaborator_key': collaboratorKey,
        'permission': permission,
        'updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> removeSetlistShare({
    required String setlistId,
    required String collaboratorKey,
  }) async {
    await _firestore.collection('setlists').doc(setlistId).collection('shares').doc(collaboratorKey).delete();
  }

  Future<Map<String, Map<String, String>>> fetchSetlistShareDeltas({
    required List<String> setlistIds,
  }) async {
    final Map<String, Map<String, String>> result = <String, Map<String, String>>{};

    for (final String setlistId in setlistIds) {
      if (setlistId.isEmpty) {
        continue;
      }
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _firestore.collection('setlists').doc(setlistId).collection('shares').get();
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snapshot.docs) {
        final Map<String, dynamic> data = doc.data();
        final String collaborator = (data['collaborator_key'] ?? doc.id).toString();
        final String permission = (data['permission'] ?? 'view').toString();
        result.putIfAbsent(setlistId, () => <String, String>{})[collaborator] = permission;
      }
    }

    return result;
  }

  Map<String, dynamic> _songDocToRow(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data();
    final Timestamp? ts = data['updated_at'] as Timestamp?;
    return <String, dynamic>{
      'id': doc.id,
      'title': (data['title'] ?? '').toString(),
      'artist': (data['artist'] ?? '').toString(),
      'original_key': (data['original_key'] ?? 'C').toString(),
      'current_key': (data['current_key'] ?? 'C').toString(),
      'lyrics_with_chords': (data['lyrics_with_chords'] ?? '').toString(),
      'updated_at': (ts?.toDate().toUtc() ?? DateTime.now().toUtc()).toIso8601String(),
    };
  }

  Map<String, dynamic> _setlistDocToRow(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data();
    final Timestamp? ts = data['updated_at'] as Timestamp?;
    return <String, dynamic>{
      'id': doc.id,
      'name': (data['name'] ?? '').toString(),
      'team_id': (data['team_id'] ?? 'default-team').toString(),
      'updated_at': (ts?.toDate().toUtc() ?? DateTime.now().toUtc()).toIso8601String(),
    };
  }
}
