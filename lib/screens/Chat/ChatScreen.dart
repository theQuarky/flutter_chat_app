import 'package:chat_app/components/chat_input_with_media.dart';
import 'package:chat_app/components/message_bubble_with_media.dart';
import 'package:chat_app/services/AppStateService.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chat_app/services/ChatService.dart';
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
    AppState.currentScreen = AppScreen.chat;
    AppState.currentChatId = widget.chatId;
  }

  @override
  void dispose() {
    AppState.currentScreen = AppScreen.other;
    AppState.currentChatId = null;
    super.dispose();
  }

  void _setupChatListener() {
    _chatStream = _chatService.getPermanentChatStream(widget.chatId);
  }

  Future<void> _fetchFriendName() async {
    String name = await _chatService.getMatchedUserName(widget.friendId);
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
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      },
      child: Scaffold(
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
                  if (snapshot.hasError)
                    return Text('Error: ${snapshot.error}');
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
                    itemBuilder: (context, index) => MessageBubbleWithMedia(
                      message: messages[index],
                      isMe:
                          messages[index]['senderId'] == _auth.currentUser!.uid,
                    ),
                  );
                },
              ),
            ),
            ChatInputWithMedia(
              chatId: widget.chatId,
              chatService: _chatService,
              recipientUserId: widget.friendId,
            ),
          ],
        ),
      ),
    );
  }
}
