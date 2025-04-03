import 'dart:typed_data'; // ✅ Add this import
import 'package:flutter/material.dart';
import '../../services/encryption_service.dart';
import '../../services/KeyManagementService.dart';
import '../../services/message_api_service.dart';
import 'dart:convert'; // ✅ Needed for base64Encode
import 'package:http/http.dart' as http;
  import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/decryption_service.dart'; // Your decryption logic
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asn1.dart'; // Add this for ASN.1 parsing
import 'package:pointycastle/pointycastle.dart' as pc;
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/pointycastle.dart' as pc;
import 'package:pointycastle/asymmetric/api.dart';
import 'package:basic_utils/basic_utils.dart';
/* THIS IS NOT THE ACTUAL UI WAS ONLY USED FOR TESTING PURPOSE */
class ChatScreen extends StatelessWidget {
  final EncryptionService _encryptionService = EncryptionService();
  final KeyManagementService _keymanagementService=KeyManagementService();
  void _sendMessage() async {
    // Generate AES Key
    Uint8List aesKey = await _keymanagementService.rotateKeyIfNeeded(9, 10);
    // Encrypt Message
    String message = "YAA RABII TEMCHIII!!!!!!!!";
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
      iv: encryptedData['iv']!,
      messageType: "text",
    );
  }


Future<void> testDecryption({
  required String senderId,
  required String recipientId,
  required ECPrivateKey senderPrivateKey,
  required ECPrivateKey recipientPrivateKey,
  required ECPublicKey senderPublicKey,
  required ECPublicKey recipientPublicKey,
}) async {
  try {
    // Fetch messages sent by sender
    List<dynamic> senderMessages = await MessageAPIService.getMessagesBySender(senderId);
    print("Sender Messages: $senderMessages");

    // Fetch messages received by recipient
    List<dynamic> recipientMessages = await MessageAPIService.getMessagesByRecipient(recipientId);
    print("Recipient Messages: $recipientMessages");

    if (senderMessages.isEmpty || recipientMessages.isEmpty) {
      print("No messages found for decryption.");
      return;
    }

    final decryptionService = DecryptionService();
    print("DecryptionService called successfuly .");
    // Pick the first message for testing
    final messageData = senderMessages[0]; // Assuming messages have same content for both
    print("First message of sender fetched .");
    String encryptedMessage = messageData['encrypted_message'];
    print("First message of sender encryptedMessage fetched .");
    String encryptedKeyid = messageData['encryption_key_id'];
    print("First message of sender encryptedKeyid fetched .");
    String iv = messageData['iv'];
    print("First message of sender iv fetched .");
    // Decrypt AES Key for Sender
    final encryptedKeyResponse = await http.get(
    Uri.parse('http://192.168.1.22:5000/api/decryption/keys/$encryptedKeyid'),
    );

   if (encryptedKeyResponse.statusCode == 200) {
  // Decode the response body as JSON
  Map<String, dynamic> responseData = json.decode(encryptedKeyResponse.body);
  
  // Access the 'encrypted_key_for_sender' from the decoded response
  String encryptedKey = responseData['encrypted_key_for_sender'];
  String encryptedKeyforrec = responseData['encrypted_key_for_recipient'];
  print('Encrypted Key for Sender: $encryptedKey');
     Uint8List senderAESKey = decryptionService.decryptAESKeyForSender(
      encryptedKey, senderPrivateKey, senderPublicKey,
    );
    print("decryptAESKeyForSender called successfuly .");
    print("Sender Decrypted AES Key: $senderAESKey");

    // Decrypt Message as Sender
    String decryptedMessageSender = decryptionService.decryptMessage(
      encryptedMessage, senderAESKey, iv,
    );
    print("Decrypted Message by Sender: $decryptedMessageSender");

    // Decrypt AES Key for Recipient
    Uint8List recipientAESKey = decryptionService.decryptAESKeyForRecipient(
      encryptedKeyforrec, recipientPrivateKey, senderPublicKey,
    );
    print("Recipient Decrypted AES Key: $recipientAESKey");

    // Decrypt Message as Recipient
    String decryptedMessageRecipient = decryptionService.decryptMessage(
      encryptedMessage, recipientAESKey, iv,
    );
    print("Decrypted Message by Recipient: $decryptedMessageRecipient");

   } else {
  throw Exception('Failed to load encrypted key');
    }
 
  } catch (e) {
    print("Error in decryption testing: $e");
  }
}
  void _testDecryption() async {
    try {
      // Fetch keys
      ECPrivateKey senderPrivateKey = await _keymanagementService.fetchSenderPrivateKey();
      ECPrivateKey recipientPrivateKey = await _keymanagementService.fetchReceipentPrivateKey();
      ECPublicKey senderPublicKey = await _keymanagementService.fetchRecipientPublicKey(9); // Sender's public key
      ECPublicKey recipientPublicKey = await _keymanagementService.fetchRecipientPublicKey(10); // Recipient's public key

      // Call testDecryption
      await testDecryption(
        senderId: "9",
        recipientId: "10",
        senderPrivateKey: senderPrivateKey,
        recipientPrivateKey: recipientPrivateKey,
        senderPublicKey: senderPublicKey,
        recipientPublicKey: recipientPublicKey,
      );
    } catch (e) {
      print("Error fetching keys for decryption: $e");
    }
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
