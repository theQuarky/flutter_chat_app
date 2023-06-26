import 'package:chat_app/ProfileScreen.dart';
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool? newUserCheck = null;

  void isNewUser() async {
    User? user = await FirebaseAuth.instance.currentUser;
    DocumentSnapshot doc =
        await _firestore.collection('users').doc(user?.uid).get();

    if (doc.data() == null) return;
    Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      setState(() {
        newUserCheck = false;
      });
      return;
    }

    if (data.isNotEmpty) {
      setState(() {
        newUserCheck = true;
      });
    }
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
    if (newUserCheck == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return Container(
      color: Colors.white,
      child: Center(
        child: newUserCheck == true
            ? const MainScreen()
            : const ProfileEditScreen(),
      ),
    );
  }
}
