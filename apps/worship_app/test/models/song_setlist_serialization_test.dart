import 'package:flutter_test/flutter_test.dart';
import 'package:worship_app/models/setlist.dart';
import 'package:worship_app/models/song.dart';

void main() {
  test('Song serializes and deserializes', () {
    final Song song = Song(
      id: 'song-1',
      title: 'Amazing Grace',
      artist: 'John Newton',
      originalKey: 'G',
      currentKey: 'A',
      lyricsWithChords: '[G]Amazing [D]grace',
      updatedAt: DateTime.parse('2026-03-08T00:00:00Z'),
    );

    final Map<String, dynamic> json = song.toJson();
    final Song restored = Song.fromJson(json);

    expect(restored.id, song.id);
    expect(restored.title, song.title);
    expect(restored.currentKey, song.currentKey);
    expect(restored.lyricsWithChords, song.lyricsWithChords);
  });

  test('Setlist serializes and deserializes', () {
    final Setlist setlist = Setlist(
      id: 'setlist-1',
      name: 'Sunday AM',
      songIds: const <String>['song-1', 'song-2'],
      teamId: 'team-1',
      updatedAt: DateTime.parse('2026-03-08T00:00:00Z'),
      shares: const <String, String>{
        'leader@example.com': 'manage',
        'guitar@example.com': 'view',
      },
    );

    final Map<String, dynamic> json = setlist.toJson();
    final Setlist restored = Setlist.fromJson(json);

    expect(restored.id, setlist.id);
    expect(restored.name, setlist.name);
    expect(restored.songIds, setlist.songIds);
    expect(restored.teamId, setlist.teamId);
    expect(restored.shares, setlist.shares);
  });
}
