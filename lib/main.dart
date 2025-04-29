import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';  // Import supabase

import 'views/screens/chat_screen_test.dart';
import 'package:lockchat/views/screens/chat_list_screen.dart';
import 'views/screens/incoming_requests.dart';
import 'views/screens/home.dart';
import 'views/screens/signup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://goecluaeedztfvcioywx.supabase.co', // Replace with your Supabase project URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdvZWNsdWFlZWR6dGZ2Y2lveXd4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDMxMjY5OTksImV4cCI6MjA1ODcwMjk5OX0.Wq6CeMGRHYUyMuy0Z7evxRMxO2xq9ihJHI8toe8xaoM',    // Replace with your anon/public key
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final Map<String, WidgetBuilder> routes = {
    '/ChatScreen': (context) => ChatScreen(),
  };

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
