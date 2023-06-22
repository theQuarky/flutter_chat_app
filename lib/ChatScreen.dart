import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'TempChatScreen.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.partnerId});
  final String partnerId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

final List<String> conversationSuggestions = [
  "Hey, how's it going?",
  "What are your hobbies?",
  "Tell me about your favorite movie.",
  "Have you been to any interesting places recently?",
  "What's your favorite book?",
];

class _ChatScreenState extends State<ChatScreen> {
  String chatDocId = '';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;
  final TextEditingController _messageController = TextEditingController();
  final functions = FirebaseFunctions.instance;
  Map<String, dynamic>? partner = {};

  // File? _selectedImage;

  // void sendMessage() async {
  //   final text = _messageController.text.trim();
  //   if (text.isEmpty) {
  //     return;
  //   }

  //   final uid = FirebaseAuth.instance.currentUser?.uid;
  //   final chat = {
  //     'sender': uid,
  //     'text': text,
  //     'time': DateTime.now().millisecondsSinceEpoch,
  //   };

  //   final batch = _firestore.batch();

  //   // Update chats collection
  //   final chatDocRef = _firestore.collection('chats').doc(chatDocId);
  //   batch.update(chatDocRef, {
  //     'chats': FieldValue.arrayUnion([chat])
  //   });

  //   // Update partner and user friends simultaneously
  //   final partnerUserDocRef =
  //       _firestore.collection('users').doc(widget.partnerId);

  //   final snapshotList = await _firestore
  //       .collection('users')
  //       .where(FieldPath.documentId, whereIn: [widget.partnerId, uid]).get();

  //   for (final snapshot in snapshotList.docs) {
  //     print("Log A: ");
  //     if (snapshot.exists) {
  //       print("Log B: ");
  //       final _friend = {
  //         'uid': snapshot.id,
  //         'lastMessage': {
  //           'by': uid,
  //           'text': _messageController.text.trim(),
  //           'time': DateTime.now().millisecondsSinceEpoch,
  //           'seen': false,
  //         }
  //       };
  //       final data = snapshot.data();
  //       print("Log C: $data");
  //       List<dynamic> friends = data['friends'] as List;

  //       final updatedFriends = friends.map((friend) {
  //         if (friend['uid'] == snapshot.id) {
  //           return _friend;
  //         }
  //         return friend;
  //       }).toList();

  //       batch.update(snapshot.reference, {'friends': updatedFriends});
  //     }
  //   }

  //   // Commit the batched writes
  //   await batch.commit();

  //   _messageController.clear();

  //   final partnerSnapshot = await partnerUserDocRef.get();
  //   final partnerData = partnerSnapshot.data();

  //   if (partnerData != null && partnerData['deviceToken'] != null) {
  //     final callable = functions.httpsCallable('sendNotification');
  //     await callable.call(<String, dynamic>{
  //       'token': partnerData['deviceToken'],
  //       'title': partnerData['displayName'],
  //       'body': text,
  //       // ignore: body_might_complete_normally_catch_error
  //     }).catchError((err) {
  //       print(err);
  //     });
  //   }
  // }

