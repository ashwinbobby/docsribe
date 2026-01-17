import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();

  String _buffer = '';
  bool _initialized = false;

  Future<bool> init() async {
    if (_initialized) return true;

    _initialized = await _speech.initialize(
      onStatus: (status) => print('🟡 Speech status: $status'),
      onError: (error) => print('🔴 Speech error: $error'),
    );

    print('✅ Speech initialized: $_initialized');
    return _initialized;
  }

  /// Start listening (manual)
  Future<void> startListening() async {
    final ok = await init();
    if (!ok) return;

    _buffer = '';
    print('▶️ START listening');

    await _speech.listen(
      partialResults: true,
      onResult: (r) {
        print('📝 Partial: ${r.recognizedWords}');
        _buffer = r.recognizedWords;
      },
    );
  }

  /// Stop listening and return final text
  Future<String?> stopListening() async {
    print('⏹️ STOP listening');
    await _speech.stop();

    final result = _buffer.trim();
    print('🎯 Final text: $result');

    return result.isEmpty ? null : result;
  }

  bool get isListening => _speech.isListening;
}
