
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
  final String imageUrl;
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
      print('🔍 Type of keyId: ${jsonres['encryption_key_id'].runtimeType}');
      print('🔍 Type of iv: ${jsonres['iv'].runtimeType}');
      print('🔍 Type of members id : ${jsonres['members'][1]['user_id'].runtimeType}');
      print('🔍 Type of members id: ${jsonres['members'][1]['user_id'].runtimeType}');
      final TokenStorage _tokenStorage = TokenStorage();
      final userIdString = await _tokenStorage.getUserId();
      final int? userId = userIdString != null ? int.tryParse(userIdString) : null;

      if (userId == null) {
        print('No valid access token available');
        return;
      }
      // Determine if the current user is the sender or the recipient
      bool isSender = userId == jsonres['members'][1]['user_id'];
      bool isRecipient = userId == jsonres['members'][0]['user_id'];

      if (!isSender && !isRecipient) {
        print('User not found in this chatroom members');
        return;
      }

      // Fetch the private key based on whether the user is sender or recipient
      KeyManagementService _keymanagementService = KeyManagementService();
      ECPublicKey senderPublicKey = await _keymanagementService.retrievePublicKeyFromBackend(jsonres['members'][1]['user_id'] );

      ECPrivateKey userPrivateKey;
      if (isSender) {
        userPrivateKey = await _keymanagementService.retrievePrivateKey(jsonres['members'][1]['name']);
        name = jsonres['members'][0]['name'];
      } else {
        name = jsonres['members'][1]['name'];
        userPrivateKey = await _keymanagementService.retrievePrivateKey(jsonres['members'][0]['name']);
      }

      // Fetch the encryption key based on whether the user is sender or recipient
      final response = await http.get(
        Uri.parse('http://10.80.1.239:5000/api/decryption/keys/$keyId'),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);

        // Extract the encrypted key for the recipient (based on the user's role)
        String encryptedKeyForRecipient = '';
      if (isSender) {
        encryptedKeyForRecipient = data['encrypted_key_for_sender'];
      } else {
        encryptedKeyForRecipient = data['encrypted_key_for_recipient'];
      }


        // Decrypt the AES key for the recipient using the decryption service
        Uint8List decryptedAESKey = decryptionService.decryptAESKeyForRecipient(
          encryptedKeyForRecipient, userPrivateKey, senderPublicKey
        );

        print("🔓 Decrypted AES Key (Base64): ${base64Encode(decryptedAESKey)}");

        // Decrypt the message using the decrypted AES key
        String decryptedMessage = decryptionService.decryptMessage(
          lastMessage, decryptedAESKey, iv,
        );

        // Update the lastMessage with the decrypted message
        lastMessage = decryptedMessage;
      } else {
        print('Failed to fetch decryption key, status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during decryption: $e');
    }
  }

}
