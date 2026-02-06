import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_service.dart';

class ChatService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken(); // If needed
    final userId = await _authService.getUserId();
    return {
      'Content-Type': 'application/json',
      'X-User-Id': userId.toString(), 
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<dynamic>> getConversations() async {
    final baseUrl = await AppConfig.apiBaseUrl;
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/chat/conversations'), headers: headers);

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Sohbet listesi yüklenemedi: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> getMessages(int otherUserId) async {
    final baseUrl = await AppConfig.apiBaseUrl;
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/chat/messages/$otherUserId'), headers: headers);

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Mesajlar yüklenemedi: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> sendMessage(int receiverId, String content) async {
    final baseUrl = await AppConfig.apiBaseUrl;
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/chat/send/$receiverId'),
      headers: headers,
      body: json.encode({'content': content}),
    );

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Mesaj gönderilemedi: ${response.statusCode} - ${response.body}');
    }
  }
}
