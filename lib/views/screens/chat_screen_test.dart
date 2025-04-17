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
  // create the route of the chat screen 
  static const String routeName = '/ChatScreen';
  final EncryptionService _encryptionService = EncryptionService();
  final KeyManagementService _keymanagementService=KeyManagementService();
  Future<void> sendMessageTest() async {
  try {
    print("🔐 Starting encryption and message sending...");

    // Get AES Key and Key ID from Key Rotation logic
    Map<String, dynamic> keyData = await _keymanagementService.rotateKeyIfNeeded(57, 49, "kuroo");
    Uint8List aesKey = keyData['aesKey'];
    String keyId = keyData['keyId'];

    print("🗝️ AES Key (Base64): ${base64Encode(aesKey)}");
    print("🆔 AES Key ID: $keyId");

    // Encrypt the message
    String message = "🌍 sup momo  !";
    Map<String, String> encryptedData = _encryptionService.encryptMessage(message, aesKey);

    String encryptedMessage = encryptedData['encryptedMessage']!;
    String iv = encryptedData['iv']!;

    print("🧪 IV: $iv");
    print("📤 Encrypted Message: $encryptedMessage");

    // Send Encrypted Message
    await MessageAPIService.sendEncryptedMessage(
      senderId: "57",
      recipientId: "49",
      chatroomId: "7",
      encryptedMessage: encryptedMessage,
      encryptedKey: keyId,
      iv: iv,
      messageType: "text",
    );

    print("✅ Message sent successfully!");
  } catch (e) {
    print("❌ Error sending message: $e");
  }
}
Future<void> decryptForRecipientTest() async {
  try {
    print("🧩 Starting decryption for recipient...");

    // Get recipient and sender keys
    ECPrivateKey recipientPrivateKey = await _keymanagementService.retrievePrivateKey("momo");
    ECPublicKey senderPublicKey = await _keymanagementService.retrievePublicKeyFromBackend(57);
    ECPublicKey recipientPublicKey = await _keymanagementService.retrievePublicKeyFromBackend(49);
    print('[SENDER] recipientPublicKey.Q: ${recipientPublicKey.Q}');
    print('[RECIPIENT] senderPublicKey.Q: ${senderPublicKey.Q}');

    final decryptionService = DecryptionService();

    // Fetch recipient's latest message
    List<dynamic> recipientMessages = await MessageAPIService.getMessagesByRecipient("49");

    if (recipientMessages.isEmpty) {
      print("⚠️ No messages found for recipient.");
      return;
    }

    final messageData = recipientMessages[0];

    String encryptedMessage = messageData['encrypted_message'];
    String keyId = messageData['encryption_key_id'];
    String iv = messageData['iv'];

    print("📨 Encrypted Message Received: $encryptedMessage");
    print("🆔 AES Key ID: $keyId");
    print("🧪 IV Received: $iv");

    // Fetch Encrypted AES Key from Server
    final response = await http.get(
      Uri.parse('http://10.80.1.212:5000/api/decryption/keys/$keyId'),
    );

    if (response.statusCode != 200) {
      throw Exception("🔐 Failed to fetch encrypted key");
    }

    Map<String, dynamic> data = json.decode(response.body);
    String encryptedKeyForRecipient = data['encrypted_key_for_recipient'];

    print("🔒 Encrypted AES Key for Recipient: $encryptedKeyForRecipient");

    // Decrypt AES Key using recipient's private + sender's public
    Uint8List decryptedAESKey = decryptionService.decryptAESKeyForRecipient(
      encryptedKeyForRecipient, recipientPrivateKey, senderPublicKey,
    );

    print("🔓 Decrypted AES Key (Base64): ${base64Encode(decryptedAESKey)}");

    // Decrypt the message
    String decryptedMessage = decryptionService.decryptMessage(
      encryptedMessage, decryptedAESKey, iv,
    );

    print("✅ Decrypted Message: $decryptedMessage");
  } catch (e) {
    print("❌ Error during recipient decryption: $e");
  }
}


  void _sendMessage() async {
    // Generate AES Key
    Map<String, dynamic> keyData = await _keymanagementService.rotateKeyIfNeeded(50, 51, "jake");
    Uint8List aesKey = keyData['aesKey'];
    String keyId = keyData['keyId'];
    // Encrypt Message
    String message = "!!!! 🌍 yEYYYYYY  !!!!";
    Map<String, String> encryptedData = _encryptionService.encryptMessage(message, aesKey);
    print("Encrypted Message: ${encryptedData['encryptedMessage']}");
    print("IV: ${encryptedData['iv']}");


    // Encrypt AES Key as an Id i should make the function rotateKeyIfNeeded returns the id as well to store it 
   /*   String encryptedKey = base64Encode(aesKey);
    print("Encrypted Key: $encryptedKey"); 
 */

    // Send encrypted message
    await MessageAPIService.sendEncryptedMessage(
      senderId: "50",
      recipientId: "51",
      chatroomId: "4",
      encryptedMessage: encryptedData['encryptedMessage']!,
      encryptedKey: keyId,
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
    final messageDataRec = recipientMessages[0];
    print("First message of receipent fetched .");
    String encryptedMessage = messageData['encrypted_message'];
    print("First message of sender encryptedMessage fetched .");
    String encryptedMessagerec = messageDataRec['encrypted_message'];
    print("First message of receipent encryptedMessage fetched .");
    String encryptedKeyid = messageData['encryption_key_id'];
    print("First message of sender encryptedKeyid fetched .");
    String encryptedKeyidrec = messageDataRec['encryption_key_id'];
    print("First message of receipent encryptedKeyid fetched .");
    String iv = messageData['iv'];
    print("First message of sender iv fetched .");
    String ivrec = messageDataRec['iv'];
    print("First message of receipent iv fetched .");
    // Decrypt AES Key for Sender
    final encryptedKeyResponse = await http.get(
    Uri.parse('http://10.80.1.212:5000/api/decryption/keys/$encryptedKeyid'),
    );

   if (encryptedKeyResponse.statusCode == 200) {
  // Decode the response body as JSON
  Map<String, dynamic> responseData = json.decode(encryptedKeyResponse.body);
  
  // Access the 'encrypted_key_for_sender' from the decoded response
  String encryptedKey = responseData['encrypted_key_for_sender'];
  String encryptedKeyforrec = responseData['encrypted_key_for_recipient'];
  print('Encrypted Key for Sender: $encryptedKey');
  print('Encrypted Key for Recipient: $encryptedKeyforrec');
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
    print("Encrypted aes Key for Receipent sent as param to decryptAESKeyForRecipient: $encryptedKeyforrec");
    print("Receipent private Key sent as param to decryptAESKeyForRecipient: $recipientPrivateKey");
    print("Sender public Key sent as param to decryptAESKeyForRecipient: $senderPublicKey");
    
    // Decrypt AES Key for Recipient
    Uint8List recipientAESKey = decryptionService.decryptAESKeyForRecipient(
      encryptedKeyforrec, recipientPrivateKey, senderPublicKey,
    );
    print("Recipient Decrypted AES Key: $recipientAESKey");

    // Decrypt Message as Recipient
    String decryptedMessageRecipient = decryptionService.decryptMessage(
      encryptedMessagerec, recipientAESKey, ivrec,
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
      ECPrivateKey senderPrivateKey = await _keymanagementService.retrievePrivateKey("jake");
      ECPrivateKey recipientPrivateKey = await _keymanagementService.retrievePrivateKey("heesu");
      ECPublicKey senderPublicKey = await _keymanagementService.retrievePublicKeyFromBackend(50); // Sender's public key
      ECPublicKey recipientPublicKey = await _keymanagementService.retrievePublicKeyFromBackend(51); // Recipient's public key
      print(senderPrivateKey.parameters?.curve);
      print(senderPublicKey.parameters?.curve);
      print(recipientPrivateKey.parameters?.curve);
      print(recipientPublicKey.parameters?.curve);

      // Call testDecryption
      await testDecryption(
        senderId: "50",
        recipientId: "51",
        senderPrivateKey: senderPrivateKey,
        recipientPrivateKey: recipientPrivateKey,
        senderPublicKey: senderPublicKey,
        recipientPublicKey: recipientPublicKey,
      );
    } catch (e) {
      print("Error fetching keys for decryption: $e");
    }
  }


  Future<void> testDecryptionrec({
  required String senderId,
  required String recipientId,
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
    final messageDataRec = recipientMessages[0];
    print("First message of receipent fetched .");
    String encryptedMessagerec = messageDataRec['encrypted_message'];
    print("First message of sender encryptedKeyid fetched .");
    String encryptedKeyidrec = messageDataRec['encryption_key_id'];
    print("First message of receipent encryptedKeyid fetched .");
    String ivrec = messageDataRec['iv'];
    print("First message of receipent iv fetched .");
    // Decrypt AES Key for Sender
    final encryptedKeyResponse = await http.get(
    Uri.parse('http://10.80.1.212:5000/api/decryption/keys/$encryptedKeyidrec'),
    );

   if (encryptedKeyResponse.statusCode == 200) {
  // Decode the response body as JSON
  Map<String, dynamic> responseData = json.decode(encryptedKeyResponse.body);
  
  // Access the 'encrypted_key_for_sender' from the decoded response
  String encryptedKey = responseData['encrypted_key_for_sender'];
  String encryptedKeyforrec = responseData['encrypted_key_for_recipient'];
  print('Encrypted Key for Sender: $encryptedKey');
  print('Encrypted Key for Recipient: $encryptedKeyforrec');

    // Decrypt AES Key for Recipient
    Uint8List recipientAESKey = decryptionService.decryptAESKeyForRecipient(
      encryptedKeyforrec, recipientPrivateKey, senderPublicKey,
    );
    print("Recipient Decrypted AES Key: $recipientAESKey");

    // Decrypt Message as Recipient
    String decryptedMessageRecipient = decryptionService.decryptMessage(
      encryptedMessagerec, recipientAESKey, ivrec,
    );
    print("Decrypted Message by Recipient: $decryptedMessageRecipient");

   } else {
  throw Exception('Failed to load encrypted key');
    }
 
  } catch (e) {
    print("Error in decryption testing: $e");
  }
}
  void _testDecryptionrec() async {
    try {
      // Fetch keys
      ECPrivateKey recipientPrivateKey = await _keymanagementService.retrievePrivateKey("suna");
      ECPublicKey senderPublicKey = await _keymanagementService.retrievePublicKeyFromBackend(17); // Sender's public key
      ECPublicKey recipientPublicKey = await _keymanagementService.retrievePublicKeyFromBackend(16); // Recipient's public key

      // Call testDecryption
      await testDecryptionrec(
        senderId: "17",
        recipientId: "16",
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
          onPressed: sendMessageTest,
          child: Text("Send Encrypted Message"),
        ),
      ),
    );
  }
}
