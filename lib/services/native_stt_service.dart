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
        print('✅ STT initialized');

        final locales = await _speech.locales();

        // Prefer exact en_IN → else fallback en_US
        final hasEnIN = locales.any((l) => l.localeId == 'en_IN');
        final hasEnUS = locales.any((l) => l.localeId == 'en_US');

        if (hasEnIN) {
          _currentLocale = 'en_IN';
        } else if (hasEnUS) {
          _currentLocale = 'en_US';
        } else {
          _currentLocale = locales.isNotEmpty
              ? locales.first.localeId
              : 'en_US';
        }

        print('🌍 Using locale: $_currentLocale');
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
    if (!_isAvailable) {
      print('🔴 STT not available');
      return;
    }

    if (_speech.isListening) {
      print('⚠️ Already listening');
      return;
    }

    print('▶️ Start listening ($_currentLocale)');

    _speech.listen(
      onResult: (result) {
        final text = result.recognizedWords;

        if (result.finalResult) {
          print('✅ Final: $text');
          onResult(text);
        } else {
          onPartialResult(text);
        }
      },
      localeId: _currentLocale,
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation, // 🔥 important change
        partialResults: true,
        cancelOnError: false,
        autoPunctuation: true,
      ),
      pauseFor: const Duration(seconds: 2),
    );
  }

  void stopListening() {
    if (_speech.isListening) {
      print('⏹️ Stop listening');
      _speech.stop();
    }
  }

  bool get isListening => _speech.isListening;

  Future<List<String>> getAvailableLanguages() async {
    try {
      final locales = await _speech.locales();
      return locales.map((l) => l.localeId).toList();
    } catch (e) {
      print('⚠️ Locale fetch error: $e');
      return ['en_IN', 'en_US'];
    }
  }
}