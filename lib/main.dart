import 'package:flutter/material.dart';
import 'views/screens/chat_screen_test.dart';
import 'package:lockchat/views/screens/chat_list_screen.dart';
import 'views/screens/incoming_requests.dart';
import 'views/screens/home.dart';
import 'views/screens/signup.dart';


void main() async {
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
      home: ChatScreen(),

    );
  }
}
