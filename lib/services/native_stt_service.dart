import 'dart:developer';

import 'package:speech_to_text/speech_to_text.dart';

class NativeSttService {
  final SpeechToText _speech = SpeechToText();

  bool _isAvailable = false;
  bool _isListening = false;

  String _currentLocale = "en_IN";

  Function()? _onDoneCallback;

  Future<bool> init({Function()? onDone}) async {
    try {
      _onDoneCallback = onDone;

      _isAvailable = await _speech.initialize(
        onError: (val) => log('STT Error: $val', name: 'NativeSttService'),
        onStatus: (status) async {
          log('STT Status: $status', name: 'NativeSttService');

          if (status == "done" || status == "notListening") {
            _isListening = false;

            if (_onDoneCallback != null) {
              await Future.delayed(const Duration(milliseconds: 300));
              _onDoneCallback!();
            }
          }
        },
        debugLogging: false,
      );

      if (_isAvailable) {
        final locales = await _speech.locales();

        if (locales.any((l) => l.localeId == 'en_IN')) {
          _currentLocale = 'en_IN';
        } else if (locales.any((l) => l.localeId == 'en_US')) {
          _currentLocale = 'en_US';
        } else {
          _currentLocale = locales.isNotEmpty
              ? locales.first.localeId
              : 'en_US';
        }
      }

      return _isAvailable;
    } catch (e) {
      log('Init Error: $e', name: 'NativeSttService');
      return false;
    }
  }

  void startListening({
    required Function(String) onResult,
    required Function(String) onPartialResult,
  }) async {
    if (!_isAvailable) return;

    if (_isListening) return;

    _isListening = true;

    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
        } else {
          onPartialResult(result.recognizedWords);
        }
      },
      pauseFor: const Duration(seconds: 1000),
      listenFor: const Duration(minutes: 10),
      localeId: _currentLocale,
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        partialResults: true,
        cancelOnError: false,
      ),
    );
  }

  void stopListening() {
    _isListening = false;
    _speech.stop();
  }

  bool get isListening => _isListening;

  Future<List<String>> getAvailableLanguages() async {
    try {
      final locales = await _speech.locales();
      return locales.map((l) => l.localeId).toList();
    } catch (e) {
      return ['en_IN', 'en_US'];
    }
  }
}
