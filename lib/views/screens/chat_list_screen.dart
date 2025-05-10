import 'package:flutter/material.dart';
import 'package:lockchat/services/socket_service.dart';
import 'package:lockchat/services/tokenStorage.dart';
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
  late String recepient_id;

  late Future<List<Map<String, dynamic>>> _chatroomsFuture2;
List<Map<String, dynamic>> allChats2 = [];
List<Map<String, dynamic>> filteredChats2 = [];
late String? user_Id;

  

  @override
  void initState()  {
    super.initState();
    _loadChatrooms();
    initWebSocketConnection();


       

    
    
  }

  //void setRecepientId(String userId) {
  //recepient_id = userId == '89' ? '2' : '89';

 // }
  void initWebSocketConnection() async {
  final TokenStorage _tokenStorage = TokenStorage();

  user_Id = await _tokenStorage.getUserId();
 // setRecepientId(user_Id!);
  // print('Recepient ID: $recepient_id');

  if (user_Id != null) {
    print(' ❌❌❌❌  user_Id: $user_Id   ❌❌❌❌');
    WebSocketService().connect(userId: "$user_Id");
  } else {
    print('❌ User ID not found');
  }
}

  

  Future<void> _loadChatrooms() async {
    _chatroomsFuture = ChatService.fetchChatrooms();
    print(' ---------------  ---------------  ---------------  --------------- calling the Simplified chatrooms function   ---------------  ---------------  ---------------  ---------------  ---------------  --------------- ');
    _chatroomsFuture2 = ChatService.fetchChatroomsSimplified();
    final chats2 = await _chatroomsFuture2;
    // Iterating over the list of chatrooms
    print('${chats2[0]['chatroom_id']}');
for (var chat in chats2) {
  print('The id of the chatroom is: ${chat['chatroom_id']}');
}
    final chats = await _chatroomsFuture;


    setState(() {
      allChats = chats;
      filteredChats = chats; // initially show all
      allChats2 = chats2;
    });
  }


  Future<void> _handleChatTap(String recepient_id , String chatroom_id , String SenderName , String RecipientName ,String first_member_id) async {
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
    print('the chatroom id that we will pass is: $chatroom_id');

    // Navigate to ChatScreene regardless of status
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreene(
          currentUserId: user_Id.toString(),
          recipientId: recepient_id,
          chatroomId : chatroom_id,
          senderName :  first_member_id == user_Id.toString().trim() ? SenderName : RecipientName,
          recipientName : first_member_id == user_Id.toString().trim() ? RecipientName : SenderName,
        ),
      ),
    );
  }
  @override
  void dispose() {
    WebSocketService().dispose();
    super.dispose();
  }
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
                    final chatDetails = allChats2[index]; // Accessing corresponding chat details
                    print('the first memebr id is: ${chatDetails['first_member_id']}');
                    print('my user id is: $user_Id');

                    return GestureDetector(

                      onTap: () => _handleChatTap( chatDetails['first_member_id'].toString().trim() == user_Id.toString().trim()
      ? chatDetails['second_member_id'].toString()
      : chatDetails['first_member_id'].toString(),chatDetails['chatroom_id'].toString(),chatDetails['first_member_name'].toString(),chatDetails['second_member_name'].toString(),chatDetails['first_member_id'].toString().trim(),
                      ),
                      child: ChatItem(
                        name: chatDetails['first_member_id'].toString().trim() == user_Id.toString().trim() ? chatDetails['second_member_name'] : chatDetails['first_member_name'],
                        lastMessage: chatDetails['last_message'] ?? 'No messages yet',
                        time: chat.time,
                        imageUrl: chatDetails['first_member_id'].toString().trim() == user_Id.toString().trim() ? chatDetails['second_member_image'] : chatDetails['first_member_image'],
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
