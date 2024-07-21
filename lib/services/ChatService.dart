import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Temporary Chat Methods
  Stream<DocumentSnapshot> getTempChatStream(String chatId) {
    return _firestore.collection('userChats').doc(chatId).snapshots();
  }

  Future<void> sendTempMessage(String chatId, String message) async {
    final messageData = {
      'senderId': _auth.currentUser!.uid,
      'text': message,
      'timestamp': Timestamp.now(),
    };

    await _firestore.collection('userChats').doc(chatId).set({
      'messages': FieldValue.arrayUnion([messageData]),
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> addFriendRequest(String chatId, String userId) async {
    await _firestore.collection('userChats').doc(chatId).set({
      'friendRequest': FieldValue.arrayUnion([userId])
    }, SetOptions(merge: true));
  }

  Future<void> endTempChat(String chatId) async {
    await _firestore.collection('userChats').doc(chatId).delete();
  }

  // Permanent Chat Methods
  Future<void> moveToPermanentChat(
      String chatId, String currentUserId, String friendId) async {
    DocumentSnapshot tempChatDoc =
        await _firestore.collection('userChats').doc(chatId).get();
    Map<String, dynamic> chatData = tempChatDoc.data() as Map<String, dynamic>;

    await _firestore.collection('_chat').doc(chatId).set({
      ...chatData,
      'status': 'permanent',
    });

    await _firestore.collection('userChats').doc(chatId).delete();

    await _addFriendToUserCollection(currentUserId, friendId, chatId);
    await _addFriendToUserCollection(friendId, currentUserId, chatId);
  }

  Stream<DocumentSnapshot> getPermanentChatStream(String chatId) {
    return _firestore.collection('_chat').doc(chatId).snapshots();
  }

  Future<void> sendPermanentMessage(String chatId, String message) async {
    final messageData = {
      'senderId': _auth.currentUser!.uid,
      'text': message,
      'timestamp': Timestamp.now(),
    };

    await _firestore.collection('_chat').doc(chatId).set({
      'messages': FieldValue.arrayUnion([messageData]),
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _updateFriendsLastMessage(chatId, message);
  }

  Future<void> sendMediaMessage(
      String chatId, String mediaUrl, String mediaType) async {
    final messageData = {
      'senderId': _auth.currentUser!.uid,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'timestamp': Timestamp.now(),
    };

    await _firestore.collection('_chat').doc(chatId).set({
      'messages': FieldValue.arrayUnion([messageData]),
      'lastMessage': 'Sent a $mediaType',
      'lastMessageTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _updateFriendsLastMessage(chatId, 'Sent a $mediaType');
  }

  Future<void> _updateFriendsLastMessage(
      String chatId, String lastMessage) async {
    DocumentSnapshot chatDoc =
        await _firestore.collection('_chat').doc(chatId).get();
    List<String> users = List<String>.from(chatDoc['users']);

    for (String userId in users) {
      String friendId = users.firstWhere((id) => id != userId);
      await _firestore.collection('users').doc(userId).set({
        'friends': {
          friendId: {
            'chatId': chatId,
            'lastMessage': lastMessage,
            'lastMessageTime': FieldValue.serverTimestamp(),
            'unreadCount':
                userId == _auth.currentUser!.uid ? 0 : FieldValue.increment(1),
          }
        }
      }, SetOptions(merge: true));
    }
  }

  Future<void> _addFriendToUserCollection(
      String userId, String friendId, String chatId) async {
    await _firestore.collection('users').doc(userId).set({
      'friends': {
        friendId: {
          'chatId': chatId,
          'lastMessage': '',
          'lastMessageTime': null,
          'unreadCount': 0,
        }
      }
    }, SetOptions(merge: true));
  }

  Future<void> markMessagesAsRead(String friendId) async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(_auth.currentUser!.uid).get();
    Map<String, dynamic> friends = userDoc['friends'] ?? {};

    if (friends.containsKey(friendId)) {
      String chatId = friends[friendId]['chatId'];

      await _firestore.collection('users').doc(_auth.currentUser!.uid).set({
        'friends': {
          friendId: {
            'unreadCount': 0,
          }
        }
      }, SetOptions(merge: true));
    }
  }

  Stream<DocumentSnapshot> getUserFriends() {
    return _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .snapshots();
  }

  Future<Map<String, dynamic>> getFriendDetails(String friendId) async {
    DocumentSnapshot friendDoc =
        await _firestore.collection('users').doc(friendId).get();
    if (friendDoc.exists) {
      Map<String, dynamic> friendData =
          friendDoc.data() as Map<String, dynamic>;
      return {
        'displayName': friendData['displayName'] ?? 'Unknown User',
        'photoURL': friendData['profileImageUrl'] ?? '',
        ...friendData,
      };
    }
    return {
      'displayName': 'Deleted Profile',
      'photoURL': '',
    };
  }

  Future<String> getMatchedUserName(String userId) async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(userId).get();
    return userDoc.get('displayName') ?? userDoc.get('email') ?? "User";
  }

  Stream<DocumentSnapshot> getFriendDetailsStream(String friendId) {
    return _firestore.collection('users').doc(friendId).snapshots();
  }

  Future<String> uploadMedia(File file, String chatId, String mediaType) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference ref = _storage.ref().child('chat_media/$chatId/$fileName');

    // Create a temporary message with isUploading flag
    String tempMessageId = await _createTempMessage(chatId, mediaType);

    UploadTask uploadTask = ref.putFile(file);

    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      // Update progress if needed
    });

    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();

    // Update the message with the download URL and set isUploading to false
    await _updateMessageAfterUpload(chatId, tempMessageId, downloadUrl);

    return downloadUrl;
  }

  Future<String> _createTempMessage(String chatId, String mediaType) async {
    DocumentReference messageRef = await _firestore
        .collection('_chat')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': _auth.currentUser!.uid,
      'mediaType': mediaType,
      'isUploading': true,
      'timestamp': FieldValue.serverTimestamp(),
    });
    return messageRef.id;
  }

  Future<void> _updateMessageAfterUpload(
      String chatId, String messageId, String mediaUrl) async {
    await _firestore
        .collection('_chat')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'mediaUrl': mediaUrl,
      'isUploading': false,
    });
  }
}
