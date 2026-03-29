import 'dart:async';
import 'services/native_stt_service.dart';

class SpeechService {
  final NativeSttService _nativeStt = NativeSttService();

  bool _initialized = false;
  String _buffer = '';
  bool _finalReceived = false;
  Completer<String>? _finalCompleter;

  Future<bool> init() async {
    if (_initialized) return true;
    _initialized = await _nativeStt.init();
    print('✅ Speech initialized: $_initialized');
    return _initialized;
  }

  Future<void> startListening({
    Function(String)? onPartialResult,
    Function(String)? onFinalResult,
  }) async {
    final ok = await init();
    if (!ok) return;

    _buffer = '';
    _finalReceived = false;
    _finalCompleter = Completer<String>();

    print('▶️ START listening');

    _nativeStt.startListening(
      onResult: (text) {
        _buffer = text;
        _finalReceived = true;
        print('🎯 Final: $text');
        onFinalResult?.call(text);
        if (!(_finalCompleter?.isCompleted ?? true)) {
          _finalCompleter?.complete(text);
        }
      },
      onPartialResult: (text) {
        _buffer = text;
        onPartialResult?.call(text);
        print('📝 Live: $text');
      },
    );
  }

  /// Stop listening and wait up to 3 seconds for the final STT result.
  Future<String?> stopListening() async {
    print('⏹️ STOP listening');
    _nativeStt.stopListening();

    // If final result already came in, use it immediately
    if (_finalReceived) {
      final result = _buffer.trim();
      print('🎯 Final text (immediate): $result');
      return result.isEmpty ? null : result;
    }

    // Otherwise wait for the final callback (max 3 seconds)
    try {
      final result = await _finalCompleter!.future
          .timeout(const Duration(seconds: 3));
      final trimmed = result.trim();
      print('🎯 Final text (waited): $trimmed');
      return trimmed.isEmpty ? null : trimmed;
    } on TimeoutException {
      // Fall back to whatever is in the buffer
      final fallback = _buffer.trim();
      print('⚠️ STT final timeout, using buffer: $fallback');
      return fallback.isEmpty ? null : fallback;
    }
  }

  bool get isListening => _nativeStt.isListening;

  Future<List<String>> getAvailableLanguages() async {
    return await _nativeStt.getAvailableLanguages();
  }
}