import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../services/decryption_service.dart';
import '../../services/KeyManagementService.dart';
import 'dart:convert'; 
import 'package:pointycastle/pointycastle.dart';
import '../../services/jwt_handler.dart';
import '../../services/tokenStorage.dart';
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
        formattedTime = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
    }

    return Chatroom(
      name: json['name'] ?? 'Unnamed',
      lastMessage: json['last_message'] ?? '',
      time: formattedTime,
      imageUrl: json['imageUrl'] ?? 'https://via.placeholder.com/50',
      unreadMessages: json['unreadMessages'] ?? 0,
      keyId: json['encryption_key_id'] ?? '',  // Ensure encryption_key_id is retrieved
      iv: json['iv'] ?? '',  // Ensure iv is retrieved
    );
  }

  // Method to fetch the decryption key, decrypt the message, and update lastMessage
Future<void> decryptLastMessage(Map<String, dynamic> jsonres, DecryptionService decryptionService) async {
  try {
    final TokenStorage _tokenStorage = TokenStorage();
    final userIdString = await _tokenStorage.getUserId();
    final int? userId = userIdString != null ? int.tryParse(userIdString) : null;

    if (userId == null) {
      print('No valid access token available');
      return;
    }

    int lastMessageSenderId = jsonres['last_message_sender_id'];
    int member0Id = jsonres['members'][0]['user_id'];
    int member1Id = jsonres['members'][1]['user_id'];

    // Identify sender and recipient correctly
    late int senderId;
    late int recipientId;
    late String senderName;
    late String recipientName;

    


    if (lastMessageSenderId == member0Id) {
      senderId = member0Id;
      recipientId = member1Id;
      senderName = jsonres['members'][0]['name'];
      recipientName = jsonres['members'][1]['name'];
     
     
      
    } else if (lastMessageSenderId == member1Id) {
      senderId = member1Id;
      recipientId = member0Id;
      senderName = jsonres['members'][1]['name'];
      recipientName = jsonres['members'][0]['name'];

    } else {
      print('Sender not found in chat members!');
      return;
    }

    // Determine if the current user is the sender or the recipient
    bool isCurrentUserSender = (userId == senderId);
    bool isCurrentUserRecipient = (userId == recipientId);

    if (!isCurrentUserSender && !isCurrentUserRecipient) {
      print('Current user is neither sender nor recipient.');
      return;
    }

    // Fetch the sender's public key
    KeyManagementService _keyManagementService = KeyManagementService();
    ECPublicKey senderPublicKey = await _keyManagementService.retrievePublicKeyFromBackend(senderId);

    // Fetch your private key
    ECPrivateKey userPrivateKey;
    if (isCurrentUserSender) {
      userPrivateKey = await _keyManagementService.retrievePrivateKey(senderName);
      name = recipientName; // Set the chatroom name to the recipient
    
    } else {
      userPrivateKey = await _keyManagementService.retrievePrivateKey(recipientName);
      name = senderName; // Set the chatroom name to the sender
      
    }

    // Fetch the encryption key
    final response = await http.get(
      Uri.parse('https://lock-chat-backend.vercel.app/api/decryption/keys/$keyId'),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);

      // Choose the correct encrypted key based on whether you are sender or recipient
      String encryptedKey;
      if (isCurrentUserSender) {
        encryptedKey = data['encrypted_key_for_sender'];
      } else {
        encryptedKey = data['encrypted_key_for_recipient'];
      }

      // Decrypt the AES key
      Uint8List decryptedAESKey = decryptionService.decryptAESKeyForRecipient(
        encryptedKey, userPrivateKey, senderPublicKey,
      );

      print("🔓 Decrypted AES Key (Base64): ${base64Encode(decryptedAESKey)}");

      // Decrypt the message
      String decryptedMessage = decryptionService.decryptMessage(
        lastMessage, decryptedAESKey, iv,
      );

      // Update the lastMessage
      lastMessage = decryptedMessage;
    } else {
      print('Failed to fetch decryption key, status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error during decryption: $e');
  }
}


}
