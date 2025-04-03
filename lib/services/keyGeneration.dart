import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/export.dart';

class KeyGenerationService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  
  /// Generate a new EC key pair (secp256r1)
  static AsymmetricKeyPair<ECPublicKey, ECPrivateKey> _generateKeyPair() {
    final keyParams = ECKeyGeneratorParameters(ECCurve_secp256r1());
    final random = SecureRandom("Fortuna")..seed(KeyParameter(Uint8List(32)));

    final generator = ECKeyGenerator()
      ..init(ParametersWithRandom(keyParams, random));

    final pair = generator.generateKeyPair();
    return AsymmetricKeyPair<ECPublicKey, ECPrivateKey>(
      pair.publicKey as ECPublicKey,
      pair.privateKey as ECPrivateKey,
    );
  }

  /// Convert EC public key to PEM format
  static String _encodePublicKeyToPem(ECPublicKey publicKey) {
    final q = publicKey.Q!;
    final bytes = q.getEncoded(false); // Uncompressed format
    return base64Encode(bytes);
  }

  /// Convert EC private key to bytes
  static String _encodePrivateKeyToBase64(ECPrivateKey privateKey) {
    final bytes = privateKey.d!.toRadixString(16);
    return base64Encode(utf8.encode(bytes));
  }

  /// Generate, store private key securely, and send public key to backend
  static Future<void> generateAndStoreKeyPair(String username, String email , String password) async {
    final keyPair = _generateKeyPair();
    final publicKeyPem = _encodePublicKeyToPem(keyPair.publicKey);
    final privateKeyBase64 = _encodePrivateKeyToBase64(keyPair.privateKey);

    // Store Private Key securely
    await _secureStorage.write(
      key: 'privateKey_$username',
      value: privateKeyBase64,
    );

    // Send Public Key to Backend
    await _sendPublicKeyToBackend(username, publicKeyPem, email, password);
  }

  /// Send the public key to the backend
  static Future<void> _sendPublicKeyToBackend(String username, String publicKeyPem, String email , String password) async {
    final url = Uri.parse('http://192.168.1.22:5000/auth/register'); // Replace with your backend URL

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'publicKey': publicKeyPem, 'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      print("✅ Public Key stored successfully for $username!");
    } else {
      print("❌ Failed to store Public Key: ${response.body}");
    }
  }
}
