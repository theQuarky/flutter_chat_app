// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'HomeScreen.dart';
// import 'dart:core';

// String _parseFirebaseAuthExceptionMessage(
//     {String plugin = "auth", required String? input}) {
//   if (input == null) {
//     return "unknown";
//   }

//   // https://regexr.com/7en3h
//   String regexPattern = r'(?<=\(' + plugin + r'/)(.*?)(?=\)\.)';
//   RegExp regExp = RegExp(regexPattern);
//   Match? match = regExp.firstMatch(input);
//   if (match != null) {
//     return match.group(0)!;
//   }

//   return "unknown";
// }

// String? _errorHandleForWeb(String errorString) {
//   try {
//     String extractedValue = errorString.split("]")[0];
//     return extractedValue.split('/')[1];
//   } catch (e) {
//     return null;
//   }
// }

// class AuthScreen extends StatefulWidget {
//   const AuthScreen({Key? key}) : super(key: key);

//   @override
//   State<AuthScreen> createState() => _AuthScreenState();
// }

// class _AuthScreenState extends State<AuthScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final emailController = TextEditingController();
//   final passController = TextEditingController();
//   User? user;

//   @override
//   void dispose() {
//     emailController.dispose();
//     passController.dispose();
//     super.dispose();
//   }

//   String? validateEmail(String? value) {
//     if (value?.isEmpty ?? true) {
//       return 'Please enter your email';
//     }
//     final emailRegex = RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$');
//     if (!emailRegex.hasMatch(value!)) {
//       return 'Please enter a valid email address';
//     }
//     return null;
//   }

//   String? validatePassword(String? value) {
//     if (value?.isEmpty ?? true) {
//       return 'Please enter your password';
//     }
//     if (value!.length < 6) {
//       return 'Password should be at least 6 characters';
//     }
//     return null;
//   }

//   void logout() {
//     FirebaseAuth.instance.signOut();
//     setState(() {
//       user = null;
//     });
//   }

//   void authUser() async {
//     if (_formKey.currentState?.validate() ?? false) {
//       try {
//         final email = emailController.text.trim();
//         final password = passController.text.trim();
//         UserCredential userCredential = await FirebaseAuth.instance
//             .signInWithEmailAndPassword(email: email, password: password);
//         // Authentication successful
//         setState(() {
//           user = userCredential.user;
//         });
//         Navigator.pushReplacement(
//             context, MaterialPageRoute(builder: (context) => HomeScreen()));
//       } on FirebaseAuthException catch (e) {
//         final code = _parseFirebaseAuthExceptionMessage(input: e.message);
//         final forWeb = _errorHandleForWeb(e.toString());

//         if (code == 'user-not-found' || forWeb == 'user-not-found') {
//           try {
//             final email = emailController.text.trim();
//             final password = passController.text.trim();
//             UserCredential userCredential =
//                 await FirebaseAuth.instance.createUserWithEmailAndPassword(
//               email: email,
//               password: password,
//             );
//             // User signed up successfully
//             print('User signed up: ${userCredential.user?.email}');

//             FirebaseAuth.instance
//                 .createUserWithEmailAndPassword(
//                     email: email, password: password)
//                 .then((value) async {
//               print(
//                   "value: ${value} ${{'email': email, 'password': password}}");
//               userCredential = await FirebaseAuth.instance
//                   .signInWithEmailAndPassword(email: email, password: password);
//             }).catchError((err) {
//               print("ERROR CODE create: ${err}");
//             });
//             // Authentication successful
//             print('User authenticated: ${userCredential.user?.email}');

//             setState(() {
//               user = userCredential.user;
//             });

//             Navigator.pushReplacement(
//                 context, MaterialPageRoute(builder: (context) => HomeScreen()));
//           } catch (e) {
//             // Sign up failed
//             print('Sign up error: $e');
//           }
//         } else if (e.code == 'wrong-password') {
//           showDialog(
//             context: context,
//             builder: (BuildContext dialogContext) {
//               return AlertDialog(
//                 title: const Text('Wrong Password'),
//                 content: const Text('The password entered is incorrect.'),
//                 actions: [
//                   TextButton(
//                     onPressed: () {
//                       Navigator.of(dialogContext).pop();
//                     },
//                     child: const Text('OK'),
//                   ),
//                 ],
//               );
//             },
//           );
//         } else {
//           // Other authentication errors
//           // print('Authentication error: $e');
//         }
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Unknown error occurred"),
//           ),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Column(
//         children: [
//           Expanded(
//             child: Container(
//               width: double.infinity,
//               decoration: BoxDecoration(
//                 color: Color(0xFF376AED),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(20.0),
//                 child: Stack(
//                   children: [
//                     Align(
//                       alignment: Alignment.topLeft,
//                       child: IconButton(
//                         icon: Icon(Icons.arrow_back, color: Colors.white),
//                         onPressed: () {
//                           // Add your back button functionality here
//                         },
//                       ),
//                     ),
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.stretch,
//                       children: [
//                         SizedBox(height: 70),
//                         Text(
//                           'Sign In',
//                           textAlign: TextAlign.center,
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 30,
//                             fontFamily: 'Roboto',
//                             fontWeight: FontWeight.w400,
//                           ),
//                         ),
//                         SizedBox(height: 30),
//                         Form(
//                             key: _formKey,
//                             child: Column(
//                               children: [
//                                 TextFormField(
//                                   controller: emailController,
//                                   decoration: InputDecoration(
//                                     hintText: 'Email',
//                                     filled: true,
//                                     fillColor: Colors.white,
//                                     border: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(12),
//                                       borderSide: BorderSide.none,
//                                     ),
//                                   ),
//                                 ),
//                                 SizedBox(height: 20),
//                                 TextFormField(
//                                   controller: passController,
//                                   decoration: InputDecoration(
//                                     hintText: 'Password',
//                                     filled: true,
//                                     fillColor: Colors.white,
//                                     border: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(12),
//                                       borderSide: BorderSide.none,
//                                     ),
//                                   ),
//                                   obscureText: true,
//                                 ),
//                               ],
//                             )),
//                         SizedBox(height: 20),
//                         ElevatedButton(
//                           onPressed: authUser,
//                           child: Text(
//                             'Sign In',
//                             style: TextStyle(
//                               fontSize: 18,
//                             ),
//                           ),
//                           style: ElevatedButton.styleFrom(
//                             primary: Color.fromARGB(255, 111, 147, 236),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             padding: EdgeInsets.symmetric(
//                               vertical: 15,
//                             ),
//                           ),
//                         ),
//                         SizedBox(height: 20),
//                         TextButton(
//                           onPressed: () {
//                             // Add your "Create Account" button functionality here
//                           },
//                           child: Column(children: [
//                             Text(
//                               'Don’t have an account?',
//                               style: TextStyle(
//                                 color: Colors.white,
//                               ),
//                             ),
//                             Text(
//                               'Login with your email and password from here',
//                               style: TextStyle(
//                                 color: Colors.white,
//                               ),
//                             )
//                           ]),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
