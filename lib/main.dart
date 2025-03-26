import 'package:flutter/material.dart';
import 'views/screens/chat_list_screen.dart';
import 'views/screens/add_contact_screen.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: ChatListScreen (),
    );
  }
}