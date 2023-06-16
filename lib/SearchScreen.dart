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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userDocumentRef = _firestore.collection('users').doc(uid ?? '');
    final userSnapshot = await userDocumentRef.get();
    final userData = userSnapshot.data();

    if (userData != null) {
      final gender = userData['gender'];

      final searchQueueRef = _firestore
          .collection('searchQueue')
          .doc(gender == 'male' ? 'female' : 'male');
      final searchQueueSnapshot = await searchQueueRef.get();
      final searchQueueData = searchQueueSnapshot.data();

      if (searchQueueData != null &&
          (searchQueueData['active'] as List).isEmpty) {
        print("IF");
        // adding self in  searchQueue queue
        _firestore.collection('searchQueue').doc(gender).update({
          'active': FieldValue.arrayUnion([uid])
        });
      } else if (searchQueueData != null) {
        print("ELSE IF");
        final partner = searchQueueData['active'][0] as String;
        final tempChatsRef = _firestore
            .collection('tempChats')
            .where('partner', isEqualTo: partner);

        tempChatsRef.get().then((value) {
          value.docs.forEach((element) async {
            await element.reference.delete();
          });
        });
        print("partner: $partner");
        CollectionReference tempChat = _firestore.collection('tempChats');
        await tempChat.add({'partner': partner, 'me': uid});

        print(await _firestore.collection('tempChats').count());

        Navigator.pushNamed(context, '/tempChat');
      }
    }
  }

  void listenPicker() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final tempChatsRef = _firestore.collection('tempChats');
    final userDocumentRef = _firestore.collection('users').doc(uid);
    final userSnapshot = await userDocumentRef.get();
    final userData = userSnapshot.data();

    if (userData != null) {
      final gender = userData['gender'] == 'male' ? 'female' : 'male';
      final queueDocumentRef = _firestore.collection('searchQueue').doc(gender);

      _subscription?.cancel(); // Cancel the previous listener, if any

      _subscription = queueDocumentRef.snapshots().listen((snapshot) async {
        final searchQueueData = snapshot.data();

        if (searchQueueData != null) {
          final activeUsers = searchQueueData['active'] as List<dynamic>;

          if (!activeUsers.contains(uid)) {
            final partyQueryA = tempChatsRef.where('partyA', isEqualTo: uid);
            final partyQueryB = tempChatsRef.where('partyB', isEqualTo: uid);

            final snapshotA = await partyQueryA.get();
            final snapshotB = await partyQueryB.get();

            if (snapshotA.size > 0 || snapshotB.size > 0) {
              _subscription?.cancel();
              Navigator.pushNamed(context, '/tempChat');
            }
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
