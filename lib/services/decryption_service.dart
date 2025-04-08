import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:pointycastle/export.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DecryptionService {
  final _storage = const FlutterSecureStorage();

  Uint8List bigIntToUint8List(BigInt number) {
    print("bigIntToUint8List - Converting BigInt: \$number");
    final byteData = number.toRadixString(16).padLeft(64, '0');
    return Uint8List.fromList(List<int>.generate(
      byteData.length ~/ 2,
      (i) => int.parse(byteData.substring(i * 2, i * 2 + 2), radix: 16),
    ));
  }

  Uint8List deriveSharedSecret(ECPrivateKey privateKey, ECPublicKey publicKey) {
    print("deriveSharedSecret - Private Key: \$privateKey, Public Key: \$publicKey");
    final ecAgreement = ECDHBasicAgreement();
    ecAgreement.init(privateKey);
    final sharedSecret = ecAgreement.calculateAgreement(publicKey);
    print("Shared Secret: \$sharedSecret");
    return bigIntToUint8List(sharedSecret);
  }

  Uint8List deriveAESKey(Uint8List sharedSecret) {
    print("deriveAESKey - Shared Secret: \$sharedSecret");
    final sha256 = SHA256Digest();
    final aesKey = sha256.process(sharedSecret).sublist(0, 32);
    print("Derived AES Key: \$aesKey");
    return aesKey;
  }

  Uint8List decryptAESKeyForRecipient(String encryptedKeyBase64, ECPrivateKey recipientPrivateKey, ECPublicKey senderPublicKey) {
    print("decryptAESKeyForRecipient - Encrypted Key: $encryptedKeyBase64");
    final encryptedBytes = base64Decode(encryptedKeyBase64);
    print("Decoded Encrypted Key: $encryptedBytes");
    
    Uint8List sharedSecret = deriveSharedSecret(recipientPrivateKey, senderPublicKey);
    print("🤝Decryption Shared Secret (Recipient): $sharedSecret");
    Uint8List derivedAESKey = deriveAESKey(sharedSecret);
    
    print("Decryption Derived AES Key for Recipient: $derivedAESKey");
    
    final encrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key(derivedAESKey), mode: encrypt.AESMode.ecb));
    print("encrypter defined successfully");
    final decryptedAESKey = encrypter.decryptBytes(encrypt.Encrypted(encryptedBytes));
    
    print("Decrypted AES Key: $decryptedAESKey");
    return Uint8List.fromList(decryptedAESKey);
  }

  Uint8List decryptAESKeyForSender(String encryptedKeyBase64, ECPrivateKey senderPrivateKey, ECPublicKey senderPublicKey) {
    print("decryptAESKeyForSender - Encrypted Key: $encryptedKeyBase64");
    final encryptedBytes = base64Decode(encryptedKeyBase64);
    print("Decoded Encrypted Key: $encryptedBytes");
    
    Uint8List sharedSecret = deriveSharedSecret(senderPrivateKey, senderPublicKey);
    print("🤝Decryption Shared Secret (Sender): $sharedSecret");
    Uint8List derivedAESKey = deriveAESKey(sharedSecret);
    
    print("Decryption Derived AES Key for Sender: $derivedAESKey");
    
    final encrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key(derivedAESKey), mode: encrypt.AESMode.ecb));
    final decryptedAESKey = encrypter.decryptBytes(encrypt.Encrypted(encryptedBytes));
    print("Decrypted AES Key: $decryptedAESKey");
    return Uint8List.fromList(decryptedAESKey);
  }

  String decryptMessage(String encryptedMessage, Uint8List aesKey, String ivBase64) {
    print("decryptMessage - Encrypted Message: \$encryptedMessage, IV: \$ivBase64");
    print("AES Key: \$aesKey");
    final iv = encrypt.IV(base64Decode(ivBase64));
    final encrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key(aesKey), mode: encrypt.AESMode.gcm));
    final decryptedMessage = encrypter.decrypt(encrypt.Encrypted.fromBase64(encryptedMessage), iv: iv);
    print("Decrypted Message: \$decryptedMessage");
    return decryptedMessage;
  }
}