import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'encryption_service.dart';
import 'decryption_service.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asn1.dart'; // Add this for ASN.1 parsing
import 'package:pointycastle/pointycastle.dart' as pc;
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/pointycastle.dart' as pc;
import 'package:pointycastle/asymmetric/api.dart';
import 'package:basic_utils/basic_utils.dart';

class KeyManagementService {
  final decryptionService = DecryptionService();
  final EncryptionService encryptionService = EncryptionService();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  
Future<Uint8List> rotateKeyIfNeeded(int senderId, int recipientId) async {
  try {
    // ✅ Check if key rotation is needed
    final Uri checkRotationUrl = Uri.parse(
      'http://192.168.1.22:5000/api/encryption/shouldRotateKey/$senderId/$recipientId',
    );

    final response = await http.get(checkRotationUrl);
    print("Check rotation response: ${response.body}");

    if (response.statusCode == 200) {
      final bool shouldRotate = jsonDecode(response.body)['shouldRotate'];
      print("Should Rotate: $shouldRotate");

      if (shouldRotate) {
        // 🔑 1. Generate a new AES key
        final Uint8List aesKey = encryptionService.generateAESKey();
        print("Generated AES Key: ${base64Encode(aesKey)}");

        // 🔑 2. Fetch public keys for sender & recipient
        final ECPublicKey recipientPublicKey = await fetchRecipientPublicKey(recipientId);
        final ECPublicKey senderPublicKey = await fetchRecipientPublicKey(senderId);
        print("Fetched Public Keys for sender and recipient.");
        final ECPrivateKey senderPrivateKey = await fetchSenderPrivateKey();

        // 🔒 3. Encrypt AES key for both sender & recipient
        final Map<String, String> encryptedKeyForboth =  encryptionService.encryptAESKeyForSenderAndRecipient(aesKey,senderPrivateKey,senderPublicKey, recipientPublicKey);
        final String? encryptedKeyForRecipient =encryptedKeyForboth['encrypted_key_for_recipient'];
        final String? encryptedKeyForSender = encryptedKeyForboth['encrypted_key_for_sender'];
        print("Encrypted AES Key for both sender and recipient.");

        // 🔄 4. Store encrypted keys in backend
        final Uri storeKeyUrl = Uri.parse('http://192.168.1.22:5000/api/encryption/storeEncryptedKey');

        final storeKeyResponse = await http.post(
          storeKeyUrl,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'senderId': senderId,
            'recipientId': recipientId,
            'encryptedKeyForRecipient': encryptedKeyForRecipient,
            'encryptedKeyForSender': encryptedKeyForSender,
          }),
        );

        print("Store Key Response: ${storeKeyResponse.body}");

        // 🔐 5. Save AES key locally
        await secureStorage.write(key: "aesKey_$recipientId", value: base64Encode(aesKey));
        return aesKey;
      } else {
        // ✅ Fetch existing encryption key
        final Uri fetchKeyUrl = Uri.parse(
          'http://192.168.1.22:5000/api/encryption/getEncryptedKey',
        ).replace(queryParameters: {
          'userId': senderId.toString(),
          'isSender': 'true',
        });

        final existingKeyResponse = await http.get(fetchKeyUrl);
        print("Fetch Existing Key Response: ${existingKeyResponse.body}");

        if (existingKeyResponse.statusCode == 200) {
          final Map<String, dynamic> responseData = jsonDecode(existingKeyResponse.body)['encryptedKey'];
          final String encryptedKey = responseData['key'];

          print("Encrypted Key Retrieved: $encryptedKey");
       
          // 🔑 Decrypt AES key using sender's private key
          final ECPublicKey senderPublicKey = await fetchRecipientPublicKey(senderId);
          final ECPrivateKey senderPrivateKey = await fetchSenderPrivateKey();
          final Uint8List aesKey = decryptionService.decryptAESKeyForSender(encryptedKey, senderPrivateKey,senderPublicKey);

          print("Decrypted AES Key: ${base64Encode(aesKey)}");

          // 🔐 Save AES key locally
          await secureStorage.write(key: "aesKey_$recipientId", value: base64Encode(aesKey));
          return aesKey;
        } else {
          throw Exception("Failed to fetch existing encryption key. Server responded: ${existingKeyResponse.statusCode}");
        }
      }
    } else {
      throw Exception("Failed to check key rotation status. Server responded: ${response.statusCode}");
    }
  } catch (error) {
    print("Error in rotateKeyIfNeeded: $error");
    throw Exception("Unexpected error occurred: $error");
  }
}



