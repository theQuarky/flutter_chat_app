import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'TempChatScreen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.partnerId});
  final String partnerId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String chatDocId = '';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;
  final TextEditingController _messageController = TextEditingController();
  Map<String, dynamic>? partner = {};
  void sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final chat = {
      'sender': uid,
      'text': text,
      'time': DateTime.now().millisecondsSinceEpoch,
    };
    await _firestore.collection('chats').doc(chatDocId).update({
      'chats': FieldValue.arrayUnion([chat]),
    });
    _messageController.clear();
  }

  void getPartnerData() async {
    try {
      final partnerData = await _firestore
          .collection('users')
          .doc(widget.partnerId)
          .get()
          .then((value) => value.data());

      setState(() {
        partner = partnerData!;
      });
    } catch (e) {
      print(e);
    }
  }

  void findChatDoc() async {
    try {
      Query userDocumentRef = _firestore
          .collection('chats')
          .where('partyA', isEqualTo: user?.uid)
          .where('partyB', isEqualTo: widget.partnerId)
          .limit(1);
      QuerySnapshot snapshot = await userDocumentRef.get();
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          chatDocId = snapshot.docs[0].id;
        });
        return;
      }
      userDocumentRef = _firestore
          .collection('chats')
          .where('partyB', isEqualTo: user?.uid)
          .where('partyA', isEqualTo: widget.partnerId)
          .limit(1);
      snapshot = await userDocumentRef.get();
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          chatDocId = snapshot.docs[0].id;
        });
        return;
      }

      CollectionReference chatDoc = _firestore.collection('chats');

      chatDoc.add({
        'partyA': user?.uid,
        'partyB': widget.partnerId,
        'msg': [],
      }).then((value) {
        setState(() {
          chatDocId = value.id;
        });
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    super.initState();
    print(widget.partnerId);
    getPartnerData();
    findChatDoc();
  }

  @override
  Widget build(BuildContext context) {
    if (chatDocId == '') {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    print(chatDocId);
    return Scaffold(
      appBar: AppBar(
        title: Text(partner!['displayName'] ?? 'User'),
        leading:
            BackButton(onPressed: () => Navigator.pushNamed(context, "/home")),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _firestore.collection('chats').doc(chatDocId).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final data = snapshot.data?.data();
                  final chats = data?['chats']?.cast<Map<String, dynamic>>();

                  return ListView.builder(
                    itemCount: chats?.length ?? 0,
                    itemBuilder: (context, index) {
                      final chat = chats?[index];
                      final sender = chat?['sender'];
                      final text = chat?['text'];
                      final time = chat?['time'];

                      // Format timestamp to a more readable format
                      final formattedTime = DateFormat('HH:mm').format(
                        DateTime.fromMillisecondsSinceEpoch(time),
                      );

                      // Determine if the message is sent by the user or the partner
                      final isUserMessage =
                          sender == FirebaseAuth.instance.currentUser?.uid;

                      return ChatBubble(
                          isUserMessage: isUserMessage,
                          text: text,
                          formattedTime: formattedTime);
                    },
                  );
                } else if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else {
                  return const Center(
                    child: Text('No messages found.'),
                  );
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Enter Message',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: sendMessage,
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
