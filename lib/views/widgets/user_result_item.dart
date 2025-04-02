// views/widgets/user_result_item.dart
import 'package:flutter/material.dart';
import '../theme/colors.dart';

class UserResultItem extends StatelessWidget {
  final String username;
  final VoidCallback onSendRequest;

  const UserResultItem({
    super.key,
    required this.username,
    required this.onSendRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // User avatar
            CircleAvatar(
              backgroundColor: AppColors.darkpurple.withOpacity(0.2),
              radius: 24,
              child: Text(
                username.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkpurple,
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Username
            Expanded(
              child: Text(
                username,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            // Send request button
            TextButton.icon(
              onPressed: onSendRequest,
              icon: const Icon(Icons.person_add_alt_1, size: 20),
              label: const Text('Request'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.darkpurple,
                backgroundColor: AppColors.darkpurple.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
