import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_map/flutter_map.dart';
import 'pages/login.dart';
import 'pages/signup.dart';
import 'pages/mapcontroller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: LoginScreen(), // Starting screen
      routes: {
        '/login': (context) => LoginScreen(),
        '/map': (context) => MapControllerScreen(),
        '/signup': (context) => SignupScreen(),
      },
    );
  }
}
