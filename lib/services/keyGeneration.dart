import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/export.dart';
import 'dart:math';
import 'package:asn1lib/asn1lib.dart';
import 'package:basic_utils/basic_utils.dart';
import 'package:basic_utils/basic_utils.dart';


class KeyGenerationService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  
  /// Generate a new EC key pair (secp256r1)
static AsymmetricKeyPair<ECPublicKey, ECPrivateKey> _generateKeyPair() {
  final keyParams = ECKeyGeneratorParameters(ECCurve_secp256r1());
  final secureRandom = SecureRandom("Fortuna")
    ..seed(KeyParameter(_generateRandomBytes(32)));

  final generator = ECKeyGenerator()
    ..init(ParametersWithRandom(keyParams, secureRandom));

  final pair = generator.generateKeyPair();
  return AsymmetricKeyPair<ECPublicKey, ECPrivateKey>(
    pair.publicKey as ECPublicKey,
    pair.privateKey as ECPrivateKey,
  );
}

static Uint8List _generateRandomBytes(int length) {
  final random = Random.secure();
  final values = List<int>.generate(length, (_) => random.nextInt(256));
  return Uint8List.fromList(values);
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
    final privateKeybase64= _encodePrivateKeyToBase64(keyPair.privateKey);
     print("Private key of user is : $privateKeybase64");
     print("[DEBUG] d (privateKey): ${keyPair.privateKey.d}");
    // Store Private Key securely
    await _secureStorage.write(
      key: 'privateKey_$username',
      value: privateKeybase64,
    );

    // Send Public Key to Backend
    await _sendPublicKeyToBackend(username, publicKeyPem, email, password);
  }

  /// Send the public key to the backend
  static Future<void> _sendPublicKeyToBackend(String username, String publicKeyPem, String email , String password) async {
    final url = Uri.parse('http://10.80.0.85:5000/auth/register'); // Replace with your backend URL

    
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
