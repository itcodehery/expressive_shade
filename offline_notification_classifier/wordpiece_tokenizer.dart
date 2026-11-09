/// BERT-style uncased WordPiece tokenizer, matching HF's BertTokenizer for
/// typical ASCII notification text.
///
/// Known gap: no accent stripping / CJK splitting (Dart has no built-in
/// Unicode normalization). Fine for English; add a mapping table if needed.
class WordPieceTokenizer {
  final Map<String, int> vocab;
  final int maxLen;
  final int maxCharsPerWord;

  WordPieceTokenizer(this.vocab, {this.maxLen = 64, this.maxCharsPerWord = 100});

  factory WordPieceTokenizer.fromVocabText(String vocabText, {int maxLen = 64}) {
    final vocab = <String, int>{};
    final lines = vocabText.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final token = lines[i].trim();
      if (token.isNotEmpty) vocab[token] = i;
    }
    return WordPieceTokenizer(vocab, maxLen: maxLen);
  }

  // BERT splits on whitespace and treats EVERY punctuation char (including
  // apostrophes and underscores) as its own token.
  static final _basic = RegExp(r'[^\W_]+|[^\s\w]|_', unicode: true);

  List<int> encode(String text) {
    final body = <int>[];
    for (final m in _basic.allMatches(text.toLowerCase())) {
      body.addAll(_wordPiece(m.group(0)!));
      if (body.length >= maxLen - 2) break;
    }
    final trimmed = body.length > maxLen - 2 ? body.sublist(0, maxLen - 2) : body;
    return [vocab['[CLS]']!, ...trimmed, vocab['[SEP]']!];
  }

  List<int> _wordPiece(String word) {
    if (word.length > maxCharsPerWord) return [vocab['[UNK]']!];
    final out = <int>[];
    var start = 0;
    while (start < word.length) {
      var end = word.length;
      int? found;
      while (start < end) {
        final piece = (start > 0 ? '##' : '') + word.substring(start, end);
        final id = vocab[piece];
        if (id != null) {
          found = id;
          break;
        }
        end--;
      }
      if (found == null) return [vocab['[UNK]']!];
      out.add(found);
      start = end;
    }
    return out;
  }
}
