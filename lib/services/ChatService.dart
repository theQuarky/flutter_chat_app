import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<DocumentSnapshot> getChatStream(String chatId) {
    return _firestore.collection('userChats').doc(chatId).snapshots();
  }

  Future<String> getMatchedUserName(String userId) async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(userId).get();
    return userDoc.get('displayName') ?? userDoc.get('email') ?? "User";
  }

  Future<void> sendMessage(String chatId, String message) async {
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

  Future<void> addFriend(String chatId, String userId) async {
    try {
      await _firestore.collection('userChats').doc(chatId).set({
        'friendRequest': FieldValue.arrayUnion([userId])
      }, SetOptions(merge: true));

      print(
          'Friend request sent successfully for user: $userId in chat: $chatId');
    } catch (e) {
      print('Error adding friend request: $e');
      throw e;
    }
  }

  Future<void> acceptMutualFriendRequest(
      String chatId, String currentUserId, String friendId) async {
    try {
      // Move the chat to the '_chat' collection
      DocumentSnapshot tempChatDoc =
          await _firestore.collection('userChats').doc(chatId).get();
      Map<String, dynamic> chatData =
          tempChatDoc.data() as Map<String, dynamic>;

      await _firestore.collection('_chat').doc(chatId).set({
        ...chatData,
        'status': 'permanent',
      });

      // Delete the temporary chat
      await _firestore.collection('userChats').doc(chatId).delete();

      // Add friend to each user's document
      await _addFriendToUserCollection(currentUserId, friendId, chatId);
      await _addFriendToUserCollection(friendId, currentUserId, chatId);

      print('Mutual friend request accepted for chat: $chatId');
    } catch (e) {
      print('Error accepting mutual friend request: $e');
      throw e;
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

  Future<void> markMessagesAsRead(String chatId, String friendId) async {
    await _firestore.collection('users').doc(_auth.currentUser!.uid).set({
      'friends': {
        friendId: {
          'unreadCount': 0,
        }
      }
    }, SetOptions(merge: true));
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
    return {
      'displayName': friendDoc['displayName'] ?? 'Unknown User',
      'photoURL': friendDoc['photoURL'] ?? '',
      ...friendDoc.data() as Map<String, dynamic>,
    };
  }

  Future<void> endChat(String chatId) async {
    await _firestore.collection('userChats').doc(chatId).delete();
  }

  // In ChatService.dart

  Future<String> getChatId(String userId1, String userId2) async {
    final chatDoc = await _firestore
        .collection('chats')
        .where('users', arrayContains: userId1)
        .where('users', arrayContains: userId2)
        .limit(1)
        .get();

    if (chatDoc.docs.isNotEmpty) {
      return chatDoc.docs.first.id;
    } else {
      // Create a new chat document if it doesn't exist
      final newChatDoc = await _firestore.collection('chats').add({
        'users': [userId1, userId2],
        'messages': [],
      });
      return newChatDoc.id;
    }
  }

  Future<String> getFriendName(String friendId) async {
    final userDoc = await _firestore.collection('users').doc(friendId).get();
    return userDoc['displayName'] ?? 'Unknown User';
  }
}
