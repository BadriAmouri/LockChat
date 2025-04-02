import 'package:flutter/material.dart';
import '../widgets/contact_card.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../theme/colors.dart';

class AddContactsScreen extends StatelessWidget {
   AddContactsScreen({super.key});

  final List<Map<String, String>> contacts = [
    {
      "name": "Metal Exchange",
      "phone": "+43 123-456-7890",
      "image": "https://example.com/metal_exchange.jpg"
    },
    {
      "name": "Michael Tony",
      "phone": "+43 123-456-7890",
      "image": "https://example.com/michael_tony.jpg"
    },
    {
      "name": "Joseph Ray",
      "phone": "+43 123-456-7890",
      "image": "https://example.com/joseph_ray.jpg"
    },
    {
      "name": "Thomas Adison",
      "phone": "+43 123-456-7890",
      "image": "https://example.com/thomas_adison.jpg"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Add Contacts",
          style: TextStyle(color: Colors.white), 
        ),
        backgroundColor: AppColors.darkpurple,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), 
          onPressed: () {
            Navigator.pop(context); 
          },
        ),
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 15),
                const Text(
                  "ADD NEW CONTACT",
                  style: TextStyle(
                    fontSize: 22, // Increased font size
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),

                CustomTextField(hintText: "+213 XXX-XX-XX-XX", icon: Icons.phone),

                const SizedBox(height: 50),
                Center(child: CustomButton(text: "Add Contact", onPressed: () {})), 
                const SizedBox(height: 30),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Contact List Section
          Expanded(
            child: Container(
              width: double.infinity, 
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.background, 
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -3), 
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 150,
                    height: 7,
                    decoration: BoxDecoration(
                      color: Colors.grey[700], 
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 30),

                  const Center(
                    child: Text(
                      "EXISTING CONTACTS IN PHONE",
                      style: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7B3FD3), 
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Expanded(
                    child: ListView.builder(
                      itemCount: contacts.length,
                      itemBuilder: (context, index) {
                        return ContactCard(
                          name: contacts[index]["name"]!,
                          phone: contacts[index]["phone"]!,
                          image: contacts[index]["image"]!,
                          isNetworkImage: true, 
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }




}
