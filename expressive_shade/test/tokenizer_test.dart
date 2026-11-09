import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:expressive_shade/ml/wordpiece_tokenizer.dart';

void main() {
  test('Dart tokenizer matches HuggingFace tokenizer', () {
    final vocabFile = File('test/fixtures/vocab.txt');
    final goldenFile = File('test/fixtures/golden_tokens.json');

    expect(vocabFile.existsSync(), isTrue, reason: 'vocab.txt must exist in test/fixtures/');
    expect(goldenFile.existsSync(), isTrue, reason: 'golden_tokens.json must exist in test/fixtures/');

    final vocab = vocabFile.readAsStringSync();
    final golden = jsonDecode(goldenFile.readAsStringSync()) as List;
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
