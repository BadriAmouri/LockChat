import 'dart:convert';
import 'package:http/http.dart' as http;

class MessageAPIService {
  static const String _baseUrl = 'http://192.168.1.10:5000/api/encryption'; // Change if using a real server

  /// Sends an encrypted message to the server
  static Future<void> sendEncryptedMessage({
    required String senderId,
    required String recipientId,
    required String chatroomId,
    required String encryptedMessage,
    required String encryptedKey,
    required String messageType,
  }) async {
    final url = Uri.parse('$_baseUrl/encrypt-message');

    try {
      print("sendEncryptedMessage from MessageAPIService is called");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "senderId": senderId,
          "recipientId": recipientId,
          "chatroomId": chatroomId,
          "encryptedMessage": encryptedMessage,
          "encryptedKey": encryptedKey,
          "messageType": messageType,
        }),
      );
      print("Response: ${response.statusCode}, Body: ${response.body}");


      if (response.statusCode == 200) {
        print("Message sent successfully: ${response.body}");
      } else {
        print("Failed to send message: ${response.statusCode} ${response.body}");
      }
    } catch (error) {
      print("Error sending encrypted message: $error");
    }
  }
}
