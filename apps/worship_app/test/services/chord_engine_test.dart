import 'package:flutter_test/flutter_test.dart';
import 'package:worship_app/services/chord_engine.dart';

void main() {
  group('ChordEngine.transposeKey', () {
    final ChordEngine engine = ChordEngine();

    test('transposes up semitone', () {
      expect(engine.transposeKey('C', 1), 'C#');
      expect(engine.transposeKey('E', 1), 'F');
    });

    test('transposes down semitone', () {
      expect(engine.transposeKey('C', -1), 'B');
      expect(engine.transposeKey('A', -2), 'G');
    });

    test('handles flat enharmonics', () {
      expect(engine.transposeKey('Bb', 1), 'B');
      expect(engine.transposeKey('Db', 2), 'D#');
    });
  });

  group('ChordEngine.transposeChordLine', () {
    final ChordEngine engine = ChordEngine();

    test('transposes simple chord line', () {
      const String input = 'C G Am F';
      expect(engine.transposeChordLine(input, 2), 'D A Bm G');
    });

    test('transposes slash chords', () {
      const String input = 'C/E G/B';
      expect(engine.transposeChordLine(input, 1), 'C#/F G#/C');
    });
  });
}
