import 'package:flutter/material.dart';
import 'package:lockchat/services/socket_service.dart';

class TestWebSocketPage extends StatefulWidget {
  const TestWebSocketPage({Key? key}) : super(key: key);

  @override
  State<TestWebSocketPage> createState() => _TestWebSocketPageState();
}

class _TestWebSocketPageState extends State<TestWebSocketPage> {
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final List<String> _messages = [];

  @override
  void initState() {
    super.initState();

    // Connect to the WebSocket with userId "1"
    WebSocketService().connect(userId: '1');

    // Listen for incoming messages
    WebSocketService().socket?.on('receive_message', (data) {
      final newMessage =
          "From ${data['senderId']}: ${data['message']}";
      setState(() {
        _messages.add(newMessage);
      });
    });
  }

  @override
  void dispose() {
    WebSocketService().dispose();
    super.dispose();
  }

  void _sendMessage() {
    final recipientId = _recipientController.text.trim();
    final message = _messageController.text.trim();

    if (recipientId.isNotEmpty && message.isNotEmpty) {
      WebSocketService().sendMessage(
        senderId: '1', // Use "1" to match the connected user ID
        recipientId: recipientId,
        message: message,
      );

      setState(() {
        _messages.add("Me to $recipientId: $message");
      });

      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WebSocket Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _recipientController,
              decoration: const InputDecoration(
                labelText: 'Recipient ID',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendMessage,
              child: const Text('Send Message'),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const Text('Messages:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (_, index) => Text(_messages[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
