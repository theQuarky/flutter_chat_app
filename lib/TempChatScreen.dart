import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:async/async.dart';

class TempChatScreen extends StatefulWidget {
  const TempChatScreen({Key? key}) : super(key: key);

  @override
  State<TempChatScreen> createState() => _TempChatScreenState();
}

class _TempChatScreenState extends State<TempChatScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _msgController = TextEditingController();
  Map<String, dynamic>? partyA;
  Map<String, dynamic>? partyB;

  Stream<List<Map<String, dynamic>>> combineStreams(
      Stream<QuerySnapshot> streamA, Stream<QuerySnapshot> streamB) async* {
    await for (final snapshot in streamA) {
      yield snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    }
    await for (final snapshot in streamB) {
      yield snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    }
  }

  Stream<List<Map<String, dynamic>>> getMessagesStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final userDocumentRef = _firestore.collection('tempChats');

    final queryA = userDocumentRef.where('partyA', isEqualTo: uid);
    final queryB = userDocumentRef.where('partyB', isEqualTo: uid);

    final streamA = queryA.snapshots().map((snapshot) => snapshot.docs.first);
    final streamB = queryB.snapshots().map((snapshot) => snapshot.docs.first);

    final combinedStream = StreamZip([streamA, streamB]);

    return combinedStream.asyncMap((chats) async {
      final List chatIds = chats.map((chat) => chat['chatId']).toList();
      final List<Stream<QuerySnapshot>> chatStreams = chatIds.map((chatId) {
        return userDocumentRef.doc(chatId).collection('chats').snapshots();
      }).toList();

      final messages = <Map<String, dynamic>>[];

      for (final chatStream in chatStreams) {
        final snapshot = await chatStream.first;
        messages.addAll(
            snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>));
      }

      return messages;
    });
  }

  void findPartner() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final userDocumentRef = _firestore.collection('tempChats');

    final queryA = userDocumentRef.where('partyA', isEqualTo: uid);
    final queryB = userDocumentRef.where('partyB', isEqualTo: uid);

    final snapshotA = await queryA.get();
    final snapshotB = await queryB.get();

    final matchingDocuments = [...snapshotA.docs, ...snapshotB.docs];

    if (matchingDocuments.isNotEmpty) {
      final documentSnapshot = matchingDocuments.first;
      final tempChatData = documentSnapshot.data();
      // Process the tempChatData or perform any desired operations
      // ...

      // Example: Access partyA and partyB values
      final partyAId = tempChatData['partyA'];
      final partyBId = tempChatData['partyB'];

      final partyADoc =
          await _firestore.collection('users').doc(partyAId).get();
      final partyBDoc =
          await _firestore.collection('users').doc(partyBId).get();

      setState(() {
        partyA = partyADoc.data();
        partyB = partyBDoc.data();
      });
    } else {
      // No matching document found
      print('No matching document found');
    }
  }

  void sendMessage() async {
    String message = _msgController.text;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    final userDocumentRef = _firestore.collection('tempChats');

    final queryA = userDocumentRef.where('partyA', isEqualTo: uid);
    final queryB = userDocumentRef.where('partyB', isEqualTo: uid);

    final snapshotA = await queryA.get();
    final snapshotB = await queryB.get();

    final matchingDocuments = [...snapshotA.docs, ...snapshotB.docs];

    if (matchingDocuments.isNotEmpty) {
      final documentSnapshot = matchingDocuments.first;
      final documentReference = documentSnapshot.reference;

      // Retrieve the existing chats array from the document
      List<Map<String, dynamic>>? chats =
          documentSnapshot.data()['chats']?.cast<Map<String, dynamic>>();

      chats ??= [];

      // Create a new chat object
      final chat = {
        'by': uid,
        'text': message,
        'time': DateTime.now(),
      };

      // Add the new chat object to the chats array
      chats.add(chat);

      // Update the document's chats field with the updated chats array
      await documentReference.update({'chats': chats});

      // Optionally, you can also update the document's timestamp field to track the last message timestamp
      await documentReference.update({'timestamp': DateTime.now()});
    } else {
      // No matching document found
      print('No matching document found');
    }
  }

  @override
  void initState() {
    super.initState();
    findPartner();
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? user, partner;
    try {
      if (partyA != null) {
        user = partyA!['uid'] == FirebaseAuth.instance.currentUser?.uid
            ? partyA
            : partyB;
        partner = partyA!['uid'] != FirebaseAuth.instance.currentUser?.uid
            ? partyA
            : partyB;
      } else {
        user = null;
        partner = null;
      }
    } catch (e) {
      user = null;
      partner = null;
    }

    if (user == null || partner == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final _messagesStream = getMessagesStream();

    return Scaffold(
      appBar: AppBar(
        title: Text(user['displayName'] ?? 'Username'),
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Icons.more_vert)),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Chat messages
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final messages = snapshot.data!;
                  return ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isUserMessage = message['sender'] == user!['uid'];

                      return ListTile(
                        title: Text(message['text']),
                        subtitle: Text(
                          isUserMessage ? 'You' : partner!['displayName'],
                        ),
                        trailing: isUserMessage ? null : Icon(Icons.check),
                      );
                    },
                  );
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
              },
            ),
          ),

          // Input field and send button
          Container(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: const InputDecoration(
                      hintText: 'Type your message',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    sendMessage();
                  },
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
