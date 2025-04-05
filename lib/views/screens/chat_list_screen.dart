import 'package:flutter/material.dart';
import 'package:lockchat/views/screens/chat_screen.dart';
import '../widgets/chat_item.dart';
import '../widgets/search_bar_widget.dart';
import '../theme/colors.dart';
import 'chat_screen_test.dart';
class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> chats = [
      {
        'name': 'Metal Exchange',
        'lastMessage': 'Lorem ipsum dolor sit amet Lorem ipsum dolor sit amet Lorem ipsum dolor sit amet Lorem ipsum dolor sit amet Lorem ipsum dolor sit amet',
        'time': '10 min',
        'imageUrl': 'https://via.placeholder.com/50',
        'unreadMessages': 7,
      },
      {
        'name': 'Michael Tony',
        'lastMessage': 'Lorem ipsum dolor sit amet',
        'time': '10 min',
        'imageUrl': 'https://via.placeholder.com/50',
        'unreadMessages': 2,
      },
            {
        'name': 'Michael Tony',
        'lastMessage': 'Lorem ipsum dolor sit amet',
        'time': '10 min',
        'imageUrl': 'https://via.placeholder.com/50',
        'unreadMessages': 2,
      },
            {
        'name': 'Michael Tony',
        'lastMessage': 'Lorem ipsum dolor sit amet',
        'time': '10 min',
        'imageUrl': 'https://via.placeholder.com/50',
        'unreadMessages': 0,
      },
            {
        'name': 'Michael Tony',
        'lastMessage': 'Lorem ipsum dolor sit amet',
        'time': '10 min',
        'imageUrl': 'https://via.placeholder.com/50',
        'unreadMessages': 2,
      },
            {
        'name': 'Michael Tony',
        'lastMessage': 'Lorem ipsum dolor sit amet',
        'time': '10 min',
        'imageUrl': 'https://via.placeholder.com/50',
        'unreadMessages': 2,
      },
            {
        'name': 'Michael Tony',
        'lastMessage': 'Lorem ipsum dolor sit amet',
        'time': '10 min',
        'imageUrl': 'https://via.placeholder.com/50',
        'unreadMessages': 1,
      },
            {
        'name': 'Michael Tony',
        'lastMessage': 'Lorem ipsum dolor sit amet',
        'time': '10 min',
        'imageUrl': 'https://via.placeholder.com/50',
        'unreadMessages': 2,
      },
            {
        'name': 'Michael Tony',
        'lastMessage': 'Lorem ipsum dolor sit amet',
        'time': '10 min',
        'imageUrl': 'https://via.placeholder.com/50',
        'unreadMessages': 2,
      },
            {
        'name': 'Michael Tony',
        'lastMessage': 'Lorem ipsum dolor sit amet',
        'time': '10 min',
        'imageUrl': 'https://via.placeholder.com/50',
        'unreadMessages': 2,
      },
            {
        'name': 'Michael Tony',
        'lastMessage': 'Lorem ipsum dolor sit amet',
        'time': '10 min',
        'imageUrl': 'https://via.placeholder.com/50',
        'unreadMessages': 2,
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Purple Header with Title and Search Bar
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
              children: [
                const SizedBox(height: 30), // Space from top
                const Text(
                  'CHATLOCK',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 15), // Space between title and search bar
                const SearchBarWidget(),
              ],
            ),
          ),
          const SizedBox(height: 2), // Space before chat list
          Expanded(
            child: ListView.builder(
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
                    name: chat['name'],
                    lastMessage: chat['lastMessage'],
                    time: chat['time'],
                    imageUrl: chat['imageUrl'],
                    unreadMessages: chat['unreadMessages'],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
