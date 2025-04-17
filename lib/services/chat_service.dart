import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chatroom.dart';
import '../../services/jwt_handler.dart';
import '../../services/decryption_service.dart';

class ChatService {
  static const String baseUrl = 'http://10.80.1.239:5000';
  static const String endpoint = 'api/chatrooms/getAllChatrooms';

  static Future<List<Chatroom>> fetchChatrooms() async {
    final jwtHandler = JwtHandler();
    print('jwtHandler object created');
    
    final response = await jwtHandler.authenticatedGet(endpoint);
    print('authenticatedGet is called');

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      final decryptionService = DecryptionService();

      // Use Future.wait to decrypt messages in parallel
      List<Chatroom> chatrooms = await Future.wait(data.map((jsonres) async {
        Chatroom chat = Chatroom.fromJson(jsonres);
        print("📤📤📤📤 Start decrypting the message 📤📤📤📤");
        await chat.decryptLastMessage(jsonres, decryptionService);
        return chat;
      }));

      return chatrooms;
    } else {
      throw Exception('Failed to load chatrooms: ${response.statusCode}');
    }
  }
}
