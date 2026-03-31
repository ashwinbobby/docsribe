import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../models/medicine.dart';

class LlmService {
  static const String _endpoint =
      'https://presartorial-unprovincially-selina.ngrok-free.dev/extract-medicines';

  Future<List<Medicine>?> extractMedicines(String text) async {
    try {
      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'transcript': text}),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) {
        log('LLM error: ${response.body}', name: 'LlmService');
        return null;
      }

      final data = jsonDecode(response.body);

      final meds = (data['medicines'] as List)
          .map((m) => Medicine.fromJson(m))
          .toList();

      return meds;
    } catch (e) {
      log('LLM exception: $e', name: 'LlmService');
      return null;
    }
  }
}
