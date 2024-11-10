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
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _loading = false;
  bool _showNotification = false;
  String _notificationMessage = "";
  double _progressValue = 1.0;
  Timer? _timer;
  Color color = Colors.green;
  bool _hasUppercase = false;
  bool _hasUniqueCharacter = false;
  bool _passwordsMatch = false;
  int _strengthScore = 0;

  Future<void> _signUp() async {
    if (_passwordController.text.length < 8) {
      _showProgressNotification(
          'Password must be at least 8 characters long', Colors.red);
      return;
    }

    if (!_passwordsMatch) {
      _showProgressNotification('Passwords do not match', Colors.red);
      return;
    }

    if (!_hasUppercase || !_hasUniqueCharacter) {
      _showProgressNotification(
          'Password does not meet complexity requirements', Colors.red);
      return;
    }

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
      color = color;
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

  void _validatePassword(String password) {
    if (password.isEmpty) {
      // Reset validation flags if password field is empty
      setState(() {
        _hasUppercase = false;
        _hasUniqueCharacter = false;
        _passwordsMatch = false;
        _strengthScore = 0;
      });
      return;
    }

    setState(() {
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasUniqueCharacter =
          password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      _passwordsMatch = password == _confirmPasswordController.text;

      _strengthScore = 0;
      if (_hasUppercase) _strengthScore++;
      if (_hasUniqueCharacter) _strengthScore++;
      if (password.length >= 8) _strengthScore++;
    });
  }

  Color _getSegmentColor(int segmentIndex) {
    if (_strengthScore == 0) {
      return segmentIndex == 0
          ? Colors.red
          : const Color.fromARGB(255, 232, 232, 232);
    } else if (_strengthScore == 1) {
      return segmentIndex == 0
          ? Colors.red
          : const Color.fromARGB(255, 232, 232, 232);
    } else if (_strengthScore == 2) {
      return segmentIndex < 2
          ? Colors.orange
          : const Color.fromARGB(255, 232, 232, 232);
    } else {
      return Colors.green[800]!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
            child: SingleChildScrollView(
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
                      onChanged: _validatePassword,
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
                    SizedBox(height: 10),
                    TextField(
                      controller: _confirmPasswordController,
                      onChanged: (value) =>
                          _validatePassword(_passwordController.text),
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
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
                    SizedBox(height: 10),
                    _buildPasswordChecklist(),
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
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPasswordChecklist() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Strength',
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(3, (index) {
                  return Expanded(
                    child: Container(
                      height: 3,
                      margin: EdgeInsets.symmetric(horizontal: 2),
                      color: _getSegmentColor(index),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Icon(
              _hasUppercase ? Icons.check : Icons.close,
              color: _hasUppercase ? Colors.green : Colors.red,
            ),
            SizedBox(width: 4),
            Text('Contains uppercase letter',
                style: TextStyle(color: Colors.white)),
          ],
        ),
        Row(
          children: [
            Icon(
              _hasUniqueCharacter ? Icons.check : Icons.close,
              color: _hasUniqueCharacter ? Colors.green : Colors.red,
            ),
            SizedBox(width: 5),
            Text('Contains unique character',
                style: TextStyle(color: Colors.white)),
          ],
        ),
        Row(
          children: [
            Icon(
              _passwordsMatch ? Icons.check : Icons.close,
              color: _passwordsMatch ? Colors.green : Colors.red,
            ),
            SizedBox(width: 5),
            Text('Passwords match', style: TextStyle(color: Colors.white)),
          ],
        ),
        Row(
          children: [
            Icon(
              _passwordController.text.length >= 8 ? Icons.check : Icons.close,
              color: _passwordController.text.length >= 8
                  ? Colors.green
                  : Colors.red,
            ),
            SizedBox(width: 5),
            Text('Minimum 8 characters', style: TextStyle(color: Colors.white)),
          ],
        ),
      ],
    );
  }
}
