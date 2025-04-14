import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class KeyGenerationService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  /// Register user and retrieve private key from backend
  static Future<void> registerUserAndStorePrivateKey(
      String username, String email, String password) async {
    final url = Uri.parse('http://10.80.0.85:5000/auth/register');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final privateKey = data['private_key'];
      final userFromServer = data['username']; // just in case you want to use it

      if (privateKey != null) {
        print("✅ Received private key from backend: $privateKey");

        // Save private key securely
        await _secureStorage.write(
          key: 'privateKey_$username',
          value: privateKey,
        );
        print("🔐 Private key securely stored for $username.");
        print("Response: ${response.body}");
      } else {
        print("⚠️ No private key received in response.");
        print("Response: ${response.body}");
      }
    } else {
      print("❌ Failed to register user: ${response.statusCode}");
      print("Response: ${response.body}");
    }
  }
}
