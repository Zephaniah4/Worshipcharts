class ChordEngine {
  static const List<String> _chromatic = <String>[
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
  ];

  static const Map<String, String> _enharmonicToSharp = <String, String>{
    'Db': 'C#',
    'Eb': 'D#',
    'Gb': 'F#',
    'Ab': 'G#',
    'Bb': 'A#',
  };

  String transposeKey(String key, int semitones) {
    final String normalized = _enharmonicToSharp[key] ?? key;
    final int index = _chromatic.indexOf(normalized);
    if (index == -1) {
      return key;
    }
    final int shifted = (index + semitones) % _chromatic.length;
    final int fixed = shifted < 0 ? shifted + _chromatic.length : shifted;
    return _chromatic[fixed];
  }

  String transposeChordLine(String text, int semitones) {
    final RegExp chordRegex = RegExp(r'\b([A-G](#|b)?)(m|maj|min|sus|dim|aug|add)?(\d+)?(\/[A-G](#|b)?)?\b');

    return text.replaceAllMapped(chordRegex, (Match match) {
      final String root = match.group(1) ?? '';
      final String quality = match.group(3) ?? '';
      final String extension = match.group(4) ?? '';
      final String slash = match.group(5) ?? '';

      final String transposedRoot = transposeKey(root, semitones);
      String transposedSlash = '';
      if (slash.isNotEmpty) {
        final String bass = slash.substring(1);
        transposedSlash = '/${transposeKey(bass, semitones)}';
      }

      return '$transposedRoot$quality$extension$transposedSlash';
    });
  }
}
