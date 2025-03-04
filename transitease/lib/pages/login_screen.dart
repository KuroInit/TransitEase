import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'sign_up_screen.dart';
import 'dart:async';
import 'package:transitease/models/models.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  bool _showNotification = false;
  String _notificationMessage = "";
  Color _notificationColor = Colors.green;
  double _progressValue = 1.0;
  Timer? _timer;
  AppUser? _currentUser;

  Future<void> _loginWithEmail() async {
    setState(() {
      _loading = true;
    });
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text, password: _passwordController.text);

      var authToken = await userCredential.user!.getIdToken();
      _currentUser = AppUser.fromFirebaseUser(userCredential.user!, authToken);

      // Save the user data
      await _saveCurrentUser(_currentUser!);

      _showProgressNotification('Login successful!', Colors.green);

      Timer(Duration(seconds: 3), () {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => HomeScreen(user: _currentUser!)));
      });
    } catch (e) {
      _showProgressNotification('Login failed: Wrong Credentials', Colors.red);
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _saveCurrentUser(AppUser user) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userID', user.userID);
    await prefs.setString('authToken', user.authToken);
    await prefs.setBool('notificationEnabled', user.notificationEnabled);
  }

  Future<void> _loadCurrentUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userID = prefs.getString('userID');
    String? authToken = prefs.getString('authToken');
    bool? notificationEnabled = prefs.getBool('notificationEnabled') ?? false;

    if (userID != null && authToken != null) {
      setState(() {
        _currentUser = AppUser(
            userID: userID,
            authToken: authToken,
            notificationEnabled: notificationEnabled);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  void _showProgressNotification(String message, Color color) {
    setState(() {
      _notificationMessage = message;
      _showNotification = true;
      _notificationColor = color;
      _progressValue = 1.0;
    });

    _timer = Timer.periodic(Duration(milliseconds: 20), (Timer timer) {
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
          SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'Assets/Icon Creator Online.png',
                      height: 300,
                      width: 300,
                    ),
                    SizedBox(height: 20),
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
                            onPressed: _loginWithEmail,
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.green,
                              backgroundColor: Colors.white,
                            ),
                            child: Text('Login'),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => SignUpScreen()));
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.green,
                              backgroundColor: Colors.white,
                            ),
                            child: Text('Sign up'),
                          ),
                        ),
                      ],
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
                      valueColor:
                          AlwaysStoppedAnimation<Color>(_notificationColor),
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
