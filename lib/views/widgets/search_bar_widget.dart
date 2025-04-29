import 'package:flutter/material.dart';
import '../theme/colors.dart';

class SearchBarWidget extends StatelessWidget {
  // Add this final callback, nullable, so the parent can listen to text changes
  final ValueChanged<String>? onChanged;

  // Update constructor to accept the callback
  const SearchBarWidget({super.key, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        // Hook up the onChanged callback here
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search',
          prefixIcon: Icon(Icons.search, color: AppColors.darkpurple),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
