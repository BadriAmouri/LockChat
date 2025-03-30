import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:pointycastle/asymmetric/api.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DecryptionService {
  final _storage = const FlutterSecureStorage();

  /// Decrypts an AES key using recipient's private key
  Uint8List decryptAESKey(String encryptedKeyBase64, RSAPrivateKey privateKey) {
    final encryptedBytes = base64Decode(encryptedKeyBase64);
    final decrypter = encrypt.Encrypter(encrypt.RSA(privateKey: privateKey));
    final decryptedKey = decrypter.decryptBytes(encrypt.Encrypted(encryptedBytes));
    return Uint8List.fromList(decryptedKey);
  }

  /// Decrypts an AES-256-GCM encrypted message
  String decryptMessage(String encryptedMessage, Uint8List aesKey, String ivBase64) {
    final iv = encrypt.IV(base64Decode(ivBase64));
    final encrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key(aesKey), mode: encrypt.AESMode.gcm));

    final decrypted = encrypter.decrypt(encrypt.Encrypted.fromBase64(encryptedMessage), iv: iv);
    return decrypted;
  }
}
