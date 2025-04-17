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
  static Future<Map<String, dynamic>> generateAndStoreKeyPair(
    String username, String email, String password) async {
  try {
    final keyPair = _generateKeyPair();
    final publicKeyPem = _encodePublicKeyToPem(keyPair.publicKey);
    final privateKeybase64 = _encodePrivateKeyToBase64(keyPair.privateKey);

    // Store private key securely
    await _secureStorage.write(
      key: 'privateKey_$username',
      value: privateKeybase64,
    );

    // Send public key to backend and get response
    final response = await _sendPublicKeyToBackend(
      username,
      publicKeyPem,
      email,
      password,
    );

    return response; // Contains success/failure and possibly error message
  } catch (e) {
    return {'success': false, 'error': 'Unexpected error: $e'};
  }
}

  /// Send the public key to the backend
  static Future<Map<String, dynamic>> _sendPublicKeyToBackend(
    String username,
    String publicKeyPem,
    String email,
    String password) async {
  final url = Uri.parse('http://10.80.1.239:5000/auth/register');

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'username': username,
      'publicKey': publicKeyPem,
      'email': email,
      'password': password,
    }),
  );

  if (response.statusCode == 200) {
    final body = jsonDecode(response.body);
    if (body['success'] == true) {
      return {'success': true};
    } else {
      return {'success': false, 'error': body['error'] ?? 'Unknown error'};
    }
  } else {
    return {'success': false, 'error': 'HTTP ${response.statusCode}: ${response.body}'};
  }
}
}