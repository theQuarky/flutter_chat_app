import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat_app/screens/Chat/TempChatScreen.dart';

class MatchListener {
  StreamSubscription<QuerySnapshot>? _matchListener;

  void listenForNewMatches(BuildContext context, Function stopAnimation) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _matchListener = FirebaseFirestore.instance
          .collection('userChats')
          .where('users', arrayContains: user.uid)
          .snapshots()
          .listen((snapshot) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            _handleNewMatch(context, change.doc, user.uid, stopAnimation);
          }
        }
      }, onError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error occurred while listening to match $error')),
        );
      });
    }
  }

  void _handleNewMatch(BuildContext context, DocumentSnapshot doc,
      String userId, Function stopAnimation) {
    print('New match found: ${doc.id}');
    Map<String, dynamic> chatData = doc.data() as Map<String, dynamic>;
    if (chatData['isPermanent'] != true) {
      String otherUserId =
          (chatData['users'] as List<dynamic>).firstWhere((id) => id != userId);
      stopAnimation();
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => TempChatScreen(
          chatId: doc.id,
          matchedUserId: otherUserId,
        ),
      ));
    }
  }

  void dispose() {
    _matchListener?.cancel();
  }
}
