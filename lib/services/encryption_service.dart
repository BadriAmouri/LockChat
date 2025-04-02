import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:pointycastle/export.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
class EncryptionService {
  final _storage = const FlutterSecureStorage();
  final int aesKeySize = 32; // 256-bit AES key
  final int ivSize = 16; // Recommended IV size

  /// Generates a random AES-256 key
  Uint8List generateAESKey() {
    final key = encrypt.Key.fromSecureRandom(aesKeySize);
    return key.bytes;
  }
    Uint8List bigIntToUint8List(BigInt number) {
    final byteData = number.toRadixString(16).padLeft(64, '0');
    return Uint8List.fromList(List<int>.generate(
      byteData.length ~/ 2,
      (i) => int.parse(byteData.substring(i * 2, i * 2 + 2), radix: 16),
    ));
  }

  /// Encrypts a message using AES-256-GCM
  Map<String, String> encryptMessage(String message, Uint8List aesKey) {
    final iv = encrypt.IV.fromSecureRandom(ivSize);
    final encrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key(aesKey), mode: encrypt.AESMode.gcm));

    final encrypted = encrypter.encrypt(message, iv: iv);
    
    return {
      'encryptedMessage': encrypted.base64,
      'iv': base64Encode(iv.bytes),
    };
  }

  Uint8List deriveSharedSecret(ECPrivateKey privateKey, ECPublicKey publicKey) {
  final ecAgreement = ECDHBasicAgreement();
  ecAgreement.init(privateKey);
  final sharedSecret = ecAgreement.calculateAgreement(publicKey);
  return bigIntToUint8List(sharedSecret);
}

// Function to derive AES encryption key from the shared secret
Uint8List deriveAESKey(Uint8List sharedSecret) {
  final sha256 = SHA256Digest();
  return sha256.process(sharedSecret).sublist(0, 32); // Take first 32 bytes for AES-256
}

// Function to encrypt AES key with derived AES encryption key
String encryptAESKey(Uint8List aesKey, Uint8List derivedAESKey) {
  final encrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key(derivedAESKey), mode: encrypt.AESMode.ecb));
  final encryptedAESKey = encrypter.encryptBytes(aesKey);
  return encryptedAESKey.base64;
}
// Main function to encrypt AES key for sender and recipient
Map<String, String> encryptAESKeyForSenderAndRecipient(
    Uint8List aesKey, ECPrivateKey senderPrivateKey, ECPublicKey senderPublicKey, ECPublicKey recipientPublicKey) {
  
  // Sender encrypts the AES key for themselves
  Uint8List sharedSecretSender = deriveSharedSecret(senderPrivateKey, senderPublicKey);
  Uint8List derivedAESKeySender = deriveAESKey(sharedSecretSender);
  String encryptedKeyForSender = encryptAESKey(aesKey, derivedAESKeySender);

  // Sender encrypts the AES key for the recipient
  Uint8List sharedSecretRecipient = deriveSharedSecret(senderPrivateKey, recipientPublicKey);
  Uint8List derivedAESKeyRecipient = deriveAESKey(sharedSecretRecipient);
  String encryptedKeyForRecipient = encryptAESKey(aesKey, derivedAESKeyRecipient);

  return {
    'encrypted_key_for_sender': encryptedKeyForSender,
    'encrypted_key_for_recipient': encryptedKeyForRecipient,
  };
}

  /// Encrypts the AES key using recipient's RSA public key
/*     String encryptAESKeyForRecipient(Uint8List aesKey, ECPublicKey publicKey) {
    try {
      final cipher = ECIESCipher();
      cipher.init(true, PublicKeyParameter<ECPublicKey>(publicKey));

      Uint8List encryptedAESKey = cipher.process(aesKey);

      return base64Encode(encryptedAESKey);
    } catch (e) {
      throw Exception("EC encryption failed: $e");
    }
  } */
}
