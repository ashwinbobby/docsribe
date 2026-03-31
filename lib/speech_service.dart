import 'dart:async';
import 'services/native_stt_service.dart';

class SpeechService {
  final NativeSttService _nativeStt = NativeSttService();

  bool _initialized = false;
  bool _shouldKeepListening = false;

  String _buffer = '';
  String _latestPartial = '';

  Function(String)? _onPartial;
  Function(String)? _onFinal;

  Future<bool> init() async {
    if (_initialized) return true;

    _initialized = await _nativeStt.init(
      onDone: () {
        if (_shouldKeepListening) {
          _restartListening();
        }
      },
    );

    return _initialized;
  }

  Future<void> startListening({
    Function(String)? onPartialResult,
    Function(String)? onFinalResult,
  }) async {
    final ok = await init();
    if (!ok) return;

    _shouldKeepListening = true;
    _buffer = '';
    _latestPartial = '';

    _onPartial = onPartialResult;
    _onFinal = onFinalResult;

    _nativeStt.startListening(
      onResult: (text) {
        _buffer = ('$_buffer $text').trim();
        _latestPartial = '';
        _onFinal?.call(text);
      },
      onPartialResult: (text) {
        _latestPartial = text;
        _onPartial?.call(text);
      },
    );
  }

  void _restartListening() async {
    if (!_shouldKeepListening) return;

    await Future.delayed(const Duration(milliseconds: 300));

    _nativeStt.startListening(
      onResult: (text) {
        _buffer = ('$_buffer $text').trim();
        _latestPartial = '';
        _onFinal?.call(text);
      },
      onPartialResult: (text) {
        _latestPartial = text;
        _onPartial?.call(text);
      },
    );
  }

  Future<String?> stopListening() async {
    _shouldKeepListening = false;
    _nativeStt.stopListening();

    // Give STT a brief window to emit the last final callback after stop.
    await Future.delayed(const Duration(milliseconds: 250));

    final trimmed = ('$_buffer $_latestPartial').trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  bool get isListening => _nativeStt.isListening;

  Future<List<String>> getAvailableLanguages() async {
    return await _nativeStt.getAvailableLanguages();
  }
}
