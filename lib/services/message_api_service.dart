import 'dart:convert';
import 'package:http/http.dart' as http;

class MessageAPIService {
  static const String _baseUrl = 'http://192.168.1.22:5000/api/encryption'; // Change if using a real server
  static const String _decbaseUrl = 'http://192.168.1.22:5000/api/decryption';
  /// Sends an encrypted message to the server
  static Future<void> sendEncryptedMessage({
    required String senderId,
    required String recipientId,
    required String chatroomId,
    required String encryptedMessage,
    required String encryptedKey,
    required String iv, 
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
          "iv": iv,
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
  /// DEFINED THESE  TO TEST DECRYPTION
  /// Retrieves messages sent by a specific sender
  static Future<List<dynamic>> getMessagesBySender(String senderId) async {
    final url = Uri.parse('$_decbaseUrl/messages/sender/$senderId');

    try {
      print("Fetching messages sent by senderId: $senderId");
      final response = await http.get(url, headers: {"Content-Type": "application/json"});

      if (response.statusCode == 200) {
        print("Messages retrieved successfully");
        return jsonDecode(response.body);
      } else {
        print("Failed to fetch messages: ${response.statusCode} ${response.body}");
        return [];
      }
    } catch (error) {
      print("Error fetching messages by sender: $error");
      return [];
    }
  }

  /// Retrieves messages received by a specific recipient
  static Future<List<dynamic>> getMessagesByRecipient(String recipientId) async {
    final url = Uri.parse('$_decbaseUrl/messages/recipient/$recipientId');

    try {
      print("Fetching messages received by recipientId: $recipientId");
      final response = await http.get(url, headers: {"Content-Type": "application/json"});

      if (response.statusCode == 200) {
        print("Messages retrieved successfully");
        return jsonDecode(response.body);
      } else {
        print("Failed to fetch messages: ${response.statusCode} ${response.body}");
        return [];
      }
    } catch (error) {
      print("Error fetching messages by recipient: $error");
      return [];
    }
  }
}
