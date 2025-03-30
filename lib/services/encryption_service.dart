import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:pointycastle/asymmetric/api.dart';
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

  /// Encrypts the AES key using recipient's RSA public key
  String encryptAESKeyForRecipient(Uint8List aesKey, RSAPublicKey publicKey) {
    final encrypter = encrypt.Encrypter(encrypt.RSA(publicKey: publicKey));
    final encryptedKey = encrypter.encryptBytes(aesKey);
    return encryptedKey.base64;
  }
}
