import 'package:chat_app/components/auth_button.dart';
import 'package:chat_app/components/customer_text_field.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chat_app/screens/Home/HomeScreen.dart';
import 'package:chat_app/services/AuthService.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passController = TextEditingController();
  bool isLogin = true;
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    emailController.dispose();
    passController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      isLogin = !isLogin;
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final email = emailController.text.trim();
        final password = passController.text.trim();

        User? user;
        if (isLogin) {
          user = await _authService.signIn(email, password);
        } else {
          user = await _authService.signUp(email, password);
        }

        if (user != null) {
          Navigator.of(context).pushReplacementNamed('/');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Colors.black,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isLogin ? 'Welcome Back' : 'Create Account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        CustomTextField(
                          controller: emailController,
                          hintText: 'Email',
                          icon: Icons.email_outlined,
                          validator: _authService.validateEmail,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: passController,
                          hintText: 'Password',
                          icon: Icons.lock_outline,
                          obscureText: true,
                          validator: _authService.validatePassword,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  AuthButton(
                    text: isLogin ? 'Log In' : 'Sign Up',
                    onPressed: _submitForm,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _toggleAuthMode,
                    child: Text(
                      isLogin
                          ? 'Don\'t have an account? Sign Up'
                          : 'Already have an account? Log In',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
