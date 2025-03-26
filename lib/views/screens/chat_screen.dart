import 'package:flutter/material.dart';
import '../theme/colors.dart';

class ChatScreen extends StatelessWidget {
  final String name;
  final String imageUrl;

  const ChatScreen({super.key, required this.name, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.darkpurple,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(imageUrl),
            ),
            const SizedBox(width: 10),
            Text(name, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
      body: Center(
        child: Text(
          'Chat with $name',
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
