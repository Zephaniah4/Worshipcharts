class Song {
  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.originalKey,
    required this.currentKey,
    required this.lyricsWithChords,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String artist;
  final String originalKey;
  final String currentKey;
  final String lyricsWithChords;
  final DateTime updatedAt;

  Song copyWith({
    String? title,
    String? artist,
    String? originalKey,
    String? currentKey,
    String? lyricsWithChords,
    DateTime? updatedAt,
  }) {
    return Song(
      id: id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      originalKey: originalKey ?? this.originalKey,
      currentKey: currentKey ?? this.currentKey,
      lyricsWithChords: lyricsWithChords ?? this.lyricsWithChords,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'artist': artist,
      'originalKey': originalKey,
      'currentKey': currentKey,
      'lyricsWithChords': lyricsWithChords,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String? ?? '',
      originalKey: json['originalKey'] as String? ?? 'C',
      currentKey: json['currentKey'] as String? ?? 'C',
      lyricsWithChords: json['lyricsWithChords'] as String? ?? '',
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '')?.toUtc() ?? DateTime.now().toUtc(),
    );
  }
}
