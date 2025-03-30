import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'encryption_service.dart';
import 'decryption_service.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asn1.dart'; // Add this for ASN.1 parsing

class KeyManagementService {
  final decryptionService = DecryptionService();
  final EncryptionService encryptionService = EncryptionService();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  
Future<Uint8List> rotateKeyIfNeeded(int senderId, int recipientId) async {
  try {
    // ✅ Check if key rotation is needed
    final Uri checkRotationUrl = Uri.parse(
      'http://192.168.1.10:5000/api/encryption/shouldRotateKey/$senderId/$recipientId',
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
        final RSAPublicKey recipientPublicKey = await fetchRecipientPublicKey(recipientId);
        final RSAPublicKey senderPublicKey = await fetchSenderPublicKey(senderId);
        print("Fetched Public Keys for sender and recipient.");

        // 🔒 3. Encrypt AES key for both sender & recipient
        final String encryptedKeyForRecipient = encryptionService.encryptAESKeyForRecipient(aesKey, recipientPublicKey);
        final String encryptedKeyForSender = encryptionService.encryptAESKeyForRecipient(aesKey, senderPublicKey);
        print("Encrypted AES Key for both sender and recipient.");

        // 🔄 4. Store encrypted keys in backend
        final Uri storeKeyUrl = Uri.parse('http://192.168.1.10:5000/api/encryption/storeEncryptedKey');

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
          'http://192.168.1.10:5000/api/encryption/getEncryptedKey',
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
          final RSAPrivateKey senderPrivateKey = await fetchSenderPrivateKey();
          final Uint8List aesKey = decryptionService.decryptAESKey(encryptedKey, senderPrivateKey);

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




 Future<RSAPrivateKey> fetchSenderPrivateKey() async {
  /* final String? privateKeyPem = await secureStorage.read(key: "privateKey"); */
  final String? privateKeyPem =
      "-----BEGIN PRIVATE KEY-----\nMIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQg5Wt4rIfs7XglgsxI\nFtwDrgzk69TFQ6O2Db9d+c3OG1ShRANCAATcbRPvGmRtPjMVZeaAPhxC26s35iCG\nTOPCzjLK/YNvZ41L1kmAIj0q0prCPO0RuGIm7i7fsmJyaFTFn+prr47G\n-----END PRIVATE KEY-----\n";
  
  if (privateKeyPem == null) {
    throw Exception("Private key not found in secure storage.");
  }
  
  final privateKey = parseRSAPrivateKeyFromPem(privateKeyPem);
  print("[DEBUG] Fetched Private Key: $privateKey");
  return privateKey;
}

Future<RSAPublicKey> fetchSenderPublicKey(int senderId) async {
  final response = await http.get(
    Uri.parse('http://192.168.1.10:5000/api/encryption/users/$senderId/publicKey'),
  );

  if (response.statusCode == 200) {
    final String publicKeyPem = jsonDecode(response.body)['publicKey'];
    final publicKey = parseRSAPublicKeyFromPem(publicKeyPem);
    print("[DEBUG] Fetched Sender's Public Key: $publicKey");
    return publicKey;
  } else {
    throw Exception("Failed to fetch sender's public key");
  }
}

Future<RSAPublicKey> fetchRecipientPublicKey(int recipientId) async {
  final response = await http.get(
    Uri.parse('http://192.168.1.10:5000/api/encryption/users/$recipientId/publicKey'),
  );

  if (response.statusCode == 200) {
    final String publicKeyPem = jsonDecode(response.body)['publicKey'];
    final publicKey = parseRSAPublicKeyFromPem(publicKeyPem);
    print("[DEBUG] Fetched Recipient's Public Key: $publicKey");
    return publicKey;
  } else {
    throw Exception("Failed to fetch recipient's public key");
  }
}

 
/// Converts ASN1Integer to BigInt
BigInt _decodeBigInt(ASN1Integer asn1Integer) {
  final Uint8List bytes = asn1Integer.valueBytes ?? Uint8List(0); // Ensure it's never null

  if (bytes.isEmpty) {
    throw Exception("ASN1Integer has no value bytes");
  }

  return BigInt.parse(
    bytes.map((e) => e.toRadixString(16).padLeft(2, '0')).join(),
    radix: 16,
  );
}
 


  RSAPrivateKey parseRSAPrivateKeyFromPem(String pem) {
    try {
      // Remove PEM headers and footers
      final pemCleaned = pem
          .replaceAll("-----BEGIN PRIVATE KEY-----", "")
          .replaceAll("-----END PRIVATE KEY-----", "")
          .replaceAll("-----BEGIN RSA PRIVATE KEY-----", "")
          .replaceAll("-----END RSA PRIVATE KEY-----", "")
          .replaceAll("\n", "")
          .trim();

      // Decode base64 content
      final Uint8List keyBytes = base64Decode(pemCleaned);

      // Parse ASN.1 format
      final asn1Parser = ASN1Parser(keyBytes);
      final ASN1Sequence? topLevelSeq = asn1Parser.nextObject() as ASN1Sequence?;

      if (topLevelSeq == null || topLevelSeq.elements == null || topLevelSeq.elements!.isEmpty) {
        throw Exception("Invalid ASN.1 format for RSA private key");
      }

      // RSA private keys can be in two formats:
      // - PKCS#1 (traditional format)
      // - PKCS#8 (modern format, wrapped in an additional ASN.1 structure)

      // If it is PKCS#1 format, it starts directly with the modulus
      if (topLevelSeq.elements!.length >= 9) {
        return _parsePKCS1PrivateKey(topLevelSeq);
      }

      // If it is PKCS#8 format, the private key is wrapped inside
      final ASN1BitString? privateKeyBitString = topLevelSeq.elements!.last as ASN1BitString?;
      if (privateKeyBitString == null) {
        throw Exception("Invalid ASN.1 format: Missing private key bit string");
      }

      final ASN1Parser privateKeyParser = ASN1Parser(privateKeyBitString.valueBytes);
      final ASN1Sequence? privateKeySeq = privateKeyParser.nextObject() as ASN1Sequence?;

      if (privateKeySeq == null || privateKeySeq.elements == null || privateKeySeq.elements!.length < 9) {
        throw Exception("Invalid ASN.1 format: Missing RSA private key components");
      }

      return _parsePKCS1PrivateKey(privateKeySeq);
    } catch (e) {
      throw Exception("Failed to parse RSA private key: $e");
    }
  }

/// Parses an RSA private key from PKCS#1 format
RSAPrivateKey _parsePKCS1PrivateKey(ASN1Sequence privateKeySeq) {
  final BigInt modulus = _decodeBigInt(privateKeySeq.elements![1] as ASN1Integer);
  final BigInt publicExponent = _decodeBigInt(privateKeySeq.elements![2] as ASN1Integer);
  final BigInt privateExponent = _decodeBigInt(privateKeySeq.elements![3] as ASN1Integer);
  final BigInt p = _decodeBigInt(privateKeySeq.elements![4] as ASN1Integer);
  final BigInt q = _decodeBigInt(privateKeySeq.elements![5] as ASN1Integer);

  return RSAPrivateKey(modulus, privateExponent, p, q);
}

 

RSAPublicKey parseRSAPublicKeyFromPem(String pem) {
  try {
    // Remove PEM headers and footers
    final pemCleaned = pem
        .replaceAll("-----BEGIN PUBLIC KEY-----", "")
        .replaceAll("-----END PUBLIC KEY-----", "")
        .replaceAll("\n", "")
        .trim();

    // Decode the base64 content
    final Uint8List keyBytes = base64Decode(pemCleaned);

    // Parse ASN.1 format
    final asn1Parser = ASN1Parser(keyBytes);
    final ASN1Sequence? topLevelSeq = asn1Parser.nextObject() as ASN1Sequence?;

    if (topLevelSeq == null || topLevelSeq.elements == null || topLevelSeq.elements!.length < 2) {
      throw Exception("Invalid ASN.1 format");
    }

    final ASN1BitString? publicKeyBitString = topLevelSeq.elements![1] as ASN1BitString?;

    if (publicKeyBitString == null) {
      throw Exception("Invalid ASN.1 format: Missing public key bit string");
    }

    // Parse the public key sequence
    final ASN1Parser publicKeyParser = ASN1Parser(publicKeyBitString.valueBytes);
    final ASN1Sequence? publicKeySeq = publicKeyParser.nextObject() as ASN1Sequence?;

    if (publicKeySeq == null || publicKeySeq.elements == null || publicKeySeq.elements!.length < 2) {
      throw Exception("Invalid ASN.1 format: Missing modulus and exponent");
    }

    // Extract modulus (n) and exponent (e)
    final ASN1Integer? modulusASN1 = publicKeySeq.elements![0] as ASN1Integer?;
    final ASN1Integer? exponentASN1 = publicKeySeq.elements![1] as ASN1Integer?;

    if (modulusASN1 == null || exponentASN1 == null) {
      throw Exception("Invalid ASN.1 format: Missing RSA key components");
    }

    final BigInt modulus = _decodeBigInt(modulusASN1);
    final BigInt exponent = _decodeBigInt(exponentASN1);

    // Create RSAPublicKey object
    return RSAPublicKey(modulus, exponent);
  } catch (e) {
    throw Exception("Failed to parse RSA public key: $e");
  }
}






}
