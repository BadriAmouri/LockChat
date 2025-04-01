import 'package:flutter/material.dart';
import 'views/screens/chat_list_screen.dart';
import 'views/screens/add_contact_screen.dart';
import 'views/screens/chat_screen_test.dart';
import 'views/screens/login.dart';
import 'views/screens/signup.dart';
import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/export.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';



void main() async  {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure async functions work before runApp()
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
      home: SignupScreen(),
    );
  }
}