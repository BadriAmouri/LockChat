import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../services/decryption_service.dart';
import '../../services/KeyManagementService.dart';
import 'package:pointycastle/pointycastle.dart';
import '../../services/jwt_handler.dart';
import '../../services/tokenStorage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Chatroom {
  String name;
  String lastMessage;
  final String time;
  String imageUrl;
  final int unreadMessages;
  final String keyId;
  final String iv;

  Chatroom({
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.imageUrl,
    required this.unreadMessages,
    required this.keyId,
    required this.iv,
  });

  factory Chatroom.fromJson(Map<String, dynamic> json) {
    final rawTimestamp = json['last_message_sent_at'];
    String formattedTime = '';

    if (rawTimestamp != null) {
      final dateTime = DateTime.tryParse(rawTimestamp);
      if (dateTime != null) {
        formattedTime =
            '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
    }

    return Chatroom(
      name: json['name'] ?? 'Unnamed',
      lastMessage: json['last_message'] ?? '',
      time: formattedTime,
      imageUrl: json['imageUrl'] ?? 'https://via.placeholder.com/50',
      unreadMessages: json['unreadMessages'] ?? 0,
      keyId: json['encryption_key_id'] ?? '',
      iv: json['iv'] ?? '',
    );
  }

 Future<void> decryptLastMessage(Map<String, dynamic> jsonres, DecryptionService decryptionService) async {
  try {
    final TokenStorage _tokenStorage = TokenStorage();
    final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
    final userIdString = await _tokenStorage.getUserId();
    final int? userId = userIdString != null ? int.tryParse(userIdString) : null;

    if (userId == null) {
      print('🚫 No valid user ID');
      return;
    }

    final members = jsonres['members'];
    if (members == null || members.length < 2) {
      print('🚫 Invalid members list');
      return;
    }

    final int lastMessageSenderId = jsonres['last_message_sender_id'] ?? -1;
    final int member0Id = members[0]['user_id'];
    final int member1Id = members[1]['user_id'];

    late int senderId, recipientId;
    late String senderName, recipientName;
    late String senderPic, recipientPic;

    if (lastMessageSenderId == member0Id) {
      senderId = member0Id;
      recipientId = member1Id;
      senderName = members[0]['name'];
      recipientName = members[1]['name'];
      senderPic = members[0]['profile_pic'] ?? '';
      recipientPic = members[1]['profile_pic'] ?? '';
    } else if (lastMessageSenderId == member1Id) {
      senderId = member1Id;
      recipientId = member0Id;
      senderName = members[1]['name'];
      recipientName = members[0]['name'];
      senderPic = members[1]['profile_pic'] ?? '';
      recipientPic = members[0]['profile_pic'] ?? '';
    } else {
      print('🚫 Sender not found in members');
      return;
    }

    final isCurrentUserSender = (userId == senderId);
    final isCurrentUserRecipient = (userId == recipientId);

    if (!isCurrentUserSender && !isCurrentUserRecipient) {
      print('🚫 Current user not in this chat');
      return;
    }

    final storageKey = "aesKey_${senderId}_$recipientId";
          // Check and read from secure storage
    String? base64Key = await secureStorage.read(key: storageKey);
    if (base64Key != null) {
            // Convert Base64 string back to Uint8List
            final Uint8List decryptedAESKey = base64Decode(base64Key);
      if (lastMessage.isEmpty || iv.isEmpty) {
        print('⚠️ Cannot decrypt: lastMessage or IV is empty');
        return;
      }

      final decryptedMessage = decryptionService.decryptMessage(
        lastMessage, decryptedAESKey, iv,
      );

      lastMessage = decryptedMessage;
      print('last message ${lastMessage}');
    } 
    else {

    final storageKey = "aesKey_${recipientId}_$senderId";
          // Check and read from secure storage
    String? base64Key = await secureStorage.read(key: storageKey);
    if (base64Key != null) {
            // Convert Base64 string back to Uint8List
    final Uint8List decryptedAESKey = base64Decode(base64Key);
    if (lastMessage.isEmpty || iv.isEmpty) {
        print('⚠️ Cannot decrypt: lastMessage or IV is empty');
        return;
    }

    final decryptedMessage = decryptionService.decryptMessage(
        lastMessage, decryptedAESKey, iv,
    );

      lastMessage = decryptedMessage;
      print('last message ${lastMessage}');
    } 
    else {

        final keyService = KeyManagementService();
    final senderPublicKey = await keyService.retrievePublicKeyFromBackend(senderId);
    final userPrivateKey = await keyService.retrievePrivateKey(isCurrentUserSender ? senderName : recipientName);
        if (keyId.isEmpty) {
      print('🚫 No keyId provided');
      return;
    }

    final response = await http.get(
      Uri.parse('https://lock-chat-backend.vercel.app/api/decryption/keys/$keyId'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final encryptedKey = isCurrentUserSender ? data['encrypted_key_for_sender'] : data['encrypted_key_for_recipient'];

      if (encryptedKey == null || encryptedKey.isEmpty) {
        print('🚫 Encrypted key not available');
        return;
      }

/*       final Uint8List decryptedAESKey = decryptionService.decryptAESKeyForRecipient(
        encryptedKey, userPrivateKey, senderPublicKey,
      ); */
      final Uint8List decryptedAESKey = base64Decode(encryptedKey);

      print("🔐 Decrypted AES Key: ${base64Encode(decryptedAESKey)}");

      if (lastMessage.isEmpty || iv.isEmpty) {
        print('⚠️ Cannot decrypt: lastMessage or IV is empty');
        return;
      }

      final decryptedMessage = decryptionService.decryptMessage(
        lastMessage, decryptedAESKey, iv,
      );

      lastMessage = decryptedMessage;
      print('last message ${lastMessage}');
    } else {
      print('🚫 Failed to fetch key: ${response.statusCode}');
    }

    }

    }



    // Set name & profile image accordingly
    name = isCurrentUserSender ? recipientName : senderName;
    imageUrl = isCurrentUserSender ? recipientPic : senderPic;


  } catch (e, st) {
    print('❌ Decryption error: $e\n$st');
  }
}

}
