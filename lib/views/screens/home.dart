import 'package:flutter/material.dart';
import '../widgets/header.dart';
import '../theme/colors.dart';
import 'chat_screen_test.dart';
import 'setting.dart';
import 'incoming_requests.dart';
import 'package:lockchat/views/screens/chat_list_screen.dart';
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Wave header with PWA logo
          HeaderWidget(text: "PWA"),
          SizedBox(height: 60),
          // Menu options
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  const SizedBox(height: 30),

                  // chat button
                  _buildMenuButton(
                    icon: Icons.chat_bubble_outline,
                    label: 'Chats',
                    onTap: () {
                      // Navigate to chat page
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ChatListScreen()),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // requests button
                  _buildMenuButton(
                    icon: Icons.call_received,
                    label: 'Requests',
                    onTap: () {
                      // Navigate to request page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatRequestListScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Settings button
                  _buildMenuButton(
                    icon: Icons.settings,
                    label: 'Settings',
                    onTap: () {
                      // Navigate to settings page
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SettingsPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: AppColors.buttonColor),
            const SizedBox(width: 20),
            Text(
              label,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
