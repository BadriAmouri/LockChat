import 'package:flutter/material.dart';
import '../theme/colors.dart';

class ChatItem extends StatelessWidget {
  final String name;
  final String lastMessage;
  final String time;
  final String imageUrl;
  final int unreadMessages;

  const ChatItem({
    super.key,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.imageUrl,
    required this.unreadMessages,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 15), // Added bottom padding for space
          child: Row(
            children: [
              // Larger Profile Picture
              CircleAvatar(
                radius: 25, // Increased size
                backgroundImage: NetworkImage(imageUrl),
              ),
              const SizedBox(width: 15), // Space between avatar and text
              
              // Chat Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4), // Space between name & message
                    Text(
                      lastMessage,
                      style: TextStyle(color: AppColors.subtitle, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis, // Prevents overflow
                    ),
                  ],
                ),
              ),

              // Time & Unread Messages
              Column(
                children: [
                  Text(
                    time,
                    style: TextStyle(color: AppColors.subtitle, fontSize: 12),
                  ),
                  const SizedBox(height: 7), // Space before unread counter

                  // Unread messages as a box (not a circle)
                  if (unreadMessages > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.darkpurple,
                        borderRadius: BorderRadius.circular(6), // Rounded corners
                      ),
                      child: Text(
                        '$unreadMessages',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        // Purple Separator Line (from image to time)
        Padding(
          padding: const EdgeInsets.only(left: 17, right: 17, bottom: 15,top: 15), // Added bottom padding for more space
          child: Container(
            height: 1.5,
            color: AppColors.darkpurple.withOpacity(0.5), // Light purple line
          ),
        ),
      ],
    );
  }
}
