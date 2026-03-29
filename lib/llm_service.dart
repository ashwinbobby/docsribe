import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'ollama.dart';
import 'prescription_model.dart';

enum LlmBackend { none, ollama, hosted }

class LlmPingResult {
  final bool reachable;
  final LlmBackend activeBackend;
  final bool usedFallback;
  final String message;

  const LlmPingResult({
    required this.reachable,
    required this.activeBackend,
    required this.usedFallback,
    required this.message,
  });
}

class LlmService {
  static const _hostedEndpoint =
      'https://ashbobby-docscribe-model.hf.space/extract';
  static const _hostedHealthEndpoint =
      'https://ashbobby-docscribe-model.hf.space/health';
    static const _envProvider =
      String.fromEnvironment('DOCSCRIBE_LLM_PROVIDER', defaultValue: 'auto');
    static const _envOllamaBaseUrl =
      String.fromEnvironment('DOCSCRIBE_OLLAMA_BASE_URL', defaultValue: '');
    static const _envOllamaModel = String.fromEnvironment(
    'DOCSCRIBE_OLLAMA_MODEL',
    defaultValue: 'qwen2.5-coder:7b',
    );

    static const _provider =
      OllamaConfig.provider == '' ? _envProvider : OllamaConfig.provider;
    static const _ollamaBaseUrl =
      OllamaConfig.baseUrl == '' ? _envOllamaBaseUrl : OllamaConfig.baseUrl;
    static const _ollamaModel =
      OllamaConfig.model == '' ? _envOllamaModel : OllamaConfig.model;

  LlmBackend _lastBackendUsed = LlmBackend.none;
  bool _lastUsedFallback = false;

  bool get _hasOllamaUrl => _ollamaBaseUrl.trim().isNotEmpty;

  LlmBackend get lastBackendUsed => _lastBackendUsed;

  bool get lastUsedFallback => _lastUsedFallback;

  String get preferredBackendLabel => _preferOllama ? 'Ollama' : 'Hosted';

  String get lastBackendLabel {
    switch (_lastBackendUsed) {
      case LlmBackend.ollama:
        return 'Ollama';
      case LlmBackend.hosted:
        return _lastUsedFallback ? 'Hosted (fallback)' : 'Hosted';
      case LlmBackend.none:
        return 'N/A';
    }
  }

  bool get _preferOllama {
    final p = _provider.toLowerCase().trim();
    return p == 'ollama' || (p == 'auto' && _hasOllamaUrl);
  }

  Future<List<Prescription>?> extract(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return <Prescription>[];

    if (_preferOllama) {
      final ollamaResult = await _extractWithOllama(trimmed);
      if (ollamaResult != null && ollamaResult.isNotEmpty) {
        _lastBackendUsed = LlmBackend.ollama;
        _lastUsedFallback = false;
        return ollamaResult;
      }
      developer.log(
        'Ollama extraction failed or empty; falling back to hosted model.',
        name: 'LlmService',
      );

      final hostedResult = await _extractWithHosted(trimmed);
      if (hostedResult != null && hostedResult.isNotEmpty) {
        _lastBackendUsed = LlmBackend.hosted;
        _lastUsedFallback = true;
      } else {
        _lastBackendUsed = LlmBackend.none;
        _lastUsedFallback = false;
      }
      return hostedResult;
    }

    final hostedResult = await _extractWithHosted(trimmed);
    if (hostedResult != null && hostedResult.isNotEmpty) {
      _lastBackendUsed = LlmBackend.hosted;
      _lastUsedFallback = false;
    } else {
      _lastBackendUsed = LlmBackend.none;
      _lastUsedFallback = false;
    }
    return hostedResult;
  }

