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

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
              ),
              child: Padding(
                padding: const EdgeInsets.all(0),
                child: Container(
                  height: 600,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 30),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: emailController,
                                  decoration: InputDecoration(
                                    hintText: 'Email',
                                    filled: true,
                                    fillColor: Color(0xFFE0E0E0),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  validator: validateEmail,
                                ),
                                SizedBox(height: 20),
                                TextFormField(
                                  controller: passController,
                                  decoration: InputDecoration(
                                    hintText: 'Password',
                                    filled: true,
                                    fillColor: const Color(0xFFE0E0E0),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  obscureText: true,
                                  validator: validatePassword,
                                ),
                              ],
                            )),
                      ),
                      SizedBox(height: 20),
                      Container(
                        width: 230,
                        height: 60,
                        decoration: ShapeDecoration(
                          color: Color(0xFF376AED),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: authUser,
                          child: Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 18,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF376AED),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: 15,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      TextButton(
                        onPressed: () {
                          // Add your "Create Account" button functionality here
                        },
                        child: Column(children: [
                          Text(
                            'Don’t have an account?',
                            style: TextStyle(
                              color: const Color.fromARGB(255, 0, 0, 0),
                            ),
                          ),
                          Text(
                            'Login with your email and password from here',
                            style: TextStyle(
                              color: const Color.fromARGB(255, 0, 0, 0),
                            ),
                          )
                        ]),
                      ),
                    ],
                  ),
                ),

                // child: Stack(
                //   children: [
                //     // Positioned(
                //     //   height: 250,
                //     //   width: 500,
                //     //   left: 0,
                //     //   top: 320,
                //     //   child: Container(
                //     //     width: double.infinity,
                //     //     height: 250,
                //     //     color: Color(0xFF376AED),
                //     //     child: Column(
                //     //       mainAxisAlignment: MainAxisAlignment.center,
                //     //       children: [
                //     //         Text(
                //     //           "Welcome",
                //     //           style: TextStyle(
                //     //             color: Colors.white,
                //     //             fontSize: 30,
                //     //             fontWeight: FontWeight.bold,
                //     //           ),
                //     //         ),
                //     //         SizedBox(height: 10),
                //     //         Text(
                //     //           "Sign in to continue",
                //     //           style: TextStyle(
                //     //             color: Colors.white,
                //     //             fontSize: 20,
                //     //           ),
                //     //         ),
                //     //       ],
                //     //     ),
                //     //   ),
                //     // ),

                //     Center(
                //       child: Positioned(
                //         height: 250,
                //         width: 500,
                //         left: 0,
                //         top: 320,
                //         child:

                //       ),
                //     ),
                // Positioned(
                //   height: 600,
                //   left: 0,
                //   top: 0,
                //   child: Padding(
                //     padding: const EdgeInsets.all(0),
                //     child: Container(
                //       child: Column(
                //         crossAxisAlignment: CrossAxisAlignment.stretch,
                //         mainAxisAlignment: MainAxisAlignment.center,
                //         children: [
                //           Text("First"),
                //           Text("Second"),
                //           Text("Third")
                //         ],
                //       ),
                //       decoration: ShapeDecoration(
                //         shape: RoundedRectangleBorder(
                //           borderRadius: BorderRadius.only(
                //             topLeft: Radius.circular(30),
                //             topRight: Radius.circular(30),
                //           ),
                //         ),
                //         color: Color.fromARGB(255, 204, 82, 82),
                //       ),
                //     ),
                //   ),
                // )
                // ],
                // ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
