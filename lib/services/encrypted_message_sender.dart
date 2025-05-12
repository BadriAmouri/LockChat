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
import '../../services/tokenStorage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final EncryptionService _encryptionService = EncryptionService();
final KeyManagementService _keymanagementService=KeyManagementService();
final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

Future<void> sendEncryptedMessage_local(int receipentid,String sendername,String message,int chatroomId)async {
  try {
    print("🔐 Starting encryption and message sending...");

    final TokenStorage _tokenStorage = TokenStorage();
    final userIdString = await _tokenStorage.getUserId();
    final int? userId = userIdString != null ? int.tryParse(userIdString) : null;
    if (userId == null) {
      print('🚫 No valid user ID');
      return;
    }
    // Get AES Key and Key ID from Key Rotation logic
    Map<String, dynamic> keyData = await _keymanagementService.rotateKeyIfNeeded(userId, receipentid, sendername);
    Uint8List aesKey = keyData['aesKey'];
    String keyId = keyData['keyId'];

    print("🗝️ AES Key (Base64): ${base64Encode(aesKey)}");
    print("🆔 AES Key ID: $keyId");

    // Encrypt the message
    /* String message = "🌍 I M SO HAPPY  !"; */
    Map<String, String> encryptedData = _encryptionService.encryptMessage(message, aesKey);

    String encryptedMessage = encryptedData['encryptedMessage']!;
    String iv = encryptedData['iv']!;

    print("🧪 IV: $iv");
    print("📤 Encrypted Message: $encryptedMessage");

    // Send Encrypted Message
    await MessageAPIService.sendEncryptedMessage(
      senderId: userId.toString(),
      recipientId: receipentid.toString(),
      chatroomId: chatroomId.toString(),
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

Future<void> decryptReceivedMessage(String username,int othermemberid) async {
  try {
    print("🧩 Starting decryption for recipient...");
    final TokenStorage _tokenStorage = TokenStorage();
    final userIdString = await _tokenStorage.getUserId();
    final int? userId = userIdString != null ? int.tryParse(userIdString) : null;
    if (userId == null) {
      print('🚫 No valid user ID');
      return;
    }
    // Get recipient and sender keys
    ECPrivateKey recipientPrivateKey = await _keymanagementService.retrievePrivateKey(username);
    ECPublicKey senderPublicKey = await _keymanagementService.retrievePublicKeyFromBackend(othermemberid);
    ECPublicKey recipientPublicKey = await _keymanagementService.retrievePublicKeyFromBackend(userId);
    print('[SENDER] recipientPublicKey.Q: ${recipientPublicKey.Q}');
    print('[RECIPIENT] senderPublicKey.Q: ${senderPublicKey.Q}');

    final decryptionService = DecryptionService();

    // Fetch recipient's latest message
    List<dynamic> recipientMessages = await MessageAPIService.getMessagesByRecipient(userId.toString());

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
      Uri.parse('https://lock-chat-backend.vercel.app/api/decryption/keys/$keyId'),
    );

    if (response.statusCode != 200) {
      throw Exception("🔐 Failed to fetch encrypted key");
    }

    Map<String, dynamic> data = json.decode(response.body);
    String encryptedKeyForRecipient = data['encrypted_key_for_recipient'];
    /* PLEASE STORE THIS KEY IN SHARED PREFRENCES */
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


Future<String> decryptReceivedMessageWithStoredaesKey(
  String username,
  int othermemberid,
  String messageData,
  String the_iv,
  String MessageKey,
) async {
  try {
    print("🧩 Starting decryption for recipient...");
    final TokenStorage _tokenStorage = TokenStorage();
    final userIdString = await _tokenStorage.getUserId();
    final int? userId = userIdString != null ? int.tryParse(userIdString) : null;
    if (userId == null) {
      print('🚫 No valid user ID');
      return "Error: Invalid user ID";
    }

    // Get recipient and sender keys
    ECPrivateKey recipientPrivateKey = await _keymanagementService.retrievePrivateKey(username);
    ECPublicKey senderPublicKey = await _keymanagementService.retrievePublicKeyFromBackend(othermemberid);
    ECPublicKey recipientPublicKey = await _keymanagementService.retrievePublicKeyFromBackend(userId);
    print('[SENDER] recipientPublicKey.Q: ${recipientPublicKey.Q}');
    print('[RECIPIENT] senderPublicKey.Q: ${senderPublicKey.Q}');

    final decryptionService = DecryptionService();

    final encryptedMessage = messageData;
    final iv = the_iv;

    print("📨 Encrypted Message Received: $encryptedMessage");
    print("🧪 IV Received: $iv");


    final storageKey = "aesKey_${userId}_$othermemberid";
          // Check and read from secure storage
    String? base64Key = await secureStorage.read(key: storageKey);
    if (base64Key != null) {
      print("The key in secure storage is not null");
      // Convert Base64 string back to Uint8List
      final Uint8List decryptedAESKey = base64Decode(base64Key);
      if (encryptedMessage.isEmpty || iv.isEmpty) {
        print('⚠️ Cannot decrypt: lastMessage or IV is empty');
      }
      print("AES KEY is  ${decryptedAESKey} ");
      print("try to decrypt the message");
      final decryptedMessage = decryptionService.decryptMessage(
        encryptedMessage, decryptedAESKey, iv,
      );
      print('last message ${decryptedMessage}');
      
    return decryptedMessage;

    } 
    else{
    
    final storageKey = "aesKey_${othermemberid}_$userId";
    // Check and read from secure storage
    String? base64Key = await secureStorage.read(key: storageKey);
    if (base64Key != null) {
      print("The key in secure storage is not null");
      // Convert Base64 string back to Uint8List
      final Uint8List decryptedAESKey = base64Decode(base64Key);
      if (encryptedMessage.isEmpty || iv.isEmpty) {
        print('⚠️ Cannot decrypt: lastMessage or IV is empty');
      }
      final decryptedMessage = decryptionService.decryptMessage(
        encryptedMessage, decryptedAESKey, iv,
      );
      print('last message ${decryptedMessage}');
    
    return decryptedMessage;

    } 
    else{

       // Get the AES key from the backend
    final response = await http.get(
      Uri.parse('https://lock-chat-backend.vercel.app/api/decryption/keys/$MessageKey'),
    );

    if (response.statusCode != 200) {
      throw Exception("🔐 Failed to fetch encrypted key");
    }

    Map<String, dynamic> data = json.decode(response.body);
    String encryptedKeyForRecipient = data['encrypted_key_for_recipient'];
    print("🔒 Encrypted AES Key for Recipient: $encryptedKeyForRecipient");

    // Decrypt AES Key using recipient's private + sender's public
  /*   Uint8List decryptedAESKey = decryptionService.decryptAESKeyForRecipient(
      encryptedKeyForRecipient,
      recipientPrivateKey,
      senderPublicKey,
    ); */
    final Uint8List decryptedAESKey = base64Decode(encryptedKeyForRecipient);

    print("🔓 Decrypted AES Key (Base64): ${(decryptedAESKey)}");

    // Validate input
    if (encryptedMessage.isEmpty || iv.isEmpty) {
      print("🚫 Missing encrypted message or IV");
      return "Error: Missing data";
    }

    // Decrypt the message
    String decryptedMessage = decryptionService.decryptMessage(
      encryptedMessage,
      decryptedAESKey,
      iv,
    );
    print("✅ Decrypted Message: $decryptedMessage");
    return decryptedMessage;



    }

    }

  
  } catch (e) {
    print("❌ Error during recipient decryption: $e");
    return "Error: $e";
  }
}
