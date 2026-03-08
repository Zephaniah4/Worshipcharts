import 'dart:convert';

import '../models/setlist.dart';
import '../models/song.dart';
import 'local_database.dart';

class LocalStore {
  LocalStore({LocalDatabase? database}) : _database = database ?? LocalDatabase();

  final LocalDatabase _database;

  final List<Song> _songs = <Song>[];
  final List<Setlist> _setlists = <Setlist>[];

  List<Song> get songs => List<Song>.unmodifiable(_songs);
  List<Setlist> get setlists => List<Setlist>.unmodifiable(_setlists);

  Future<void> init() async {
    await _database.init();

    final List<String> encodedSongs = await _database.loadSongPayloads();
    final List<String> encodedSetlists = await _database.loadSetlistPayloads();

    _songs
      ..clear()
      ..addAll(
        encodedSongs
            .map((String row) => jsonDecode(row) as Map<String, dynamic>)
            .map(Song.fromJson),
      );

    _setlists
      ..clear()
      ..addAll(
        encodedSetlists
            .map((String row) => jsonDecode(row) as Map<String, dynamic>)
            .map(Setlist.fromJson),
      );
  }

  Future<void> upsertSong(Song song) async {
    final int index = _songs.indexWhere((Song s) => s.id == song.id);
    if (index == -1) {
      _songs.add(song);
    } else {
      _songs[index] = song;
    }
    await _persistSongs();
  }

  Future<void> upsertSetlist(Setlist setlist) async {
    final int index = _setlists.indexWhere((Setlist s) => s.id == setlist.id);
    if (index == -1) {
      _setlists.add(setlist);
    } else {
      _setlists[index] = setlist;
    }
    await _persistSetlists();
  }

  Future<void> _persistSongs() async {
    for (final Song song in _songs) {
      await _database.upsertSongRow(
        id: song.id,
        payload: jsonEncode(song.toJson()),
        updatedAt: song.updatedAt.toIso8601String(),
      );
    }
  }

  Future<void> _persistSetlists() async {
    for (final Setlist setlist in _setlists) {
      await _database.upsertSetlistRow(
        id: setlist.id,
        payload: jsonEncode(setlist.toJson()),
        updatedAt: setlist.updatedAt.toIso8601String(),
      );
    }
  }
}
