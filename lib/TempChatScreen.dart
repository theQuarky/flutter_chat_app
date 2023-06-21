import 'dart:async';
import 'dart:html' as html;
import 'dart:io';
import 'package:chat_app/HomeScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class TempChatScreen extends StatefulWidget {
  final tempChatDocId;

  TempChatScreen({required String this.tempChatDocId});

  @override
  State<TempChatScreen> createState() => _TempChatScreenState();
}

class _TempChatScreenState extends State<TempChatScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  Map<String, dynamic>? user, partner;

  late Timer _timer;
  int _start = 900; // 15 minutes in seconds

  void endChatListener() {
    _firestore
        .collection('tempChats')
        .doc(widget.tempChatDocId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.data() == null) {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (builder) => HomeScreen()));
      }
    });
  }

  void startTimer() {
    const oneSec = const Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
      (Timer timer) {
        if (_start == 0) {
          _firestore
              .collection('tempChats')
              .doc(widget.tempChatDocId)
              .delete()
              .then((value) {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (builder) => HomeScreen()));
          });
          setState(() {
            timer.cancel();
          });
        } else {
          setState(() {
            _start--;
          });
        }
      },
    );
  }

  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;

    String minutesStr = minutes.toString().padLeft(2, '0');
    String secondsStr = remainingSeconds.toString().padLeft(2, '0');

    return '$minutesStr:$secondsStr';
  }

  void setUsers() async {
    DocumentReference tempChatDoc =
        _firestore.collection('tempChats').doc(widget.tempChatDocId);
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
    print('userId: $userId | partnerId: $partnerId');
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
    await _firestore.collection('tempChats').doc(widget.tempChatDocId).update({
      'chats': FieldValue.arrayUnion([chat]),
    });
    _messageController.clear();
  }

  void addFriend({bool isPermanent = false}) async {
    if (!isPermanent) {
      await _firestore
          .collection('tempChats')
          .doc(widget.tempChatDocId)
          .update({
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
        'lastMessage': {'time': DateTime.now().microsecondsSinceEpoch}
      };

      await userDocRef.update({
        'friends': FieldValue.arrayUnion([friend])
      }).then((value) async {
        Navigator.pushNamed(context, '/home');
      });
    }
  }

  void cleanTempChats() async {
    await _firestore.collection('tempChats').doc(widget.tempChatDocId).delete();
  }

  void showPopupMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Add Friend'),
                onTap: () {
                  Navigator.pop(context, 'Add');
                },
              ),
              ListTile(
                title: Text('End Chat'),
                onTap: () {
                  Navigator.pop(context, 'End');
                },
              ),
            ],
          ),
        );
      },
    ).then((selectedValue) {
      if (selectedValue != null) {
        // Handle the selected value
        switch (selectedValue) {
          case "Add":
            addFriend();
            break;
          case "End":
            cleanTempChats();
            break;
          default:
        }
      }
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _timer.cancel();
    cleanTempChats();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setUsers();
    startTimer();
    endChatListener();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tempChatDocId == '' && user == null && partner == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        flexibleSpace: SafeArea(
            child: Container(
          padding: EdgeInsets.only(right: 16),
          child: Row(children: [
            IconButton(
                onPressed: () {
                  cleanTempChats();
                  Navigator.of(context).pop();
                },
                icon: Icon(Icons.arrow_back, color: Colors.black)),
            SizedBox(
              width: 2,
            ),
            CircleAvatar(
              backgroundImage: NetworkImage('https://robohash.org/$user'),
              maxRadius: 20,
            ),
            SizedBox(
              width: 12,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    "Stranger",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(
                    height: 6,
                  )
                ],
              ),
            ),
            SizedBox(
              width: 2,
            ),
            Text(
              formatTime(_start),
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(
              width: 2,
            ),
            IconButton(
                onPressed: () {
                  showPopupMenu(context);
                },
                icon: Icon(
                  Icons.settings,
                  color: Colors.black54,
                )),
          ]),
        )),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _firestore
                  .collection('tempChats')
                  .doc(widget.tempChatDocId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final data = snapshot.data?.data();
                  List? chats = data?['chats']?.cast<Map<String, dynamic>>();
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

                  chats.sort((a, b) {
                    // sort by time
                    final aTime = a['time'] as int;
                    final bTime = b['time'] as int;
                    return bTime.compareTo(aTime);
                  });

                  return ListView.builder(
                    itemCount: chats.length,
                    reverse: true,
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
  final text;
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
              text is String
                  ? Text(
                      text,
                      style: TextStyle(
                        color: isUserMessage ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  : (text['type'] == 'image'
                      ? Image.network(text['image'])
                      : Container(
                          width: 200,
                          height: 200,
                          child: GestureDetector(
                            onTap: () async {
                              final imageUrl = text['image'];
                              _downloadFile(context, imageUrl);
                            },
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(Icons.download_rounded, size: 64),
                              ],
                            ),
                          ),
                        )),
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

void _downloadFile(BuildContext context, String url) async {
  try {
    final response = await html.HttpRequest.request(url, responseType: 'blob');

    if (response.status == 200) {
      final String dir =
          'filename.extension'; // Specify the desired file name and extension
      html.AnchorElement(
        href: url,
      )
        ..setAttribute('download', dir)
        ..click();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File downloaded successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download file')),
      );
    }
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error downloading file')),
    );
  }
}

// void _downloadFile(BuildContext context, String url) async {
//   try {
//     final httpClient = HttpClient();
//     final request = await httpClient.getUrl(Uri.parse(url));
//     final response = await request.close();
//     if (response.statusCode == HttpStatus.ok) {
//       final bytes = await consolidateHttpClientResponseBytes(response);
//       final String dir = (await getApplicationDocumentsDirectory()).path;
//       final String filePath =
//           '$dir/filename.extension'; // Specify the desired file name and extension

//       File file = File(filePath);
//       await file.writeAsBytes(bytes);

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('File downloaded successfully')),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to download file')),
//       );
//     }
//   } catch (error) {
//     print(error);
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Error downloading file')),
//     );
//   }
// }
