import 'package:flutter/material.dart';
import '../theme/colors.dart';

// Custom Button Widget
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const CustomButton({super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180, // Adjust width as needed
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add, color: AppColors.darkpurple),
        label: Text(
          text,
          style: const TextStyle(
            color: AppColors.darkpurple,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.darkpurple, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), // Oval shape
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          backgroundColor: Colors.transparent,
        ),
      ),
    );
  }
}
