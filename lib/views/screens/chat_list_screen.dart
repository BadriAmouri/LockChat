import 'package:flutter/material.dart';
import 'package:lockchat/services/socket_service.dart';
import '../../models/chatroom.dart';
import '../../services/chat_service.dart';
import '../widgets/chat_item.dart';
import '../widgets/search_bar_widget.dart';
import '../theme/colors.dart';
import 'chat_screen_test.dart';
import 'chat_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../../services/jwt_handler.dart';
import 'home.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late Future<List<Chatroom>> _chatroomsFuture;
  List<Chatroom> allChats = [];     // ← Full list
  List<Chatroom> filteredChats = []; // ← Search result list

  @override
  void initState() {
    super.initState();
    _loadChatrooms();


    // Connect to the WebSocket with userId "1"
    WebSocketService().connect(userId: '1');

    
    
  }

  Future<void> _loadChatrooms() async {

  }

  Future<void> _loadChatrooms() async {
    _chatroomsFuture = ChatService.fetchChatrooms();
    final chats = await _chatroomsFuture;

    setState(() {
      allChats = chats;
      filteredChats = chats; // initially show all
    });
  }


  Future<void> _handleChatTap(String recepient_id) async {
    final isConnected = await WebSocketService().checkUserConnection(recepient_id); // 👈 your service method
    final message = isConnected
        ? 'The user is online. Starting chat...'
        : 'The user is offline. You can still send messages.';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isConnected ? 'Online' : 'Offline'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          )
        ],
      ),
    );

    // Navigate to ChatScreene regardless of status
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreene(
          
        ),
      ),
    );
  }
  @override
  void dispose() {
    WebSocketService().dispose();
    super.dispose();

  void _filterChats(String query) {
    final results = allChats.where((chat) {
      final nameLower = chat.name.toLowerCase();
      final queryLower = query.toLowerCase();
      return nameLower.contains(queryLower);
    }).toList();

    setState(() {
      filteredChats = results;
    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.darkpurple,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            /* child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                IconButton(
                  icon: Icon(Icons.home, color: Colors.white, size: 28),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                    );
                  },
                    ),
                const SizedBox(height: 30),
                const Text(
                  'CHATLOCK',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 15),
                // 🔥 Update: Make search bar functional
                SearchBarWidget(
                  onChanged: _filterChats, // <<<<<<<<<<<<<<<
                ),
              ],
            ), */
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.menu, color: Colors.white, size: 28),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const HomeScreen()),
                          );
                        },
                      ),
                      const Text(
                        'CHATLOCK',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      SizedBox(width: 48), // just to balance spacing on the right side
      ],
    ),
    const SizedBox(height: 15),
    SearchBarWidget(
      onChanged: _filterChats,
    ),
  ],
),

          ),
          const SizedBox(height: 2),
          Expanded(
            child: FutureBuilder<List<Chatroom>>(
              future: _chatroomsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No chats found.'));
                }

                return ListView.builder(
                  itemCount: filteredChats.length,
                  itemBuilder: (context, index) {
                    final chat = filteredChats[index];
                    return GestureDetector(

                      onTap: () => _handleChatTap('2'),

                      child: ChatItem(
                        name: chat.name,
                        lastMessage: chat.lastMessage,
                        time: chat.time,
                        imageUrl: chat.imageUrl,
                        unreadMessages: chat.unreadMessages,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
