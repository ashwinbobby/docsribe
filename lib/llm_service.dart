import 'dart:convert';
import 'package:http/http.dart' as http;
import 'prescription_model.dart';

class LlmService {
  static const _endpoint = 'https://ashbobby-docscribe-model.hf.space/extract';

  Future<List<Prescription>?> extract(String text) async {
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

      final data = jsonDecode(response.body);

      final list = data['prescriptions'] as List;

      return list.map((e) => Prescription.fromJson(e)).toList();
    } catch (e) {
      print('LLM exception: $e');
      return null;
    }
  }
}