  Future<LlmPingResult> pingPreferredBackend() async {
    if (_preferOllama) {
      final ollamaOk = await _pingOllama();
      if (ollamaOk) {
        return const LlmPingResult(
          reachable: true,
          activeBackend: LlmBackend.ollama,
          usedFallback: false,
          message: 'Ollama reachable',
        );
      }

      final hostedOk = await _pingHosted();
      if (hostedOk) {
        return const LlmPingResult(
          reachable: true,
          activeBackend: LlmBackend.hosted,
          usedFallback: true,
          message: 'Ollama unreachable, hosted fallback is reachable',
        );
      }

      return const LlmPingResult(
        reachable: false,
        activeBackend: LlmBackend.none,
        usedFallback: false,
        message: 'Both Ollama and hosted backend are unreachable',
      );
    }

    final hostedOk = await _pingHosted();
    if (hostedOk) {
      return const LlmPingResult(
        reachable: true,
        activeBackend: LlmBackend.hosted,
        usedFallback: false,
        message: 'Hosted backend reachable',
      );
    }

    return const LlmPingResult(
      reachable: false,
      activeBackend: LlmBackend.none,
      usedFallback: false,
      message: 'Hosted backend unreachable',
    );
  }

  Future<List<Prescription>?> _extractWithHosted(String text) async {
    try {
      final response = await http
          .post(
            Uri.parse(_hostedEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'text': text}),
          )
          .timeout(const Duration(seconds: 120));

      if (response.statusCode != 200) {
        developer.log(
          'Hosted LLM error: ${response.body}',
          name: 'LlmService',
        );
        return null;
      }

      final data = jsonDecode(response.body);
      final list = data['prescriptions'] as List;
      return list.map((e) => Prescription.fromJson(e)).toList();
    } catch (e) {
      developer.log('Hosted LLM exception: $e', name: 'LlmService');
      return null;
    }
  }

  Future<List<Prescription>?> _extractWithOllama(String text) async {
    if (!_hasOllamaUrl) {
      developer.log(
        'DOCSCRIBE_OLLAMA_BASE_URL is not set.',
        name: 'LlmService',
      );
      return null;
    }

    try {
      final response = await http
          .post(
            _ollamaUri('/api/generate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': _ollamaModel,
              'prompt': _ollamaPrompt(text),
              'stream': false,
              'format': 'json',
              'options': {'temperature': 0},
            }),
          )
          .timeout(const Duration(seconds: 180));

      if (response.statusCode != 200) {
        developer.log(
          'Ollama error (${response.statusCode}): ${response.body}',
          name: 'LlmService',
        );
        return null;
      }

      final body = jsonDecode(response.body);
      final raw = (body['response'] ?? '').toString().trim();
      if (raw.isEmpty) {
        developer.log('Ollama returned empty response.', name: 'LlmService');
        return null;
      }

      final parsed = _parseOllamaJson(raw);
      if (parsed == null) {
        developer.log(
          'Unable to parse Ollama JSON response: $raw',
          name: 'LlmService',
        );
        return null;
      }

      final list = parsed['prescriptions'];
      if (list is! List) return <Prescription>[];

      return list
          .whereType<Map>()
          .map((e) => Prescription.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      developer.log('Ollama exception: $e', name: 'LlmService');
      return null;
    }
  }

  Uri _ollamaUri(String path) {
    final base = _ollamaBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final suffix = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$suffix');
  }

  Future<bool> _pingHosted() async {
    try {
      final response = await http
          .get(Uri.parse(_hostedHealthEndpoint))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return false;

      final data = jsonDecode(response.body);
      return data['status'] == 'awake';
    } catch (_) {
      return false;
    }
  }

  Future<bool> _pingOllama() async {
    if (!_hasOllamaUrl) return false;

    try {
      final response =
          await http.get(_ollamaUri('/api/tags')).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return false;

      final data = jsonDecode(response.body);
      final models = (data['models'] as List?) ?? const [];
      return models.any((m) => (m['name'] ?? '').toString() == _ollamaModel);
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic>? _parseOllamaJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      // Try to recover JSON when model wraps it in extra text.
    }

    final match = RegExp(r'\{[\s\S]*\}').firstMatch(raw);
    if (match == null) return null;

    try {
      final decoded = jsonDecode(match.group(0)!);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}

    return null;
  }

  String _ollamaPrompt(String text) {
    return '''
Extract medicine prescriptions from the text below.
Return only valid JSON in this exact shape:
{
  "prescriptions": [
    {
      "medicine": "",
      "dose": "",
      "timing": "",
      "duration": ""
    }
  ]
}

Rules:
- Always return the keys medicine, dose, timing, duration.
- If a field is missing, return an empty string.
- Do not include markdown or explanations.

Text:
$text
''';
  }
}
