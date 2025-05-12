import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:lockchat/services/encrypted_message_sender.dart';
import 'package:lockchat/services/jwt_handler.dart';
import 'package:lockchat/services/socket_service.dart';
import 'package:lockchat/views/theme/colors.dart';

class ChatScreene extends StatefulWidget {
  final String currentUserId;
  final String recipientId; // This is the chatroom ID in your case
  final String chatroomId;
  final String senderName;
  final String recipientName;

  ChatScreene({required this.currentUserId, required this.recipientId , required this.chatroomId,required this.senderName, required this.recipientName});

  @override
  _ChatScreeneState createState() => _ChatScreeneState();
}

class _ChatScreeneState extends State<ChatScreene> {
  List<Map<String, dynamic>> messages = [];

  TextEditingController _messageController = TextEditingController();
  final jwthandler = JwtHandler();

  @override
  void initState() {
    super.initState();
    fetchMessages();

    // Listen to incoming WebSocket messages
    WebSocketService().socket?.on('receive_message', (data) {
      if (data['senderId'].toString() == widget.recipientId) {
        setState(() {
          messages.add({"isMe": false, "message": data['message']});
        });
      }
    });
  }

final secureStorage = FlutterSecureStorage();

Future<void> printAllSecureStorageItems() async {
  Map<String, String> allValues = await secureStorage.readAll();
  
  if (allValues.isEmpty) {
    print("🔒 SecureStorage is empty.");
  } else {
    print("🔐 SecureStorage contents:");
    allValues.forEach((key, value) {
      print('$key: $value');
    });
  }
}
Future<void> fetchMessages() async {
  try {
    final response = await jwthandler.authenticatedGet('api/chatrooms/${widget.chatroomId}/messages');
    print('📥 Response: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> fetched = jsonDecode(response.body);

      // Wait for all decryptions to complete
      final List<Map<String, dynamic>> decryptedMessages = await Future.wait(
        fetched.map((msg) async {
          print('🔑 Message Key: ${msg['encryption_key_id']}');
          print('🔑 Message sent is : ${msg['encrypted_message']}');
          print('🔑 Iv sent is : ${msg['iv']}');
          final decryptedMessage = await decryptReceivedMessageWithStoredaesKey(
            widget.senderName,
            int.parse(widget.recipientId),
            msg['sender_id'],
            msg['encrypted_message'],
            msg['iv'],
            msg['encryption_key_id'],
          );

          return {
            "isMe": msg['sender_id'].toString() == widget.currentUserId,
            "message": decryptedMessage,
          };
        }),
      );

      setState(() {
        messages = decryptedMessages;
      });
    } else {
      print('❌ Failed to fetch messages. Status: ${response.statusCode}');
      print('Response: ${response.body}');
    }
  } catch (e) {
    print('❌ Error fetching messages: $e');
  }
}


  void sendMessage() {
    String text = _messageController.text.trim();
    if (text.isNotEmpty) {
      // Send via WebSocket
      WebSocketService().sendMessage(
        senderId: widget.currentUserId,
        recipientId: widget.recipientId,
        message: text,
      );

      // Show message immediately in the UI
      setState(() {
        messages.add({"isMe": true, "message": text});
      });
      //  can also send the message to your backend here
      print('the message is : $text');
      print(' the sender name is : ${widget.senderName}');
      print('the chatroom id is : ${int.parse(widget.chatroomId)}');
      print(' the recipient id is : ${int.parse(widget.recipientId)}');

      sendEncryptedMessage_local(int.parse(widget.recipientId), widget.senderName, text,int.parse(widget.chatroomId));

      _messageController.clear();
    }
  }

  @override
  void dispose() {
    WebSocketService().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.darkpurple,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chat', style: TextStyle(fontSize: 18)),
            Text('Chatroom ID: ${widget.recipientId}',
                style: TextStyle(fontSize: 12)),
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
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
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
