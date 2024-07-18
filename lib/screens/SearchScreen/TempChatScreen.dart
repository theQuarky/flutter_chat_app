// TempChatScreen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:chat_app/screens/Chat/ChatScreen.dart';

class TempChatScreen extends StatefulWidget {
  final String matchedUserId;

  const TempChatScreen({Key? key, required this.matchedUserId}) : super(key: key);

  @override
  _TempChatScreenState createState() => _TempChatScreenState();
}

class _TempChatScreenState extends State<TempChatScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late Timer _timer;
  int _remainingSeconds = 15 * 60; // 15 minutes

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Setup message listener
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

  void _endChat() {
    _timer.cancel();
    // Implement logic to end the chat (e.g., delete chat data, update user statuses)
    Navigator.of(context).pop(); // Return to previous screen
  }

  void _sendMessage() {
    // Implement send message logic
  }

  void _addUser() {
    // Implement logic to add user as a permanent contact
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (context) => PermanentChatScreen(userId: widget.matchedUserId),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Temporary Chat'),
        actions: [
          TextButton(
            onPressed: _addUser,
            child: Text('Add User', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          Text('Time remaining: ${_remainingSeconds ~/ 60}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}'),
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
    _timer.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}