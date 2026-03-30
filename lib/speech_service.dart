import 'dart:async';
import 'services/native_stt_service.dart';

class SpeechService {
  final NativeSttService _nativeStt = NativeSttService();

  bool _initialized = false;
  String _buffer = '';
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
    _finalCompleter = Completer<String>();

    print('▶️ START listening');

    _nativeStt.startListening(
      onResult: (text) {
        _buffer = text;

        print('🎯 Final: $text');

        // Complete ONLY once
        if (!(_finalCompleter?.isCompleted ?? true)) {
          _finalCompleter?.complete(text);
        }

        // UI callback
        onFinalResult?.call(text);
      },
      onPartialResult: (text) {
        _buffer = text;
        onPartialResult?.call(text);
        print('📝 Live: $text');
      },
    );
  }

  /// Stop listening and safely return final result
  Future<String?> stopListening() async {
    print('⏹️ STOP listening');
    _nativeStt.stopListening();

    try {
      // Wait for final result (max 2 seconds)
      final result = await _finalCompleter!.future
          .timeout(const Duration(seconds: 2));

      final trimmed = result.trim();
      print('🎯 Final text (waited): $trimmed');

      return trimmed.isEmpty ? null : trimmed;
    } on TimeoutException {
      // Fallback to buffer if final didn't arrive
      final fallback = _buffer.trim();
      print('⚠️ Timeout → using buffer: $fallback');

      return fallback.isEmpty ? null : fallback;
    }
  }

  bool get isListening => _nativeStt.isListening;

  Future<List<String>> getAvailableLanguages() async {
    return await _nativeStt.getAvailableLanguages();
  }
}