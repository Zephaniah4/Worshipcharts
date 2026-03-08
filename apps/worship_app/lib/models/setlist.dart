class Setlist {
  Setlist({
    required this.id,
    required this.name,
    required this.songIds,
    required this.teamId,
    required this.updatedAt,
    this.shares = const <String, String>{},
  });

  final String id;
  final String name;
  final List<String> songIds;
  final String teamId;
  final DateTime updatedAt;
  final Map<String, String> shares;

  Setlist copyWith({
    String? name,
    List<String>? songIds,
    String? teamId,
    DateTime? updatedAt,
    Map<String, String>? shares,
  }) {
    return Setlist(
      id: id,
      name: name ?? this.name,
      songIds: songIds ?? this.songIds,
      teamId: teamId ?? this.teamId,
      updatedAt: updatedAt ?? this.updatedAt,
      shares: shares ?? this.shares,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'songIds': songIds,
      'teamId': teamId,
      'updatedAt': updatedAt.toIso8601String(),
      'shares': shares,
    };
  }

  factory Setlist.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawSongIds = json['songIds'] as List<dynamic>? ?? <dynamic>[];
    final Map<String, dynamic> rawShares =
        Map<String, dynamic>.from(json['shares'] as Map? ?? <String, dynamic>{});
    return Setlist(
      id: json['id'] as String,
      name: json['name'] as String,
      songIds: rawSongIds.map((dynamic value) => value.toString()).toList(),
      teamId: json['teamId'] as String? ?? 'default-team',
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '')?.toUtc() ?? DateTime.now().toUtc(),
      shares: rawShares.map((String key, dynamic value) => MapEntry<String, String>(key, value.toString())),
    );
  }
}
