import 'package:speech_to_text/speech_to_text.dart';

class NativeSttService {
  final SpeechToText _speech = SpeechToText();

  bool _isAvailable = false;
  String _currentLocale = "en_IN";

  Future<bool> init() async {
    try {
      _isAvailable = await _speech.initialize(
        onError: (val) => print('🔴 STT Error: $val'),
        onStatus: (val) => print('🟡 STT Status: $val'),
        debugLogging: false,
      );

      if (_isAvailable) {
        final locales = await _speech.locales();

        final hasEnIN = locales.any((l) => l.localeId == 'en_IN');
        final hasEnUS = locales.any((l) => l.localeId == 'en_US');

        if (hasEnIN) {
          _currentLocale = 'en_IN';
        } else if (hasEnUS) {
          _currentLocale = 'en_US';
        } else {
          _currentLocale =
              locales.isNotEmpty ? locales.first.localeId : 'en_US';
        }
      }

      return _isAvailable;
    } catch (e) {
      print("🔴 Init Error: $e");
      return false;
    }
  }

  void startListening({
    required Function(String) onResult,
    required Function(String) onPartialResult,
  }) {
    if (!_isAvailable) return;
    if (_speech.isListening) return;

    _speech.listen(
      onResult: (result) {
        final text = result.recognizedWords;

        if (result.finalResult) {
          onResult(text);
        } else {
          onPartialResult(text);
        }
      },
      localeId: _currentLocale,
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        partialResults: true,
        cancelOnError: false,
        autoPunctuation: true,
      ),
      // 🚫 NO pauseFor → manual stop only
    );
  }

  void stopListening() {
    if (_speech.isListening) {
      _speech.stop();
    }
  }

  bool get isListening => _speech.isListening;

  Future<List<String>> getAvailableLanguages() async {
    try {
      final locales = await _speech.locales();
      return locales.map((l) => l.localeId).toList();
    } catch (e) {
      return ['en_IN', 'en_US'];
    }
  }
}