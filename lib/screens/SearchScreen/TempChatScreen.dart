import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chat_app/screens/Chat/ChatScreen.dart';

class TempChatScreen extends StatefulWidget {
  final String matchedUserId;

  const TempChatScreen({Key? key, required this.matchedUserId})
      : super(key: key);

  @override
  _TempChatScreenState createState() => _TempChatScreenState();
}

class _TempChatScreenState extends State<TempChatScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late Timer _timer;
  int _remainingSeconds = 15 * 60; // 15 minutes
  String _matchedUserName = "User";
  String? _currentUserId;
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _startTimer();
    _fetchMatchedUserName();
    _setupMessageListener();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _endChat();
        }
      });
    });
  }

  Future<void> _fetchMatchedUserName() async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(widget.matchedUserId).get();
    if (userDoc.exists) {
      setState(() {
        _matchedUserName = userDoc.get('name') ?? "User";
      });
    }
  }

  void _setupMessageListener() {
    _database
        .child('tempChats/$_currentUserId/${widget.matchedUserId}')
        .onChildAdded
        .listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _messages.add(Map<String, dynamic>.from(event.snapshot.value as Map));
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _endChat() {
    _timer.cancel();
    // Delete chat data
    _database
        .child('tempChats/$_currentUserId/${widget.matchedUserId}')
        .remove();
    _database
        .child('tempChats/${widget.matchedUserId}/$_currentUserId')
        .remove();
    Navigator.of(context).pop();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      final message = {
        'senderId': _currentUserId,
        'text': _messageController.text.trim(),
        'timestamp': ServerValue.timestamp,
      };
      _database
          .child('tempChats/$_currentUserId/${widget.matchedUserId}')
          .push()
          .set(message);
      _database
          .child('tempChats/${widget.matchedUserId}/$_currentUserId')
          .push()
          .set(message);
      _messageController.clear();
    }
  }

  void _addFriend() async {
    // First, check if the other user has already sent a friend request
    DocumentSnapshot currentUserDoc =
        await _firestore.collection('users').doc(_currentUserId).get();
    List<String> pendingFriendRequests =
        List<String>.from(currentUserDoc.get('pendingFriendRequests') ?? []);

    if (pendingFriendRequests.contains(widget.matchedUserId)) {
      // If there's a pending request from the matched user, accept it
      await _firestore.collection('users').doc(_currentUserId).update({
        'friends': FieldValue.arrayUnion([widget.matchedUserId]),
        'pendingFriendRequests': FieldValue.arrayRemove([widget.matchedUserId])
      });
      await _firestore.collection('users').doc(widget.matchedUserId).update({
        'friends': FieldValue.arrayUnion([_currentUserId])
      });

      // Notify the user and navigate to the permanent chat
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Friend added successfully!')));
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => PermanentChatScreen(userId: widget.matchedUserId),
      ));
    } else {
      // If there's no pending request, send a friend request
      await _firestore.collection('users').doc(widget.matchedUserId).update({
        'pendingFriendRequests': FieldValue.arrayUnion([_currentUserId])
      });

      // Notify the user that the request was sent
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Friend request sent!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with $_matchedUserName'),
        actions: [
          FutureBuilder<DocumentSnapshot>(
            future: _firestore.collection('users').doc(_currentUserId).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              }

              List<String> friends =
                  List<String>.from(snapshot.data?.get('friends') ?? []);
              List<String> pendingRequests = List<String>.from(
                  snapshot.data?.get('pendingFriendRequests') ?? []);

              if (friends.contains(widget.matchedUserId)) {
                return Center(
                    child:
                        Text('Friends', style: TextStyle(color: Colors.white)));
              } else if (pendingRequests.contains(widget.matchedUserId)) {
                return TextButton(
                  onPressed: _addFriend,
                  child: Text('Accept Request',
                      style: TextStyle(color: Colors.white)),
                );
              } else {
                return TextButton(
                  onPressed: _addFriend,
                  child:
                      Text('Add Friend', style: TextStyle(color: Colors.white)),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Text(
              'Time remaining: ${_remainingSeconds ~/ 60}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}'),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isCurrentUser = message['senderId'] == _currentUserId;
                return Align(
                  alignment: isCurrentUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isCurrentUser ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message['text'],
                      style: TextStyle(
                          color: isCurrentUser ? Colors.white : Colors.black),
                    ),
                  ),
                );
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
                    decoration: InputDecoration(hintText: 'Type a message...'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _endChat,
            child: Text('End Chat'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
