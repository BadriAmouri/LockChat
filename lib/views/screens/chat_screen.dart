import 'package:flutter/material.dart';
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

  void sendMessage() {
    String text = _messageController.text.trim();
    if (text.isNotEmpty) {
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

  ChatBubble({required this.isMe, required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5),
        padding: EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: 250),
        decoration: BoxDecoration(
          color: isMe ? Colors.purple : Colors.purple.shade300,
          borderRadius: BorderRadius.circular(20),
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

  ChatInputField({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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