import 'dart:async';
import 'dart:io';

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
  final _streamController =
      StreamController<DocumentSnapshot<Map<String, dynamic>>>();

  void addToSearchQueue() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userDocumentRef = _firestore.collection('users').doc(uid);
    final userSnapshot = await userDocumentRef.get();
    final userData = userSnapshot.data();
    if (userData == null) return;
    final opGender = userData['gender'] == 'male' ? 'female' : 'male';

    final searchQueueSnapshot =
        await _firestore.collection('searchQueue').doc(opGender).get();

    final data = searchQueueSnapshot.data()?['active'] as List;

    if (data.isEmpty) {
      await _firestore
          .collection('searchQueue')
          .doc(userData['gender'])
          .update({
        'active': FieldValue.arrayUnion([uid])
      });
      listenPicker();
      return;
    }

    final opUid = data[0] as String;

    // writing code to delete document from tempChats collection where partyA or partyB is opUid
    var tempChatsSnapshot = await _firestore
        .collection('tempChats')
        .where('partyA', isEqualTo: opUid)
        .get();

    for (final doc in tempChatsSnapshot.docs) {
      await doc.reference.delete();
    }

    tempChatsSnapshot = await _firestore
        .collection('tempChats')
        .where('partyB', isEqualTo: opUid)
        .get();

    for (final doc in tempChatsSnapshot.docs) {
      await doc.reference.delete();
    }

    _firestore
        .collection('tempChats')
        .add({'partyA': uid, 'partyB': opUid}).then((value) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (builder) => TempChatScreen(
                tempChatDocId: value.id,
              )));
    });
  }

  void listenPicker() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userDocumentRef = _firestore.collection('users').doc(uid);
    final userSnapshot = await userDocumentRef.get();
    final userData = userSnapshot.data();
    if (userData == null) return;

    final partyAQuery = _firestore
        .collection('tempChats')
        .where('partyA', isEqualTo: uid)
        .snapshots();
    final partyBQuery = _firestore
        .collection('tempChats')
        .where('partyB', isEqualTo: uid)
        .snapshots();

    // Listen to changes in the 'partyA' query
    partyAQuery.listen((querySnapshot) {
      for (var documentSnapshot in querySnapshot.docs) {
        _streamController.add(documentSnapshot);
      }
    });

    // Listen to changes in the 'partyB' query
    partyBQuery.listen((querySnapshot) {
      for (var documentSnapshot in querySnapshot.docs) {
        _streamController.add(documentSnapshot);
      }
    });

    // Listen to the merged stream of 'partyA' and 'partyB' queries
    _subscription = _streamController.stream.listen((documentSnapshot) async {
      await _firestore
          .collection('searchQueue')
          .doc(userData['gender'])
          .update({
        'active': FieldValue.arrayRemove([uid])
      });

      // doc
      final data = documentSnapshot.data();
      if (data == null) return;
      final partyA = data['partyA'] as String;
      final partyB = data['partyB'] as String;

      if (partyA == uid || partyB == uid) {
        // Document matches the condition, handle it accordingly
        // For example, you can extract the required data and take action
        // final docId = documentSnapshot.id;
        // final partyAData = data['partyAData'];
        // final partyBData = data['partyBData'];
        // Do something with the data or trigger a callback function
        _subscription?.cancel();
        Navigator.of(context).push(MaterialPageRoute(
            builder: (builder) =>
                TempChatScreen(tempChatDocId: documentSnapshot.id)));
      }
    });
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

  void clean() async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    DocumentReference<Map<String, dynamic>> documentRef =
        _firestore.collection('users').doc(uid ?? '');
    DocumentSnapshot<Map<String, dynamic>> snapshot = await documentRef.get();
    Map<String, dynamic> user = snapshot.data() ?? {};

    documentRef = _firestore.collection('searchQueue').doc(user['gender']);
    _subscription?.cancel();
    documentRef.update({
      'active': FieldValue.arrayRemove([uid]),
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _subscription?.cancel(); // Cancel the stream subscription
    clean();
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
              clean();
              // ignore: use_build_context_synchronously
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => const MainScreen()));
            },
            child: const Text('Exit'),
          ),
          const SizedBox(
            height: 20,
          ),
        ],
      ),
    );
  }
}
