import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_service.dart';

class UserActivity {
  final int id;
  final int userId;
  final String type;
  final String description;
  final DateTime createdAt;

  UserActivity({
    required this.id,
    required this.userId,
    required this.type,
    required this.description,
    required this.createdAt,
  });

  factory UserActivity.fromJson(Map<String, dynamic> json) {
    return UserActivity(
      id: json['id'],
      userId: json['userId'],
      type: json['type'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class FeedService {
  final AuthService _authService = AuthService();

  Future<List<UserActivity>> getFeed({int limit = 20}) async {
    final apiUrl = await AppConfig.apiBaseUrl;
    final userId = await _authService.getUserId();
    final token = await _authService.getToken();

    final response = await http.get(
      Uri.parse('$apiUrl/feed?limit=$limit'),
      headers: {
        'X-User-Id': userId.toString(),
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => UserActivity.fromJson(json)).toList();
    } else {
      throw Exception('Akış yüklenemedi: ${response.statusCode}');
    }
  }
}
