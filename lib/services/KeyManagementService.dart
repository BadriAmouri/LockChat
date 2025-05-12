import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'encryption_service.dart';
import 'decryption_service.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asn1.dart'; // Add this for ASN.1 parsing
import 'package:basic_utils/basic_utils.dart';
import 'package:pointycastle/pointycastle.dart' as pc;
import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/export.dart';
import 'package:asn1lib/asn1lib.dart' as asn1lib;
import 'package:pointycastle/asn1.dart' as pc_asn1;
import 'package:pointycastle/ecc/api.dart';
class KeyManagementService {
  final decryptionService = DecryptionService();
  final EncryptionService encryptionService = EncryptionService();
  static final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  
Future<Map<String, dynamic>> rotateKeyIfNeeded(int senderId, int recipientId, String sendername) async {
  try {
    final Uri checkRotationUrl = Uri.parse(
      'https://lock-chat-backend.vercel.app/api/encryption/shouldRotateKey/$senderId/$recipientId',
    );

    final response = await http.get(checkRotationUrl);
    print("Check rotation response: ${response.body}");

    if (response.statusCode == 200) {
      final bool shouldRotate = jsonDecode(response.body)['shouldRotate'];
      print("Should Rotate: $shouldRotate");

      if (shouldRotate) {
        // 🔑 1. Generate new AES key
        final Uint8List aesKey = encryptionService.generateAESKey();
        print("Generated AES Key: ${base64Encode(aesKey)}");

        // 🔑 2. Fetch public keys
        final ECPublicKey recipientPublicKey = await retrievePublicKeyFromBackend(recipientId);
        final ECPublicKey senderPublicKey = await retrievePublicKeyFromBackend(senderId);
        final ECPrivateKey senderPrivateKey = await retrievePrivateKey(sendername);

        // 🔒 3. Encrypt AES key
        final Map<String, String> encryptedKeyForboth = encryptionService.encryptAESKeyForSenderAndRecipient(
          aesKey, senderPrivateKey, senderPublicKey, recipientPublicKey,
        );

        final String? encryptedKeyForRecipient = encryptedKeyForboth['encrypted_key_for_recipient'];
        final String? encryptedKeyForSender = encryptedKeyForboth['encrypted_key_for_sender'];

        // 🔄 4. Store encrypted keys
        final Uri storeKeyUrl = Uri.parse('https://lock-chat-backend.vercel.app/api/encryption/storeEncryptedKey');
        final storeKeyResponse = await http.post(
          storeKeyUrl,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'senderId': senderId,
            'recipientId': recipientId,
            'encryptedKeyForRecipient':  base64Encode(aesKey),
            'encryptedKeyForSender':  base64Encode(aesKey),
          }),
        );

        print("Store Key Response: ${storeKeyResponse.body}");

        final Map<String, dynamic> responseBody = jsonDecode(storeKeyResponse.body);
        final String keyId = responseBody['insertedKeyId'];

        // 🔐 Save AES key locally
        await secureStorage.write(key: "aesKey_${senderId}_$recipientId", value: base64Encode(aesKey));
        await secureStorage.write(key: "keyId_${senderId}_$recipientId", value: keyId);

        return {
          'aesKey': aesKey,
          'keyId': keyId,
        };
      } else {
        // 🔁 Try to retrieve locally stored AES key
        final String? base64Key = await secureStorage.read(key: "aesKey_${senderId}_$recipientId");
        final String? keyIdString = await secureStorage.read(key: "keyId_${senderId}_$recipientId");

        if (base64Key != null && keyIdString != null) {
          final Uint8List aesKey = base64Decode(base64Key);
          print("AES KEY WHILE ENCRYPTION is  ${aesKey}");

          return {
            'aesKey': aesKey,
            'keyId': keyIdString,
          };
        } else {
          // 🔁 Try reversed key
          final String? base64KeyReverse = await secureStorage.read(key: "aesKey_${recipientId}_$senderId");
          final String? keyIdStringReverse = await secureStorage.read(key: "keyId_${recipientId}_$senderId");

          if (base64KeyReverse != null && keyIdStringReverse != null) {
            final Uint8List aesKey = base64Decode(base64KeyReverse);
            print("AES KEY WHILE ENCRYPTION is  ${aesKey}");

            return {
              'aesKey': aesKey,
              'keyId': keyIdStringReverse,
            };
          } else {
            // 🌐 Fetch from backend as fallback
            final Uri fetchKeyUrl = Uri.parse(
              'https://lock-chat-backend.vercel.app/api/encryption/getEncryptedKey',
            ).replace(queryParameters: {
              'userId': senderId.toString(),
              'isSender': 'true',
            });

            final existingKeyResponse = await http.get(fetchKeyUrl);
            print("Fetch Existing Key Response: ${existingKeyResponse.body}");

            if (existingKeyResponse.statusCode == 200) {
              final Map<String, dynamic> responseData = jsonDecode(existingKeyResponse.body)['encryptedKey'];
              final String encryptedKey = responseData['key'];
              final String keyId = responseData['id'];

              final ECPublicKey senderPublicKey = await retrievePublicKeyFromBackend(senderId);
              final ECPrivateKey senderPrivateKey = await retrievePrivateKey(sendername);

              final Uint8List aesKey = decryptionService.decryptAESKeyForSender(
                encryptedKey, senderPrivateKey, senderPublicKey,
              );

              print("Decrypted AES Key: ${base64Encode(aesKey)}");

              await secureStorage.write(key: "aesKey_${senderId}_$recipientId", value: base64Encode(aesKey));
              await secureStorage.write(key: "keyId_${senderId}_$recipientId", value: keyId);

              return {
                'aesKey': aesKey,
                'keyId': keyId,
              };
            } else {
              throw Exception("Failed to fetch existing encryption key.");
            }
          }
        }
      }
    } else {
      throw Exception("Failed to check key rotation.");
    }
  } catch (error) {
    print("Error in rotateKeyIfNeeded: $error");
    throw Exception("Unexpected error: $error");
  }
}


