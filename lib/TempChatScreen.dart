import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TempChatScreen extends StatefulWidget {
  const TempChatScreen({Key? key}) : super(key: key);

  @override
  State<TempChatScreen> createState() => _TempChatScreenState();
}

class _TempChatScreenState extends State<TempChatScreen> {
  String tempChatDocId = '';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  Map<String, dynamic>? user, partner;

  void setUsers() async {
    DocumentReference tempChatDoc =
        _firestore.collection('tempChats').doc(tempChatDocId);
    DocumentSnapshot snapshot = await tempChatDoc.get();
    Map<String, dynamic> data = (snapshot.data() ?? {}) as Map<String, dynamic>;

    String userId, partnerId;

    if (FirebaseAuth.instance.currentUser?.uid == data['partyA']) {
      userId = data['partyA'];
      partnerId = data['partyB'];
    } else {
      userId = data['partyB'];
      partnerId = data['partyA'];
    }

    DocumentReference usersDoc = _firestore.collection('users').doc(userId);
    DocumentSnapshot userSnapshot = await usersDoc.get();
    Map<String, dynamic> userData =
        (userSnapshot.data() ?? {}) as Map<String, dynamic>;
    userData['uid'] = userId;
    DocumentReference partnerDoc =
        _firestore.collection('users').doc(partnerId);
    DocumentSnapshot partnerSnapshot = await partnerDoc.get();
    Map<String, dynamic> partnerData =
        (partnerSnapshot.data() ?? {}) as Map<String, dynamic>;
    partnerData['uid'] = partnerId;
    setState(() {
      user = userData;
      partner = partnerData;
    });
  }

  void findTempChatDocId() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      Query userDocumentRef = _firestore
          .collection('tempChats')
          .where('partyA', isEqualTo: uid)
          .limit(1);
      QuerySnapshot snapshot = await userDocumentRef.get();
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        setState(() {
          tempChatDocId = doc.id;
        });
        setUsers();
        return;
      }
      userDocumentRef = FirebaseFirestore.instance
          .collection('tempChats')
          .where('partyB', isEqualTo: uid)
          .limit(1);
      snapshot = await userDocumentRef.get();
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        setState(() {
          tempChatDocId = doc.id;
        });
        setUsers();
        return;
      }
    } catch (e) {
      print('TempChatScreen $e');
    }
  }

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
    await _firestore.collection('tempChats').doc(tempChatDocId).update({
      'chats': FieldValue.arrayUnion([chat]),
    });
    _messageController.clear();
  }

  void addFriend({bool isPermanent = false}) async {
    if (!isPermanent) {
      await _firestore.collection('tempChats').doc(tempChatDocId).update({
        'isFriend': FieldValue.arrayUnion(
            [FirebaseAuth.instance.currentUser?.uid as String]),
      });
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;

// Get the user document reference
    final userDocRef = _firestore.collection('users').doc(uid);
    final userDocSnapshot = await userDocRef.get();

// Retrieve the current friends array
    final friends = userDocSnapshot.data()?['friends'] ?? [];

// Check if the friend already exists in the friends array
    final friendExists =
        friends.any((friend) => friend['uid'] == partner!['uid']);

    if (!friendExists) {
      cleanTempChats();

      // Friend does not exist, add the friend to the friends array
      final friend = {
        'uid': partner!['uid'],
        'lastMessage': {'time': DateTime.now()}
      };

      await userDocRef.update({
        'friends': FieldValue.arrayUnion([friend])
      }).then((value) async {
        Navigator.pushNamed(context, '/home');
      });
    }
  }

  void cleanTempChats() async {
    await _firestore.collection('tempChats').doc(tempChatDocId).delete();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    cleanTempChats();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    findTempChatDocId();
  }

  @override
  Widget build(BuildContext context) {
    if (tempChatDocId == '' && user == null && partner == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    print('User: $user');
    print('Partner: $partner');

    return Scaffold(
      appBar: AppBar(
        title: Text(partner?['displayName'] ?? ''),
        leading: BackButton(onPressed: () {
          cleanTempChats();
          Navigator.pushNamed(context, "/home");
        }),
        actions: [
          GestureDetector(
            onTap: addFriend,
            child: Container(
              margin: const EdgeInsets.only(right: 16.0),
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: const [
                  Icon(Icons.add),
                  SizedBox(width: 6.0),
                  Text(
                    'Add Friend',
                    style: TextStyle(fontSize: 16.0),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _firestore
                  .collection('tempChats')
                  .doc(tempChatDocId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final data = snapshot.data?.data();
                  final chats = data?['chats']?.cast<Map<String, dynamic>>();

                  if (data != null && data['isFriend'] != null) {
                    List isFriend = data['isFriend'] as List;

                    if (isFriend.contains(user!['uid']) &&
                        isFriend.contains(partner!['uid'])) {
                      final name = partner!['displayName'];
                      addFriend(isPermanent: true);
                      return Center(
                        child: Text(
                          'You both are friends now!! You can check $name on your home page',
                        ),
                      );
                    }
                  }

                  if (chats == null || chats.isEmpty) {
                    return const Center(
                      child: Text('No chat found!'),
                    );
                  }

                  return ListView.builder(
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      final chat = chats[index];
                      final sender = chat['sender'];
                      final text = chat['text'];
                      final time = chat['time'];

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
                        formattedTime: formattedTime,
                      );
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

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.isUserMessage,
    required this.text,
    required this.formattedTime,
  });

  final bool isUserMessage;
  final String text;
  final String formattedTime;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Align(
        alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: isUserMessage ? Colors.blue : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text ?? '',
                style: TextStyle(
                  color: isUserMessage ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                formattedTime,
                style: TextStyle(
                  color: isUserMessage ? Colors.white70 : Colors.grey.shade600,
                  fontSize: 12.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
