import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'ollama.dart';

class AwakenService {
  static const String _hostedHealthUrl =
      'https://ashbobby-docscribe-model.hf.space/health';
  static const String _envOllamaBaseUrl =
      String.fromEnvironment('DOCSCRIBE_OLLAMA_BASE_URL', defaultValue: '');
  static const String _envOllamaModel = String.fromEnvironment(
    'DOCSCRIBE_OLLAMA_MODEL',
    defaultValue: 'qwen2.5-coder:7b',
  );
  static const String _ollamaBaseUrl =
      OllamaConfig.baseUrl == '' ? _envOllamaBaseUrl : OllamaConfig.baseUrl;
  static const String _ollamaModel =
      OllamaConfig.model == '' ? _envOllamaModel : OllamaConfig.model;

  static Future<bool> wakeModel() async {
    if (_ollamaBaseUrl.trim().isNotEmpty) {
      final ok = await _checkOllama();
      if (ok) return true;
      developer.log(
        'Ollama health check failed; trying hosted health endpoint.',
        name: 'AwakenService',
      );
    }

    return _checkHosted();
  }

  static Future<bool> _checkHosted() async {
    try {
      final response = await http
          .get(Uri.parse(_hostedHealthUrl))
          .timeout(const Duration(seconds: 40));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'awake';
      }
    } catch (e) {
      developer.log('Model awaken failed: $e', name: 'AwakenService');
    }
    return false;
  }

  static Future<bool> _checkOllama() async {
    final base = _ollamaBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final url = Uri.parse('$base/api/tags');

    try {
      final response =
          await http.get(url).timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) return false;

      final data = jsonDecode(response.body);
      final models = (data['models'] as List?) ?? const [];
      return models.any((m) => (m['name'] ?? '').toString() == _ollamaModel);
    } catch (e) {
      developer.log('Ollama health check failed: $e', name: 'AwakenService');
      return false;
    }
  }
}
