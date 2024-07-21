// PermanentChatScreen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chat_app/services/ChatService.dart';
import 'package:chat_app/components/message_bubble.dart';
import 'package:chat_app/components/chat_input.dart';
import 'package:chat_app/screens/Profile/ProfileScreen.dart';

class PermanentChatScreen extends StatefulWidget {
  final String chatId;
  final String friendId;

  const PermanentChatScreen({
    Key? key,
    required this.chatId,
    required this.friendId,
  }) : super(key: key);

  @override
  _PermanentChatScreenState createState() => _PermanentChatScreenState();
}

class _PermanentChatScreenState extends State<PermanentChatScreen> {
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Stream<DocumentSnapshot> _chatStream;
  String _friendName = "Friend";

  @override
  void initState() {
    super.initState();
    _setupChatListener();
    _fetchFriendName();
  }

  void _setupChatListener() {
    _chatStream = _chatService.getChatStream(widget.chatId);
  }

  Future<void> _fetchFriendName() async {
    String name = await _chatService.getFriendName(widget.friendId);
    setState(() {
      _friendName = name;
    });
  }

  void _viewProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(userId: widget.friendId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_friendName),
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: _viewProfile,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: _chatStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) return Text('Error: ${snapshot.error}');
                if (snapshot.connectionState == ConnectionState.waiting)
                  return Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || !snapshot.data!.exists)
                  return Text('No messages yet');

                Map<String, dynamic>? data =
                    snapshot.data!.data() as Map<String, dynamic>?;
                List<dynamic> messages = data?['messages'] ?? [];
                messages
                    .sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) => MessageBubble(
                    message: messages[index],
                    isMe: messages[index]['senderId'] == _auth.currentUser!.uid,
                  ),
                );
              },
            ),
          ),
          ChatInput(
            onSendMessage: (message) =>
                _chatService.sendMessage(widget.chatId, message),
          ),
        ],
      ),
    );
  }
}
