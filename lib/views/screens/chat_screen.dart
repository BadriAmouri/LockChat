import 'dart:typed_data'; // ✅ Add this import
import 'package:flutter/material.dart';
import '../../services/encryption_service.dart';
import '../../services/KeyManagementService.dart';
import '../../services/message_api_service.dart';
import 'dart:convert'; // ✅ Needed for base64Encode
import 'package:http/http.dart' as http;

class ChatScreen extends StatelessWidget {
  final EncryptionService _encryptionService = EncryptionService();
  final KeyManagementService _keymanagementService=KeyManagementService();
  void _sendMessage() async {
    // Generate AES Key
    Uint8List aesKey = await _keymanagementService.rotateKeyIfNeeded(4, 2);
    // Encrypt Message
    String message = "We are testing, this is a secret!";
    Map<String, String> encryptedData = _encryptionService.encryptMessage(message, aesKey);
    print("Encrypted Message: ${encryptedData['encryptedMessage']}");
    print("IV: ${encryptedData['iv']}");


    // Encrypt AES Key (for simplicity, using Base64 without RSA for now)
    String encryptedKey = base64Encode(aesKey);
    print("Encrypted Key: $encryptedKey");


    // Send encrypted message
    await MessageAPIService.sendEncryptedMessage(
      senderId: "9",
      recipientId: "10",
      chatroomId: "1",
      encryptedMessage: encryptedData['encryptedMessage']!,
      encryptedKey: encryptedKey,
      messageType: "text",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chat")),
      body: Center(
        child: ElevatedButton(
          onPressed: _sendMessage,
          child: Text("Send Encrypted Message"),
        ),
      ),
    );
  }
}