  void sendMessage(
      {String? mediaUrl = null,
      bool? isImage = false,
      String? extension = ''}) async {
    if (_messageController.text.trim().isEmpty && mediaUrl == null) {
      return;
    }
    var text = mediaUrl != null
        ? {'image': mediaUrl, 'isImage': isImage}
        : _messageController.text.trim();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    final chat = {
      'sender': uid,
      'text': text,
      'time': DateTime.now().millisecondsSinceEpoch,
    };
    await _firestore.collection('chats').doc(chatDocId).update({
      'chats': FieldValue.arrayUnion([chat]),
    });

    DocumentSnapshot<Map<String, dynamic>> partnerSnapshot =
        await _firestore.collection('users').doc(widget.partnerId).get();

    if (partnerSnapshot.exists) {
      final _friend = {
        'uid': uid,
        'lastMessage': {
          'by': uid,
          'text': _messageController.text.trim(),
          'time': DateTime.now().millisecondsSinceEpoch,
          'seen': false,
        }
      };
      final data = partnerSnapshot.data();

      List<dynamic> friends = data!['friends'] as List;

      final updatedFriends = friends.map((friend) {
        if (friend['uid'] == uid) {
          return _friend;
        }
        return friend;
      }).toList();

      await _firestore
          .collection('users')
          .doc(widget.partnerId)
          .update({'friends': updatedFriends});
    }
    DocumentSnapshot<Map<String, dynamic>> userSnapshot =
        await _firestore.collection('users').doc(uid).get();

    if (userSnapshot.exists) {
      final _friend = {
        'uid': widget.partnerId,
        'lastMessage': {
          'by': uid,
          'text': text,
          'time': DateTime.now().millisecondsSinceEpoch,
          'seen': false,
        }
      };
      final data = userSnapshot.data();

      List<dynamic> friends = data!['friends'] as List;

      final updatedFriends = friends.map((friend) {
        if (friend['uid'] == widget.partnerId) {
          return _friend;
        }
        return friend;
      }).toList();

      await _firestore
          .collection('users')
          .doc(uid)
          .update({'friends': updatedFriends});
    }
    _messageController.clear();
    if (partner!['deviceToken'] != null) {
      final callable = functions.httpsCallable('sendNotification');
      callable
          .call(<String, dynamic>{
            'token': partner!['deviceToken'],
            'title': partner!['displayName'],
            'body': text,
          })
          .then((value) async {})
          .catchError((err) {
            print(err);
          });
    }
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

  void readMessage() async {
    _firestore.collection('users').doc(user!.uid).get().then((snapshots) async {
      if (snapshots.exists) {
        final data = snapshots.data();
        List<dynamic> friends = data!['friends'] as List;
        final updatedFriends = friends.map((friend) {
          if (friend['uid'] == widget.partnerId) {
            friend['lastMessage']['seen'] = true;
          }
          return friend;
        }).toList();
        await _firestore
            .collection('users')
            .doc(user!.uid)
            .update({'friends': updatedFriends});
      }
    });
  }

  @override
  void initState() {
    super.initState();
    getPartnerData();
    findChatDoc();
    readMessage();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<String>? uploadImage(String url, String extension) async {
    try {
      print("URL: $url");
      final http.Response response = await http.get(Uri.parse(url));
      final Uint8List imageData = response.bodyBytes;

      // Generate a unique filename for the image (optional)
      String fileName =
          DateTime.now().millisecondsSinceEpoch.toString() + '.' + extension;
      // Create a reference to the Firebase Storage location
      firebase_storage.Reference storageReference =
          firebase_storage.FirebaseStorage.instance.ref().child(fileName);

      // Upload the image data to Firebase Storage
      firebase_storage.UploadTask uploadTask =
          storageReference.putData(imageData);

      // Get the download URL of the uploaded image
      firebase_storage.TaskSnapshot storageSnapshot =
          await uploadTask.whenComplete(() => null);
      String downloadUrl = await storageSnapshot.ref.getDownloadURL();

      // Use the download URL as needed (e.g., save it to a document in Firestore)
      print('Download URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print("ERROR: $e");
      throw e;
    }
  }

  Future _pickImageFromGallery() async {
    final imagePicker = ImagePicker();
    final pickedImage =
        await imagePicker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      final isImage = pickedImage.mimeType?.split('/').first == 'image';
      final extension = pickedImage.mimeType?.split('/').last;
      print(extension);
      final String? imageUrl =
          await uploadImage(pickedImage.path, extension ?? 'png');
      if (imageUrl != null) {
        sendMessage(mediaUrl: imageUrl, isImage: isImage, extension: extension);
      }
    }
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      color: Colors.grey[200],
      child: Container(
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 163, 163, 163),
          borderRadius: BorderRadius.circular(25.0),
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.image),
              onPressed: _pickImageFromGallery,
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                onSubmitted: (e) => sendMessage(),
                decoration: InputDecoration.collapsed(
                  hintText: 'Type a message',
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send),
              onPressed: () {
                // Send message logic goes here
                // String message = _messageController.text;
                sendMessage();
                _messageController.clear();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (chatDocId == '') {
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
                  Navigator.of(context).pop();
                },
                icon: Icon(Icons.arrow_back, color: Colors.black)),
            SizedBox(
              width: 2,
            ),
            CircleAvatar(
              backgroundImage: Image.network(partner?['image'] ?? "").image,
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
                    partner?['displayName'] ?? "",
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
            IconButton(
                onPressed: () {
                  // showPopupMenu(context);
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
              stream: _firestore.collection('chats').doc(chatDocId).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final data = snapshot.data?.data();
                  List<Map<String, dynamic>>? chats =
                      data?['chats']?.cast<Map<String, dynamic>>();

                  chats?.sort((a, b) => b['time'].compareTo(a['time']));

                  return ListView.builder(
                    itemCount: chats?.length ?? 0,
                    reverse: true,
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
                        formattedTime: formattedTime,
                      );
                    },
                  );
                } else {
                  final random = Random();
                  final randomSuggestion = conversationSuggestions[
                      random.nextInt(conversationSuggestions.length)];

                  return Center(
                      child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Ask them something!'),
                      Text(randomSuggestion)
                    ],
                  ));
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildMessageInput(),
            //  Row(
            //   children: [
            //     IconButton(
            //       onPressed: () {},
            //       icon: const Icon(Icons.add),
            //     ),
            //     Expanded(
            //       child: TextField(
            //         controller: _messageController,
            //         decoration: const InputDecoration(
            //           hintText: 'Enter Message',
            //         ),
            //       ),
            //     ),
            //     IconButton(
            //       onPressed: sendMessage,
            //       icon: const Icon(Icons.send),
            //     ),
            //   ],
            // ),
          ),
        ],
      ),
    );
  }
}
