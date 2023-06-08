import 'dart:async';

import 'package:chat_app/MainScreen.dart';
import 'package:chat_app/TempChatScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;

  void addToSearchQueue() async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    DocumentReference<Map<String, dynamic>> documentRef =
        _firestore.collection('users').doc(uid ?? '');
    DocumentSnapshot<Map<String, dynamic>> snapshot = await documentRef.get();
    Map<String, dynamic> user = snapshot.data() ?? {};

    documentRef = _firestore
        .collection('searchQueue')
        .doc(user['gender'] == 'male' ? 'female' : 'male');
    snapshot = await documentRef.get();
    Map<String, dynamic>? data = snapshot.data();

    if (data != null && (data['active'] as List<dynamic>).isEmpty) {
      documentRef = _firestore.collection('searchQueue').doc(user['gender']);
      documentRef.update({
        'active': FieldValue.arrayUnion([uid]),
      });
    } else {
      if (data != null) {
        _subscription?.cancel();
        String chatId = data['active'][0];

        final userDocumentRef = _firestore.collection('tempChats');

        final queryA = userDocumentRef.where('partyA', isEqualTo: chatId);
        final queryB = userDocumentRef.where('partyB', isEqualTo: chatId);

        final snapshotA = await queryA.get();
        final snapshotB = await queryB.get();
        final batch = _firestore.batch();

        for (final doc in snapshotA.docs) {
          batch.delete(doc.reference);
        }
        for (final doc in snapshotB.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();
        await documentRef.set({
          'active': FieldValue.arrayRemove([chatId]),
        });
        CollectionReference tempChat = _firestore.collection('tempChats');
        tempChat.add({'partyA': chatId, 'partyB': uid}).then((value) async {
          print('Searching User');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TempChatScreen(),
            ),
          );
        });
      }
    }
  }

  void listenPicker() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final userDocumentRef = _firestore.collection('users').doc(uid ?? '');
    try {
      final userSnapshot = await userDocumentRef.get();
      final user = userSnapshot.data() ?? {};
      final queueDocumentRef =
          _firestore.collection('searchQueue').doc(user['gender']);

      _subscription = queueDocumentRef.snapshots().listen((snapshot) {
        final searchQueueData = snapshot.data();
        if (searchQueueData != null &&
            !(searchQueueData['active'] as List).contains(uid)) {
          _subscription?.cancel();
          print('User picked');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TempChatScreen(),
            ),
          );
        }
      });
    } catch (e) {
      print('Error: $e');
      // Handle the error appropriately
    }
  }

  @override
  void initState() {
    addToSearchQueue();
    listenPicker();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Listen for changes in searchQueue
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _subscription?.cancel(); // Cancel the stream subscription
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: GestureDetector(
              onTapDown: _onTapDown,
              onTapUp: _onTapUp,
              child: AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (BuildContext context, Widget? child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue,
                      ),
                      child: const Icon(
                        Icons.search,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              String? uid = FirebaseAuth.instance.currentUser?.uid;
              DocumentReference<Map<String, dynamic>> documentRef =
                  _firestore.collection('users').doc(uid ?? '');
              DocumentSnapshot<Map<String, dynamic>> snapshot =
                  await documentRef.get();
              Map<String, dynamic> user = snapshot.data() ?? {};

              documentRef =
                  _firestore.collection('searchQueue').doc(user['gender']);
              _subscription?.cancel();
              documentRef.update({
                'active': FieldValue.arrayRemove([uid]),
              });
              // ignore: use_build_context_synchronously
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => const MainScreen()));
            },
            child: const Text('Exit'),
          )
        ],
      ),
    );
  }
}
