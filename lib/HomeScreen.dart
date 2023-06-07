import 'package:chat_app/ProfileScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'AuthScreen.dart';
import 'MainScreen.dart';

class HomeScreen extends StatefulWidget {
  final bool newUser;
  const HomeScreen({Key? key, required this.newUser}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late bool newUserCheck = true;

  Future<bool> isNewUser() async {
    DocumentReference<Map<String, dynamic>> documentRef = _firestore
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid ?? '');

    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot = await documentRef.get();
      return snapshot.exists;
    } catch (error) {
      print('Error checking user existence: $error');
      return true; // Consider it a new user to be safe
    }
  }

  @override
  void initState() {
    super.initState();
    isNewUser().then((isNew) {
      setState(() {
        newUserCheck = isNew;
      });
    });
  }

  void logout() {
    setState(() {
      newUserCheck = false;
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
