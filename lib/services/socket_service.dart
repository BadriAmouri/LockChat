import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();

  factory WebSocketService() => _instance;

  WebSocketService._internal();

  IO.Socket? socket;

  void connect({required String userId}) {
    socket = IO.io(
      'https://lockchat-backend.onrender.com',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect() // Manual connect
          .setQuery({'userId': userId}) // Send userId in query
          .setExtraHeaders({
            'Access-Control-Allow-Origin': '*',
          }) // Optional for CORS in dev
          .build(),
    );

    socket!.connect();

    socket!.onConnect((_) {
      debugPrint('🟢 Connected to WebSocket server as $userId');
    });

    socket!.on('connected_message', (data) {
      debugPrint('✅ Server says: ${data['message']}');
    });

    socket!.on('receive_message', (data) {
      debugPrint('📨 Received message: ${data['message']} from ${data['senderId']}');
    });

    socket!.on('typing', (data) {
      debugPrint('✍️ ${data['senderId']} is typing...');
    });

    socket!.on('stop_typing', (data) {
      debugPrint('🙅 ${data['senderId']} stopped typing.');
    });

    socket!.onDisconnect((_) {
      debugPrint('🔴 Disconnected from server');
    });
  }

  void sendMessage({
    required String senderId,
    required String recipientId,
    required String message,
  }) {
    if (socket != null && socket!.connected) {
      socket!.emit('send_message', {
        'senderId': senderId,
        'recipientId': recipientId,
        'message': message,
      });
      debugPrint('📤 Sent message to $recipientId: $message');
    } else {
      debugPrint('⚠️ Socket not connected. Cannot send message.');
    }
  }

  void emitTyping({required String senderId, required String recipientId}) {
    socket?.emit('typing', {
      'senderId': senderId,
      'recipientId': recipientId,
    });
  }

  void emitStopTyping({required String senderId, required String recipientId}) {
    socket?.emit('stop_typing', {
      'senderId': senderId,
      'recipientId': recipientId,
    });
  }

  void disconnect() {
    socket?.disconnect();
  }

  void dispose() {
    socket?.dispose();
    socket = null;
  }


Future<bool> checkUserConnection(String userId) async {
  final url = Uri.parse('https://lockchat-backend.onrender.com/api/websocket/check-user-connection');

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("User connection status: ${data['isConnected']}");
      return data['isConnected'] == true;
    } else {
      print('Server error: ${response.statusCode}');
      return false;
    }
  } catch (e) {
    print('Error checking user connection: $e');
    return false;
  }
}


}
