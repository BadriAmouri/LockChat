import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  late io.Socket socket;
  // the sender ID is the user ID 
  void connect(String senderId) {
    socket = io.io('http://localhost:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.onConnect((_) {
      print('Connected to server');
      socket.emit("update_status", {"userId": senderId});
    });

    socket.onDisconnect((_) => print('Disconnected from server'));
  }
  // here i need to get the recipientId 
  void sendMessage(String senderId, String recipientId, String message) {
    final messageId = DateTime.now().millisecondsSinceEpoch.toString();
    socket.emit("send_message", {
      "senderId": senderId,
      "recipientId": recipientId,
      "message": message,
      "messageId": messageId,
    });
  }

  void onMessageReceived(Function(String senderId, String message) callback) {
    socket.on("receive_message", (data) {
      callback(data["senderId"], data["message"]);
    });
  }

  void onTyping(Function(String senderId) callback) {
    socket.on("typing", (data) => callback(data["senderId"]));
  }

  void onStopTyping(Function(String senderId) callback) {
    socket.on("stop_typing", (data) => callback(data["senderId"]));
  }

  void onMessageStatusUpdate(Function(String messageId, String status) callback) {
    socket.on("message_status_update", (data) {
      callback(data["messageId"], data["status"]);
    });
  }

  void sendTyping(String senderId, String recipientId) {
    socket.emit("typing", {"senderId": senderId, "recipientId": recipientId});
  }

  void stopTyping(String senderId, String recipientId) {
    socket.emit("stop_typing", {"senderId": senderId, "recipientId": recipientId});
  }

  void disconnect() {
    socket.disconnect();
  }
}
