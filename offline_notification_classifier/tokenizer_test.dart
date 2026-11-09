// Place in test/, copy vocab.txt and golden_tokens.json into test/fixtures/.
// Adjust the import to your package name. Run: flutter test
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:your_app/ml/wordpiece_tokenizer.dart';

void main() {
  test('Dart tokenizer matches HuggingFace tokenizer', () {
    final vocab = File('test/fixtures/vocab.txt').readAsStringSync();
    final golden = jsonDecode(File('test/fixtures/golden_tokens.json').readAsStringSync()) as List;
    final tok = WordPieceTokenizer.fromVocabText(vocab, maxLen: 64);

    var failures = 0;
    for (final c in golden) {
      final text = c['text'] as String;
      final expected = (c['ids'] as List).cast<int>();
      final actual = tok.encode(text);
      if (actual.join(',') != expected.join(',')) {
        failures++;
        // ignore: avoid_print
        print('MISMATCH: $text\n  expected: $expected\n  actual:   $actual');
      }
    }
    expect(failures, 0);
  });
}
