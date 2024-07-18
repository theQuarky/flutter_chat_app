// PermanentChatScreen.dart

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class PermanentChatScreen extends StatefulWidget {
  final String userId;

  const PermanentChatScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _PermanentChatScreenState createState() => _PermanentChatScreenState();
}

class _PermanentChatScreenState extends State<PermanentChatScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Setup message listener
  }

  void _sendMessage() {
    // Implement send message logic
  }

  void _viewProfile() {
    // Implement navigation to user's profile
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
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
            child: ListView(
              controller: _scrollController,
              children: [
                // Implement chat messages list
              ],
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
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