/* STATIC DATA WAS USED NEED TO BE CHANGED BASED ON THE IMPLEMENTATION OF AUTH AND WHERE FATIMA STORED PRIVATE KEYS*/
Future<ECPrivateKey> fetchReceipentPrivateKey() async {
  /* final String? privateKeyPem = await secureStorage.read(key: "privateKey"); */
  final String? privateKeyPem =
      "-----BEGIN PRIVATE KEY-----\nMIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgBqdF0J9xGmbwM9xN\nKpvRGanygz/kb9c05gOV7X8nI1OhRANCAAQt6hrWyuEuLrI6WnMAzhyvL2QC3nzf\nwnuV9F6Pohfav6TeipIhY9PLwP4UAEPxI72LP/ArBdhuevsggMV8Lyc3\n-----END PRIVATE KEY-----\n";
  
  if (privateKeyPem == null) {
    throw Exception("Private key not found in secure storage.");
  }

  try {
    final ECPrivateKey ecPrivateKey = CryptoUtils.ecPrivateKeyFromPem(privateKeyPem);
    print("[DEBUG] Parsed EC Private Key: $ecPrivateKey");
    return ecPrivateKey;
  } catch (e) {
    throw Exception("Failed to parse EC private key: $e");
  }
}

/* STATIC DATA WAS USED NEED TO BE CHANGED BASED ON THE IMPLEMENTATION OF AUTH AND WHERE FATIMA STORED PRIVATE KEYS */
Future<ECPrivateKey> fetchSenderPrivateKey() async {
  /* final String? privateKeyPem = await secureStorage.read(key: "privateKey"); */
  final String? privateKeyPem =
      "-----BEGIN PRIVATE KEY-----\nMIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQg5Wt4rIfs7XglgsxI\nFtwDrgzk69TFQ6O2Db9d+c3OG1ShRANCAATcbRPvGmRtPjMVZeaAPhxC26s35iCG\nTOPCzjLK/YNvZ41L1kmAIj0q0prCPO0RuGIm7i7fsmJyaFTFn+prr47G\n-----END PRIVATE KEY-----\n";
  
  if (privateKeyPem == null) {
    throw Exception("Private key not found in secure storage.");
  }

  try {
    final ECPrivateKey ecPrivateKey = CryptoUtils.ecPrivateKeyFromPem(privateKeyPem);
    print("[DEBUG] Parsed EC Private Key: $ecPrivateKey");
    return ecPrivateKey;
  } catch (e) {
    throw Exception("Failed to parse EC private key: $e");
  }
}

Future<ECPublicKey> fetchRecipientPublicKey(int recipientId) async {
  final response = await http.get(
    Uri.parse('http://192.168.1.22:5000/api/encryption/users/$recipientId/publicKey'),
  );

  if (response.statusCode == 200) {
    final String publicKeyPem = jsonDecode(response.body)['publicKey'];
    
    // Debugging: Print the received public key
    print("Fetched Public Key PEM:\n$publicKeyPem");

    try {
      final ECPublicKey ecPublicKey = CryptoUtils.ecPublicKeyFromPem(publicKeyPem);
      print("Parsed EC Public Key: $ecPublicKey");
      return ecPublicKey;
    } catch (e) {
      throw Exception("Failed to parse EC public key: $e");
    }
  } else {
    throw Exception("Failed to fetch recipient's public key");
  }
}



}
