import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lockchat/services/tokenStorage.dart';
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
     // print('Response data: after decoding it :  $data');
      final decryptionService = DecryptionService();

      // Use Future.wait to decrypt messages in parallel
      List<Chatroom> chatrooms = await Future.wait(data.map((jsonres) async {
        Chatroom chat = Chatroom.fromJson(jsonres);
        print("📤📤📤📤 Start decrypting the message 📤📤📤📤");
        await chat.decryptLastMessage(jsonres, decryptionService);
        print("the decrypted message is : Chatroom(id: ${chat.imageUrl}, name: ${chat.name} ${chat.iv} ${chat.keyId}, lastMessage: ${chat.lastMessage})");

        



        return chat;
      }));
      print('Fetched chats: ${chatrooms.map((c) => 'Chatroom(id: ${c.keyId}, name: ${c.name})').toList()}');
      

      return chatrooms;
    } else {
      throw Exception('Failed to load chatrooms: ${response.statusCode}');
    }
  }


  
static Future<List<Map<String, dynamic>>> fetchChatroomsSimplified() async {
  final jwtHandler = JwtHandler();
  print('jwtHandler object created');
  
  final response = await jwtHandler.authenticatedGet(getAllChatroomsEndpoint);
  print('authenticatedGet is called');

  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    print('Response data: after decoding it :  $data');

    // Extract only the desired attributes
    List<Map<String, dynamic>> simplifiedChatrooms = data.map((jsonres) {
       // Handle members list safely
      List<dynamic> members = jsonres["members"] ?? [];
      Map<String, dynamic> firstMember = members.isNotEmpty ? members[0] : {};
      Map<String, dynamic> secondMember = members.length > 1 ? members[1] : {};
      

     
      return {
        "chatroom_id": jsonres["chatroom_id"],
        "name": jsonres["name"],
        "last_message": jsonres["last_message"],
        "is_private": jsonres["is_private"],
        "created_at": jsonres["created_at"],
        "unread_message_count": jsonres["unread_message_count"],
        'iv': jsonres['iv'],
        "first_member_name": firstMember["name"],
        "first_member_role": firstMember["role"],
        "first_member_id": firstMember["user_id"],
        "first_member_image": firstMember["profile_pic"],
        "second_member_name": secondMember["name"],
        "second_member_role": secondMember["role"],
        "second_member_id": secondMember["user_id"],
        "second_member_image": secondMember["profile_pic"],
      };
    }).toList();

    // Print each simplified chatroom
    print('-----------------------------------------------------------------------------------');
    for (var chat in simplifiedChatrooms) {
  print("Chatroom => ID: ${chat['chatroom_id']}, "
        "Name: ${chat['name']}, "
        "Private: ${chat['is_private']}, "
        "Created At: ${chat['created_at']}, "
        "Last Message: ${chat['last_message']}, "
        "Unread Count: ${chat['unread_message_count']}, "
        "First Member: ${chat['first_member_name']} (${chat['first_member_role']}) (${chat['first_member_id']})  (${chat['first_member_image']}), "
        "Second Member: ${chat['second_member_name']} (${chat['second_member_role']})");
}


    return simplifiedChatrooms;
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
