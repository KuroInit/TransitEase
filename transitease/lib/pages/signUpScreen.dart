import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  bool _showNotification = false;
  String _notificationMessage = "";
  double _progressValue = 1.0;
  Timer? _timer;

  Future<void> _signUp() async {
    setState(() {
      _loading = true;
    });
    try {
      await _auth.createUserWithEmailAndPassword(
          email: _emailController.text, password: _passwordController.text);
      _showProgressNotification(
          'Sign up successful! Please log in.', Colors.green);
      Timer(Duration(seconds: 3), () {
        Navigator.pop(context);
      });
    } catch (e) {
      _showProgressNotification('Sign up failed: $e', Colors.red);
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _showProgressNotification(String message, Color color) {
    setState(() {
      _notificationMessage = message;
      _showNotification = true;
      _progressValue = 1.0;
    });

    _timer = Timer.periodic(Duration(milliseconds: 50), (Timer timer) {
      setState(() {
        _progressValue -= 0.02;
        if (_progressValue <= 0.0) {
          _progressValue = 0.0;
          _showNotification = false;
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: Colors.white),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(color: Colors.white),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    obscureText: true,
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 20),
                  _loading
                      ? CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _signUp,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.green,
                            backgroundColor: Colors.white,
                          ),
                          child: Text('Sign up'),
                        ),
                  SizedBox(height: 20),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Divider(
                          color: Colors.white,
                          thickness: 1,
                        ),
                      ),
                      Text(
                        " OR ",
                        style: TextStyle(color: Colors.white),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.white,
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.green,
                      backgroundColor: Colors.white,
                    ),
                    child: Text('Back to Login'),
                  ),
                ],
              ),
            ),
          ),
          if (_showNotification)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      _notificationMessage,
                      style: TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: _progressValue,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
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
