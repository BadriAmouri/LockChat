import 'package:flutter/material.dart';
import '../../models/chatroom.dart';
import '../../services/chat_service.dart';
import '../widgets/chat_item.dart';
import '../widgets/search_bar_widget.dart';
import '../theme/colors.dart';
import 'chat_screen_test.dart';
import 'chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/jwt_handler.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late Future<List<Chatroom>> _chatroomsFuture;

  @override
void initState() {
  super.initState();
  _loadChatrooms();
}

Future<void> _loadChatrooms() async {

    setState(() {
      _chatroomsFuture = ChatService.fetchChatrooms();
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: const [
                SizedBox(height: 30),
                Text(
                  'CHATLOCK',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                SizedBox(height: 15),
                SearchBarWidget(),
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

                final chats = snapshot.data!;
                return ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                        MaterialPageRoute(
                        //maybe with the backendlogic we pass the id of the chat or smth 
                        builder: (context) => ChatScreene(
/*                           name: chat['name'],
                          imageUrl: chat['imageUrl'], */
                              ),
                          ),
                        );
                      },
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
