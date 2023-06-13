import 'package:chat_app/FriendListScreen.dart';
import 'package:chat_app/ProfileScreen.dart';
import 'package:chat_app/SearchScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'AuthScreen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const List<Widget> _widgetOptions = <Widget>[
    FriendListScreen(),
    ProfileEditScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void updateDeviceToken() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? deviceToken = await messaging.getToken();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final userDoc = _firestore.collection('users').doc(uid);
    await userDoc.update({'deviceToken': deviceToken});
  }

  void getMessage() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print(message);
    });

    FirebaseMessaging.onBackgroundMessage((message) {
      print(message);
      throw "hello";
    });
  }

  @override
  void initState() {
    super.initState();
    updateDeviceToken();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const SearchScreen(),
            ),
          );
        },
        child: const Icon(Icons.refresh),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
