import 'package:flutter/material.dart';
import '../theme/colors.dart';

class ContactCard extends StatelessWidget {
  final String name;
  final String phone;
  final String image;
  final bool isNetworkImage;

  const ContactCard({
    super.key,
    required this.name,
    required this.phone,
    required this.image,
    this.isNetworkImage = false, // Default to false (for assets)
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
      padding: const EdgeInsets.symmetric(vertical: 10), // Increased height
      decoration: BoxDecoration(
        color: Colors.transparent, // Transparent background
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 2),
            leading: CircleAvatar(
              backgroundImage: isNetworkImage
                  ? NetworkImage(image) // Use network image
                  : AssetImage(image) as ImageProvider, // Use local asset
              radius: 30, // Slightly larger avatar
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(phone),
            trailing: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("+ Add", style: TextStyle(color: Colors.white)),
            ),
          ),

          // Purple line spanning from image to button
          Padding(
            padding: const EdgeInsets.only(left: 17, right: 13,top: 15), // Matches the layout
            child: Container(
              height: 2,
              width: double.infinity,
              color: AppColors.darkpurple.withOpacity(0.5), // Semi-transparent purple
            ),
          ),
        ],
      ),
    );
  }
}
