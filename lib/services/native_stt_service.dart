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
        debugLogging: true,
      );
      
      if (_isAvailable) {
        print('✅ STT initialized successfully');
        
        // List available locales
        final locales = await _speech.locales();
        print('📍 Available locales: ${locales.length}');
        
        // Check for en_IN
        final enInAvailable = locales.any((loc) => 
          loc.localeId.contains('en_IN') || 
          loc.localeId.contains('en-IN') ||
          loc.localeId.startsWith('en_')
        );
        
        if (enInAvailable) {
          print('✅ en_IN language available');
          _currentLocale = "en_IN";
        } else {
          print('⚠️ en_IN not available, using en_US');
          _currentLocale = "en_US"; // Fallback
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
    if (!_isAvailable) {
      print('🔴 STT not available');
      return;
    }

    print('▶️ Starting listening on locale: $_currentLocale');

    _speech.listen(
      onResult: (result) {
        final text = result.recognizedWords;
        onPartialResult(text); // Live partial results
        
        if (result.finalResult) {
          print('✅ Final result: $text');
          onResult(text);
        }
      },
      localeId: _currentLocale, // Use detected locale
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.confirmation,
        partialResults: true,
        cancelOnError: false,
        autoPunctuation: true,
      ),
      pauseFor: const Duration(seconds: 2),
    );
  }

  void stopListening() {
    print('⏹️ Stopping listening');
    _speech.stop();
  }

  bool get isListening => _speech.isListening;

  Future<List<String>> getAvailableLanguages() async {
    try {
      final locales = await _speech.locales();
      return locales.map((l) => l.localeId).toList();
    } catch (e) {
      print('Error getting locales: $e');
      return ['en_US', 'en_IN'];
    }
  }
}
