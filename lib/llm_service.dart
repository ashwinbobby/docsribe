import 'dart:convert';
import 'package:http/http.dart' as http;
import 'prescription_model.dart';

class LlmService {
  static const _endpoint =
    'https://ashbobby-docscribe-gemma.hf.space/extract';

  Future<Prescription?> extract(String text) async {
    try {
      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'text': text}),
          )
          .timeout(const Duration(seconds: 120));

      if (response.statusCode != 200) {
        print('LLM error: ${response.body}');
        return null;
      }

      return Prescription.fromJson(jsonDecode(response.body));
    } catch (e) {
      print('LLM exception: $e');
      return null;
    }
  }
}
