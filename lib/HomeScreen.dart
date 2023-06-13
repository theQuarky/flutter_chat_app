import 'package:chat_app/ProfileScreen.dart';
import 'package:chat_app/services/userService.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'AuthScreen.dart';
import 'MainScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  late bool newUserCheck = false;

  void isNewUser() async {
    try {
      final user =
          await getUserDataByUID(FirebaseAuth.instance.currentUser?.uid);
      print("USER DATA: $user");
      if (user != null) {
        setState(() {
          newUserCheck = true;
        });
      }
    } catch (e) {}
  }

  @override
  void initState() {
    super.initState();
    isNewUser();
  }

  void logout() {
    setState(() {
      newUserCheck = true;
    });
    FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: newUserCheck ? const MainScreen() : const ProfileEditScreen(),
      ),
    );
  }
}
