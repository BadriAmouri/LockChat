import 'package:flutter/material.dart';
import 'package:lockchat/services/socket_service.dart';
import 'package:lockchat/views/theme/colors.dart';

class ChatScreene extends StatefulWidget {
  @override
  _ChatScreeneState createState() => _ChatScreeneState();
}

class _ChatScreeneState extends State<ChatScreene> {
  List<Map<String, dynamic>> messages = [
    {"isMe": false, "message": "Lorem Ipsum Dolor Sit Amet, Consectetur Adipiscing Elit"},
    {"isMe": true, "message": "Sed Do Eiusmod Tempor Incididunt Ut Labore Et"},
    {"isMe": false, "message": "Lorem Ipsum Dolor Sit"},
    {"isMe": true, "message": "Ut Enim Ad Minim Veniam"},
    {"isMe": false, "message": "Ok"},
  ];

  TextEditingController _messageController = TextEditingController();
  final String currentUserId = '1'; // your user ID
  final String recipientId = '2';   // recipient user ID

  @override
  void initState() {
    super.initState();

    // Listen to incoming WebSocket messages
    WebSocketService().socket?.on('receive_message', (data) {
      if (data['senderId'].toString() == recipientId) {
        setState(() {
          messages.add({"isMe": false, "message": data['message']});
        });
      }
    });
  }

  @override
  void dispose() {
    WebSocketService().dispose();
    super.dispose();
  }

  void sendMessage() {
    String text = _messageController.text.trim();
    if (text.isNotEmpty) {
      // Send via WebSocket
      WebSocketService().sendMessage(
        senderId: currentUserId,
        recipientId: recipientId,
        message: text,
      );

      // Show message immediately in the UI
      setState(() {
        messages.add({"isMe": true, "message": text});
      });

      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.darkpurple,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Michael Tony', style: TextStyle(fontSize: 18)),
            Text('+43 123-456-7890', style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(icon: Icon(Icons.notifications), onPressed: () {}),
          IconButton(icon: Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(10),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return ChatBubble(
                  isMe: messages[index]["isMe"],
                  message: messages[index]["message"],
                );
              },
            ),
          ),
          ChatInputField(
            controller: _messageController,
            onSend: sendMessage,
          ),
        ],
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final bool isMe;
  final String message;

  const ChatBubble({required this.isMe, required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5),
        padding: EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? Colors.purple : Colors.purple.shade300,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: isMe ? Radius.circular(20) : Radius.circular(0),
            bottomRight: isMe ? Radius.circular(0) : Radius.circular(20),
          ),
        ),
        child: Text(
          message,
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}

class ChatInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const ChatInputField({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 2)],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Type message here...',
                border: InputBorder.none,
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: Colors.purple),
            onPressed: onSend,
          ),
        ],
      ),
    );
  }
}
