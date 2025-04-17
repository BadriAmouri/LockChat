import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chatroom.dart';

class ChatService {
  static const String baseUrl = 'http://192.168.136.139:5000'; // e.g., localhost:3000
  static const String endpoint = '/chatrooms/getAllChatrooms';

  static Future<List<Chatroom>> fetchChatrooms(String token) async {
    final url = Uri.parse('$baseUrl$endpoint');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // If your `authenticate` middleware requires token
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Chatroom.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load chatrooms: ${response.statusCode}');
    }
  }
}
