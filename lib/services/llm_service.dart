import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/medicine.dart';

class LlmService {
  static const String _endpoint =
      'https://presartorial-unprovincially-selina.ngrok-free.dev/extract-medicines';

  Future<List<Medicine>?> extractMedicines(String text) async {
    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'transcript': text}),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) {
        print('❌ LLM error: ${response.body}');
        return null;
      }

      final data = jsonDecode(response.body);

      final meds = (data['medicines'] as List)
          .map((m) => Medicine.fromJson(m))
          .toList();

      return meds;
    } catch (e) {
      print('❌ LLM exception: $e');
      return null;
    }
  }
}