import 'dart:math' as math;
// import 'package:firebase_core/firebase_core.dart';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'HomeScreen.dart';
import 'dart:core';

String _parseFirebaseAuthExceptionMessage(
    {String plugin = "auth", required String? input}) {
  if (input == null) {
    return "unknown";
  }

  // https://regexr.com/7en3h
  String regexPattern = r'(?<=\(' + plugin + r'/)(.*?)(?=\)\.)';
  RegExp regExp = RegExp(regexPattern);
  Match? match = regExp.firstMatch(input);
  if (match != null) {
    return match.group(0)!;
  }

  return "unknown";
}

String? _errorHandleForWeb(String errorString) {
  try {
    String extractedValue = errorString.split("]")[0];
    return extractedValue.split('/')[1];
  } catch (e) {
    return null;
  }
}

// import 'components/center_widget/center_widget.dart';
// import 'components/login_content.dart';

class SosmadApp extends StatelessWidget {
  const SosmadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Sosmad',
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passController = TextEditingController();
  User? user;

  @override
  void dispose() {
    emailController.dispose();
    passController.dispose();
    super.dispose();
  }

  String? validateEmail(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$');
    if (!emailRegex.hasMatch(value!)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Please enter your password';
    }
    if (value!.length < 6) {
      return 'Password should be at least 6 characters';
    }
    return null;
  }

  void logout() {
    FirebaseAuth.instance.signOut();
    setState(() {
      user = null;
    });
  }

  void authUser() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final email = emailController.text.trim();
        final password = passController.text.trim();
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);
        // Authentication successful
        setState(() {
          user = userCredential.user;
        });
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => HomeScreen()));
      } on FirebaseAuthException catch (e) {
        final code = _parseFirebaseAuthExceptionMessage(input: e.message);
        final forWeb = _errorHandleForWeb(e.toString());

        if (code == 'user-not-found' || forWeb == 'user-not-found') {
          try {
            final email = emailController.text.trim();
            final password = passController.text.trim();
            UserCredential userCredential =
                await FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: email,
              password: password,
            );
            // User signed up successfully
            print('User signed up: ${userCredential.user?.email}');

            FirebaseAuth.instance
                .createUserWithEmailAndPassword(
                    email: email, password: password)
                .then((value) async {
              print(
                  "value: ${value} ${{'email': email, 'password': password}}");
              userCredential = await FirebaseAuth.instance
                  .signInWithEmailAndPassword(email: email, password: password);
            }).catchError((err) {
              print("ERROR CODE create: ${err}");
            });
            // Authentication successful
            print('User authenticated: ${userCredential.user?.email}');

            setState(() {
              user = userCredential.user;
            });

            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => HomeScreen()));
          } catch (e) {
            // Sign up failed
            print('Sign up error: $e');
          }
        } else if (e.code == 'wrong-password') {
          showDialog(
            context: context,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                title: const Text('Wrong Password'),
                content: const Text('The password entered is incorrect.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        } else {
          // Other authentication errors
          // print('Authentication error: $e');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Unknown error occurred"),
          ),
        );
      }
    }
  }

  Widget topWidget(double screenWidth) {
    return Transform.rotate(
      angle: -35 * math.pi / 180,
      child: Container(
        width: 1.2 * screenWidth,
        height: 1.2 * screenWidth,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(150),
          gradient: const LinearGradient(
            begin: Alignment(-0.2, -0.8),
            end: Alignment.bottomCenter,
            colors: [
              Color(0x007CBFCF),
              Color(0xB316BFC4),
            ],
          ),
        ),
      ),
    );
  }

  Widget bottomWidget(double screenWidth) {
    return Container(
      width: 1.5 * screenWidth,
      height: 1.5 * screenWidth,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment(0.6, -1.1),
          end: Alignment(0.7, 0.8),
          colors: [
            Color(0xDB4BE8CC),
            Color(0x005CDBCF),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -160,
            left: -30,
            child: topWidget(screenSize.width),
          ),

          Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                  ),
                  style: TextStyle(
                    color: Colors.black,
                  ),
                  validator: validateEmail,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: passController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                  ),
                  style: TextStyle(
                    color: Colors.black,
                  ),
                  validator: validatePassword,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: authUser,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 40,
                    ),
                    child: Text(
                      user != null ? 'Logout' : 'Login',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (user != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      'User is already signed in.',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Positioned(
            bottom: -180,
            left: -40,
            child: bottomWidget(screenSize.width),
          ),
          // CenterWidget(size: screenSize),
          // const LoginContent(),
        ],
      ),
    );
  }
}
