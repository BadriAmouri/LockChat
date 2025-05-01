import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chatroom.dart';
import '../../services/jwt_handler.dart';
import '../../services/decryption_service.dart';

class ChatService {
  static const String baseUrl = 'https://lock-chat-backend.vercel.app';
   static const String getAllChatroomsEndpoint = 'api/chatrooms/getAllChatrooms';
  static const String createChatroomEndpoint = 'api/chatrooms/createChatroom';
  static const String fetchChatroomUsersEndpoint = 'api/chatrooms';
  static const String leaveChatroomEndpoint = 'api/chatrooms';
  static const String removeUserFromChatroomEndpoint = 'api/chatrooms';
  static const String addUserToChatroomEndpoint = 'api/chatrooms';

  static Future<List<Chatroom>> fetchChatrooms() async {
    final jwtHandler = JwtHandler();
    print('jwtHandler object created');
    
    final response = await jwtHandler.authenticatedGet(getAllChatroomsEndpoint);
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

  static Future<int> createChatroom(String name, int creatorId, bool isPrivate) async {
    final jwtHandler = JwtHandler();
    final body = {
      'name': name,
      'creatorId': creatorId,
      'isPrivate': isPrivate,
    };

    final response = await jwtHandler.authenticatedPost(createChatroomEndpoint, body);

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return data['chatroom'];
    } else {
      throw Exception('Failed to create chatroom: ${response.body}');
    }
  }

  static Future<List<dynamic>> fetchChatroomUsers(String chatroomId) async {
    final jwtHandler = JwtHandler();
    final response = await jwtHandler.authenticatedGet('$fetchChatroomUsersEndpoint/$chatroomId/users');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch chatroom users: ${response.body}');
    }
  }

  static Future<void> leaveChatroom(String chatroomId) async {
    final jwtHandler = JwtHandler();
    final body = {'chatroomId': chatroomId};
    final response = await jwtHandler.authenticatedPost('$leaveChatroomEndpoint/$chatroomId/leave',body);

    if (response.statusCode != 200) {
      throw Exception('Failed to leave chatroom: ${response.body}');
    }
  }

  static Future<void> removeUserFromChatroom(String chatroomId, String userId) async {
    final jwtHandler = JwtHandler();
    final body = {'userId': userId};
    final response = await jwtHandler.authenticatedPost('$removeUserFromChatroomEndpoint/$chatroomId/removeUser', body);

    if (response.statusCode != 200) {
      throw Exception('Failed to remove user from chatroom: ${response.body}');
    }
  }

  static Future<void> addUserToChatroom(String chatroomId, String userId) async {
    final jwtHandler = JwtHandler();
    final body = {'userId': userId};
    final response = await jwtHandler.authenticatedPost('$addUserToChatroomEndpoint/$chatroomId/addUser', body);

    if (response.statusCode != 200) {
      throw Exception('Failed to add user to chatroom: ${response.body}');
    }
  }
}
