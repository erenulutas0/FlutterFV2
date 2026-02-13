import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_service.dart';

class NotificationService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final userId = await _authService.getUserId();
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'X-User-Id': userId.toString(), 
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<dynamic>> getNotifications() async {
    final baseUrl = await AppConfig.apiBaseUrl;
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/notifications'), headers: headers);

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Bildirimler yüklenemedi');
    }
  }

    Future<int> getUnreadCount() async {
    final baseUrl = await AppConfig.apiBaseUrl;
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/notifications/unread-count'), headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return 0;
    }
  }

  Future<void> markAsRead(int notificationId) async {
    final baseUrl = await AppConfig.apiBaseUrl;
    final headers = await _getHeaders();
    await http.post(
      Uri.parse('$baseUrl/notifications/$notificationId/read'),
      headers: headers,
    );
  }
}
