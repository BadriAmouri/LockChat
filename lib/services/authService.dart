// api/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class AuthService {
  // Replace with your actual API base URL
  final String baseUrl = 'http://10.80.1.239:5000/auth';
  
  // Login method
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );
      
      final responseData = jsonDecode(response.body);
      print("✅✅✅✅✅LOG IN CALLED✅✅✅✅");
      print(responseData);
      
      if (response.statusCode == 200) {
        // Store tokens securely (you should use flutter_secure_storage in production)
        return {
          'success': true,
          'accessToken': responseData['accessToken'],
          'refreshToken': responseData['refreshToken'],
          'user_id': responseData['user_id'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection error: ${e.toString()}',
      };
    }
  }
  
  // Refresh token method
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/refreshToken'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'refreshToken': refreshToken,
        }),
      );
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'accessToken': responseData['accessToken'],
        };
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Failed to refresh token',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection error: ${e.toString()}',
      };
    }
  }
  
  // Logout method
  Future<Map<String, dynamic>> logout(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'refreshToken': refreshToken,
        }),
      );
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {'success': true, 'message': responseData['message']};
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Logout failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection error: ${e.toString()}',
      };
    }
  }
}