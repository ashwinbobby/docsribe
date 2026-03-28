class TextNormalizer {
  static final Map<String, String> _numberMap = {
    'one': '1',
    'two': '2',
    'three': '3',
    'four': '4',
    'five': '5',
    'six': '6',
    'seven': '7',
    'eight': '8',
    'nine': '9',
    'ten': '10',
  };

  static final Map<String, String> _phraseMap = {
    'once a day': '1 time a day',
    'twice a day': '2 times a day',
    'thrice a day': '3 times a day',
    'after food': 'after meals',
    'before food': 'before meals',
  };

  static String normalize(String input) {
    String text = input.toLowerCase().trim();

    // Normalize phrases first
    _phraseMap.forEach((k, v) {
      text = text.replaceAll(k, v);
    });

    // Normalize number words
    _numberMap.forEach((word, digit) {
      text = text.replaceAllMapped(
        RegExp(r'\b' + word + r'\b'),
        (_) => digit,
      );
    });

    // Cleanup extra spaces
    text = text.replaceAll(RegExp(r'\s+'), ' ');

    return text;
  }
}
