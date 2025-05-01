// services/jwt_handler.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'tokenStorage.dart';

class JwtHandler {
  final TokenStorage _tokenStorage = TokenStorage();
  final String baseUrl = 'https://lock-chat-backend.vercel.app/auth'; 
  
  // Check if token is expired or about to expire (within 5 minutes)
  bool _isTokenExpiringSoon(String token) {
    final decodedToken = JwtDecoder.decode(token);
    final expirationDate = DateTime.fromMillisecondsSinceEpoch(decodedToken['exp'] * 1000);
    final currentDate = DateTime.now();
    
    // Consider token as expiring if less than 3 minutes left
    return expirationDate.difference(currentDate).inMinutes < 3;
  }
  
  // Get valid access token (auto-refresh if needed)
  Future<String?> getValidAccessToken() async {
    String? accessToken = await _tokenStorage.getAccessToken();
    
    if (accessToken == null) {
      return null; // No token, user needs to login
    }
    
    // Check if token is expired or about to expire
    if (_isTokenExpiringSoon(accessToken)) {
      // Try to refresh the token
      String? refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) {
        return null; // No refresh token, user needs to login
      }
      
      // Call refresh token API
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/refreshToken'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refreshToken': refreshToken}),
        );
        
        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          accessToken = responseData['accessToken'];
          
          // Save the new access token
          await _tokenStorage.saveTokens(accessToken!, refreshToken);
        } else {
          // Failed to refresh, user needs to login again
          await _tokenStorage.clearTokens();
          return null;
        }
      } catch (e) {
        print('Error refreshing token: $e');
        return null;
      }
    }
    
    return accessToken;
  }
  
  // Create authenticated HTTP client
  Future<http.Client> getAuthenticatedClient() async {
    final client = http.Client();
    final accessToken = await getValidAccessToken();
      print('fetched token is :');
      print(accessToken);
    if (accessToken == null) {
      throw Exception('Not authenticated');
    }
    
    return client;
  }
  
  // Authenticated GET request
  Future<http.Response> authenticatedGet(String endpoint) async {
    final accessToken = await getValidAccessToken();
    print("✅✅✅ accessToken got successfully ! ✅✅✅");
     print(accessToken);
    if (accessToken == null) {
      throw Exception('Not authenticated');
    }
    print("call to  $endpoint");
    return http.get(
      Uri.parse('https://lock-chat-backend.vercel.app/$endpoint'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );
    
  }
  
  // Authenticated POST request
  Future<http.Response> authenticatedPost(String endpoint, Map<String, dynamic> body) async {
    final accessToken = await getValidAccessToken();
    
    if (accessToken == null) {
      throw Exception('Not authenticated');
    }
    
    return http.post(
      Uri.parse('https://lock-chat-backend.vercel.app/$endpoint'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
  }
}