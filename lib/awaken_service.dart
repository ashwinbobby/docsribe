import 'dart:convert';
import 'package:http/http.dart' as http;

class AwakenService {
  static const String _healthUrl =
      'https://ashbobby-docscribe-gemma.hf.space/health';

  static Future<bool> wakeModel() async {
    try {
      final response = await http
          .get(Uri.parse(_healthUrl))
          .timeout(const Duration(seconds: 40));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'awake';
      }
    } catch (e) {
      print('Model awaken failed: $e');
    }
    return false;
  }
}
