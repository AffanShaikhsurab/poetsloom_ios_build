import 'dart:convert';
import 'package:http/http.dart' as http;

class MnemonicService {
  final String baseUrl;
  
  MnemonicService({required this.baseUrl});

  Future<Map<String, dynamic>> generateKey() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/generate_key'),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to generate key: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  Future<Map<String, dynamic>> keyToMnemonic(String key) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/key_to_mnemonic'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'key': key}),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to convert key to mnemonic: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  Future<Map<String, dynamic>> mnemonicToKey(String mnemonic) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/mnemonic_to_key'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'mnemonic': mnemonic}),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to convert mnemonic to key: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  Future<Map<String, dynamic>> verifyMnemonic(String mnemonic) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/verify_mnemonic/$mnemonic'),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to verify mnemonic: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }
}
