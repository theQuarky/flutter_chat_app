import 'dart:async';
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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final userDocumentRef = _firestore.collection('users').doc(uid ?? '');
    final userSnapshot = await userDocumentRef.get();
    final userData = userSnapshot.data() as Map<String, dynamic>?;

    if (userData != null) {
      final gender = userData['gender'];
      final oppositeGender = gender == 'male' ? 'female' : 'male';

      final oppositeQueueRef =
          _firestore.collection('searchQueue').doc(oppositeGender);
      final oppositeQueueSnapshot = await oppositeQueueRef.get();
      final oppositeQueueData = oppositeQueueSnapshot.data();

      if (oppositeQueueData != null &&
          (oppositeQueueData['active'] as List).isEmpty) {
        final currentQueueRef =
            _firestore.collection('searchQueue').doc(gender);
        currentQueueRef.update({
          'active': FieldValue.arrayUnion([uid])
        });
        listenPicker();
      } else if (oppositeQueueData != null) {
        final chatId = oppositeQueueData['active'][0] as String;

        final tempChatsRef = _firestore.collection('tempChats');

        final queryA = tempChatsRef.where('partyA', isEqualTo: chatId);
        final queryB = tempChatsRef.where('partyB', isEqualTo: chatId);

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
        await oppositeQueueRef.update({
          'active': FieldValue.arrayRemove([chatId])
        });

        final tempChatRef = _firestore.collection('tempChats');
        await tempChatRef.add({'partyA': chatId, 'partyB': uid});
        Navigator.pushNamed(context, '/tempChat');
      }
    }
  }

  void listenPicker() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final tempChatsRef = _firestore.collection('tempChats');
    final tempChatSnapshotA =
        await tempChatsRef.where('partyA', isEqualTo: uid).get();
    final tempChatSnapshotB =
        await tempChatsRef.where('partyB', isEqualTo: uid).get();

    if (tempChatSnapshotA.size > 0 || tempChatSnapshotB.size > 0) {
      Navigator.pushNamed(context, '/tempChat');
      return;
    }

    final userDocumentRef = _firestore.collection('users').doc(uid);
    final userSnapshot = await userDocumentRef.get();
    final userData = userSnapshot.data() as Map<String, dynamic>?;

    if (userData != null) {
      final gender = userData['gender'];
      final queueDocumentRef = _firestore.collection('searchQueue').doc(gender);

      _subscription = queueDocumentRef.snapshots().listen((snapshot) async {
        final searchQueueData = snapshot.data() as Map<String, dynamic>?;
        if (searchQueueData != null &&
            !(searchQueueData['active'] as List).contains(uid)) {
          final partyAQuery = tempChatsRef.where('partyA', isEqualTo: uid);
          final partyBQuery = tempChatsRef.where('partyB', isEqualTo: uid);

          final partyASnapshot = await partyAQuery.get();
          final partyBSnapshot = await partyBQuery.get();

          if (partyASnapshot.size > 0 || partyBSnapshot.size > 0) {
            _subscription?.cancel();
            Navigator.pushNamed(context, '/tempChat');
          }
        }
      });
    }
  }

  @override
  void initState() {
    addToSearchQueue();

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
              }).then((value) {
                Navigator.pushNamed(context, '/home');
              });
            },
            child: const Text('Exit'),
          )
        ],
      ),
    );
  }
}
