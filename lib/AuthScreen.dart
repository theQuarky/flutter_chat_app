import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'HomeScreen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passController = TextEditingController();
  User? user = FirebaseAuth.instance.currentUser;

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
        final UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);
        // Authentication successful
        print('User authenticated: ${userCredential.user?.email}');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const HomeScreen(newUser: false)),
        );
        setState(() {
          user = userCredential.user;
        });
      } catch (e) {
        // Authentication failed
        if (e is FirebaseAuthException && e.code == 'user-not-found') {
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

            userCredential = await FirebaseAuth.instance
                .signInWithEmailAndPassword(email: email, password: password);
            // Authentication successful
            print('User authenticated: ${userCredential.user?.email}');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => HomeScreen(newUser: true)),
            );
            setState(() {
              user = userCredential.user;
            });
          } catch (e) {
            // Sign up failed
            print('Sign up error: $e');
          }
        } else if (e is FirebaseAuthException && e.code == 'wrong-password') {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Wrong Password'),
                content: const Text('The password entered is incorrect.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        } else {
          // Other authentication errors
          print('Authentication error: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [Text('Login')],
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Email',
                  ),
                  validator: validateEmail,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: passController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Password',
                  ),
                  validator: validatePassword,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: user != null ? logout : authUser,
                  child: Text(user != null ? 'Logout' : 'Login'),
                ),
                if (user != null) const Text('User is already signed in.'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
