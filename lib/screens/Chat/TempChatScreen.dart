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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Stream<DocumentSnapshot> _chatStream;
  late Stream<DocumentSnapshot> _friendshipStream;
  String _matchedUserName = "User";
  bool _isFriend = false;

  @override
  void initState() {
    super.initState();
    _setupChatListener();
    _setupFriendshipListener();
    _fetchMatchedUserName();
  }

  void _setupChatListener() {
    _chatStream = _chatService.getChatStream(widget.chatId);
  }

  void _setupFriendshipListener() {
    _friendshipStream =
        _firestore.collection('userChats').doc(widget.chatId).snapshots();
    _friendshipStream.listen((snapshot) {
      if (snapshot.exists) {
        var data = snapshot.data() as Map<String, dynamic>?;
        if (data != null) {
          List<String> friends = List<String>.from(data['friendRequest'] ?? []);
          if (friends.contains(widget.matchedUserId) &&
              friends.contains(_auth.currentUser!.uid)) {
            _chatService.acceptMutualFriendRequest(
                widget.chatId, _auth.currentUser!.uid, widget.matchedUserId);
            _navigateToPermanentChat();
          }
        }
      } else {
        print('chat ended by other user');
        _endChat();
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
      await _chatService.addFriend(widget.chatId, _auth.currentUser!.uid);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Friend added successfully!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding friend. Please try again.')));
    }
  }

  void _endChatButton() {
    _chatService.endChat(widget.chatId);
    Navigator.of(context).pop();
  }

  void _endChat({bool navigateAway = false}) async {
    try {
      await _chatService.endChat(widget.chatId);
      if (!navigateAway) {
        _navigateToSearchScreen();
      }
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
        if (didPop) {
          return;
        }
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
                  _endChatButton();
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
                  _chatService.sendMessage(widget.chatId, message),
            ),
          ],
        ),
      ),
    );
  }
}
