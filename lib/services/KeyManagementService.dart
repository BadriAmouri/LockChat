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
      'http://10.80.0.85:5000/api/encryption/shouldRotateKey/$senderId/$recipientId',
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
        final ECPublicKey recipientPublicKey = await fetchRecipientPublicKey(recipientId);
        final ECPublicKey senderPublicKey = await fetchRecipientPublicKey(senderId);
        final ECPrivateKey senderPrivateKey = await fetchSenderPrivateKey(sendername);

        // 🔒 3. Encrypt AES key
        final Map<String, String> encryptedKeyForboth = encryptionService.encryptAESKeyForSenderAndRecipient(
          aesKey, senderPrivateKey, senderPublicKey, recipientPublicKey,
        );

        final String? encryptedKeyForRecipient = encryptedKeyForboth['encrypted_key_for_recipient'];
        final String? encryptedKeyForSender = encryptedKeyForboth['encrypted_key_for_sender'];

        // 🔄 4. Store encrypted keys
        final Uri storeKeyUrl = Uri.parse('http://10.80.0.85:5000/api/encryption/storeEncryptedKey');
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

        final Map<String, dynamic> responseBody = jsonDecode(storeKeyResponse.body);
        final String keyId = responseBody['insertedKeyId'];

        // 🔐 Save AES key locally
        await secureStorage.write(key: "aesKey_$recipientId", value: base64Encode(aesKey));

        return {
          'aesKey': aesKey,
          'keyId': keyId,
        };
      } else {
        // ✅ Fetch existing encryption key
        final Uri fetchKeyUrl = Uri.parse(
          'http://10.80.0.85:5000/api/encryption/getEncryptedKey',
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

          final ECPublicKey senderPublicKey = await fetchRecipientPublicKey(senderId);
          final ECPrivateKey senderPrivateKey = await fetchSenderPrivateKey(sendername);

          final Uint8List aesKey = decryptionService.decryptAESKeyForSender(
            encryptedKey, senderPrivateKey, senderPublicKey,
          );

          print("Decrypted AES Key: ${base64Encode(aesKey)}");

          await secureStorage.write(key: "aesKey_$recipientId", value: base64Encode(aesKey));

          return {
            'aesKey': aesKey,
            'keyId': keyId,
          };
        } else {
          throw Exception("Failed to fetch existing encryption key.");
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

Future<ECPrivateKey> fetchSendertestPrivateKey() async {
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
}

Future<ECPrivateKey> fetchReceipentPrivateKey() async {
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
 

  Future<ECPrivateKey> fetchSenderPrivateKey(String username) async {
    final String? base64PrivateKey =
        await secureStorage.read(key: 'privateKey_$username');

    if (base64PrivateKey == null) {
      throw Exception("Private key not found in secure storage.");
    }

    try {
      // Step 1: Base64 decode the private key
      final decodedBytes = base64Decode(base64PrivateKey);

      // Step 2: Since the private key is raw bytes, directly create a BigInt from it
      final d = BigInt.parse(decodedBytes.toList().map((e) => e.toRadixString(16)).join(), radix: 16);

      // Step 3: Define curve params (secp256r1 or whichever curve you're using)
      final domainParams = ECCurve_secp256r1();

      // Step 4: Create the ECPrivateKey using the decoded BigInt and domain parameters
      final ecPrivateKey = ECPrivateKey(d, domainParams);

      print("[✅] Successfully reconstructed EC Private Key for $username");
      print("[DEBUG] d (fetched privateKey): ${ecPrivateKey.d}");
      return ecPrivateKey;
    } catch (e) {
      throw Exception("❌ Failed to parse EC private key: $e");
    }
  }

Future<ECPublicKey> fetchRecipientPublicKey(int recipientId) async {
  final response = await http.get(
    Uri.parse('http://10.80.0.85:5000/api/encryption/users/$recipientId/publicKey'),
  );

  if (response.statusCode == 200) {
    final String base64PublicKey = jsonDecode(response.body)['publicKey'];

    // Debugging: Print the fetched base64 public key
    print("Fetched Public Key (Base64):\n$base64PublicKey");

    try {
      // Decode the base64-encoded public key into bytes
      final pubKeyBytes = base64Decode(base64PublicKey);

      // Use the appropriate curve (secp256r1/prime256v1) for decoding the public key
      final domainParams = ECCurve_secp256r1(); // Corresponds to prime256v1
      final q = domainParams.curve.decodePoint(pubKeyBytes);

      // Return the EC public key
      final ecPublicKey = ECPublicKey(q, domainParams);
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