/* Future<ECPrivateKey> fetchSendertestPrivateKey() async {
  /* final String? privateKeyPem = await secureStorage.read(key: "privateKey"); */
  final String? privateKeyPem ="-----BEGIN PRIVATE KEY-----\nMIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQg5Wt4rIfs7XglgsxI\nFtwDrgzk69TFQ6O2Db9d+c3OG1ShRANCAATcbRPvGmRtPjMVZeaAPhxC26s35iCG\nTOPCzjLK/YNvZ41L1kmAIj0q0prCPO0RuGIm7i7fsmJyaFTFn+prr47G\n-----END PRIVATE KEY-----\n";
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
} */

/* Future<ECPrivateKey> fetchReceipentPrivateKey() async {
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
 
 */
 Future<ECPrivateKey> retrievePrivateKey(String username) async {
  final privateKeyBase64 = await secureStorage.read(key: 'privateKey_$username');

  if (privateKeyBase64 == null) {
    throw Exception("🔐 Private key for user '$username' not found in secure storage.");
  }

  try {
    final decoded = utf8.decode(base64Decode(privateKeyBase64));
    final d = BigInt.parse(decoded, radix: 16);
    final domainParams = ECDomainParameters('secp256r1');
    return ECPrivateKey(d, domainParams);
  } catch (e) {
    throw Exception("❌ Failed to decode private key: $e");
  }
}


 Future<ECPublicKey> retrievePublicKeyFromBackend(int username) async {
  final url = Uri.parse('https://lock-chat-backend.vercel.app/api/encryption/users/$username/publicKey');

  final response = await http.get(url);

  if (response.statusCode != 200) {
    throw Exception("❌ Failed to retrieve public key: ${response.statusCode} ${response.body}");
  }

  try {
    final data = jsonDecode(response.body);
    final publicKeyBase64 = data['publicKey'];

    final bytes = base64Decode(publicKeyBase64);
    final domainParams = ECDomainParameters('secp256r1');
    final curve = domainParams.curve;
    final q = curve.decodePoint(bytes);

    if (q == null) {
      throw Exception("❌ Failed to decode EC point from public key bytes.");
    }

    return ECPublicKey(q, domainParams);
  } catch (e) {
    throw Exception("❌ Error while decoding public key: $e");
  }
}



}
