import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chat_app/services/ChatService.dart';
import 'package:chat_app/components/message_bubble.dart';
import 'package:chat_app/components/chat_input.dart';
import 'package:chat_app/components/timer_display.dart';
import 'package:chat_app/screens/Chat/ChatScreen.dart';

class TempChatScreen extends StatefulWidget {
  final String chatId;
  final String matchedUserId;

  const TempChatScreen({
    Key? key,
    required this.chatId,
    required this.matchedUserId,
  }) : super(key: key);

  @override
  _TempChatScreenState createState() => _TempChatScreenState();
}

class _TempChatScreenState extends State<TempChatScreen> {
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Stream<DocumentSnapshot> _chatStream;
  String _matchedUserName = "User";
  bool _isFriend = false;

  @override
  void initState() {
    super.initState();
    _setupChatListener();
    _fetchMatchedUserName();
  }

  void _setupChatListener() {
    _chatStream = _chatService.getTempChatStream(widget.chatId);
    _chatStream.listen((snapshot) {
      if (snapshot.exists) {
        var data = snapshot.data() as Map<String, dynamic>?;
        if (data != null) {
          List<String> friendRequests =
              List<String>.from(data['friendRequest'] ?? []);
          if (friendRequests.contains(widget.matchedUserId) &&
              friendRequests.contains(_auth.currentUser!.uid)) {
            _chatService.moveToPermanentChat(
                widget.chatId, _auth.currentUser!.uid, widget.matchedUserId);
            _navigateToPermanentChat();
          }
        }
      } else {
        print('Chat ended by other user');
        _navigateToSearchScreen();
      }
    });
  }

  void _navigateToPermanentChat() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PermanentChatScreen(
          chatId: widget.chatId,
          friendId: widget.matchedUserId,
        ),
      ),
    );
  }

  Future<void> _fetchMatchedUserName() async {
    String name = await _chatService.getMatchedUserName(widget.matchedUserId);
    setState(() {
      _matchedUserName = name;
    });
  }

  void _addFriend() async {
    try {
      await _chatService.addFriendRequest(
          widget.chatId, _auth.currentUser!.uid);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Friend request sent successfully!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error sending friend request. Please try again.')));
    }
  }

  void _endChat() async {
    try {
      await _chatService.endTempChat(widget.chatId);
      _navigateToSearchScreen();
    } catch (e) {
      print('Error ending chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error ending chat. Please try again.')),
      );
    }
  }

  void _navigateToSearchScreen() {
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _endChat();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_matchedUserName),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'add_friend') {
                  _addFriend();
                } else if (value == 'end_chat') {
                  _endChat();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                if (!_isFriend)
                  const PopupMenuItem<String>(
                    value: 'add_friend',
                    child: Text('Add Friend'),
                  ),
                const PopupMenuItem<String>(
                  value: 'end_chat',
                  child: Text('End Chat'),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            TimerDisplay(chatId: widget.chatId),
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: _chatStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError)
                    return Text('Error: ${snapshot.error}');
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return Center(child: CircularProgressIndicator());
                  if (!snapshot.hasData || !snapshot.data!.exists)
                    return Text('No data available');

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
                      isMe:
                          messages[index]['senderId'] == _auth.currentUser!.uid,
                    ),
                  );
                },
              ),
            ),
            ChatInput(
              onSendMessage: (message) =>
                  _chatService.sendTempMessage(widget.chatId, message),
            ),
          ],
        ),
      ),
    );
  }
}
