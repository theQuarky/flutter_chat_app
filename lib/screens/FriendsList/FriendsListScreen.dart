import 'package:chat_app/services/AppStateService.dart';
import 'package:chat_app/services/ChatService.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:chat_app/screens/Chat/ChatScreen.dart';

class FriendsListScreen extends StatefulWidget {
  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
  final ChatService _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    AppState.currentScreen = AppScreen.friendsList;
    AppState.currentChatId = null;
  }

  @override
  void dispose() {
    super.dispose();
    AppState.currentScreen = AppScreen.other;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Friends'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // Navigate to search screen or show search dialog
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _chatService.getUserFriends(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          Map<String, dynamic>? userData =
              snapshot.data?.data() as Map<String, dynamic>?;
          Map<String, dynamic> friends = userData?['friends'] ?? {};

          if (friends.isEmpty) {
            return Center(child: Text('No friends yet. Start chatting!'));
          }

          List<MapEntry<String, dynamic>> sortedFriends = friends.entries
              .toList()
            ..sort((a, b) => (b.value['lastMessageTime'] ?? Timestamp.now())
                .compareTo(a.value['lastMessageTime'] ?? Timestamp.now()));

          return ListView.builder(
            itemCount: sortedFriends.length,
            itemBuilder: (context, index) {
              String friendId = sortedFriends[index].key;
              Map<String, dynamic> friendData = sortedFriends[index].value;

              return FriendListTile(
                friendId: friendId,
                friendData: friendData,
                chatService: _chatService,
              );
            },
          );
        },
      ),
    );
  }
}

class FriendListTile extends StatelessWidget {
  final String friendId;
  final Map<String, dynamic> friendData;
  final ChatService chatService;

  const FriendListTile({
    Key? key,
    required this.friendId,
    required this.friendData,
    required this.chatService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: chatService.getFriendDetailsStream(friendId),
      builder: (context, snapshot) {
        Map<String, dynamic> friendDetails =
            snapshot.data?.data() as Map<String, dynamic>? ?? {};

        return ListTile(
          leading: CircleAvatar(
            backgroundImage:
                NetworkImage(friendDetails['profileImageUrl'] ?? ''),
            child: friendDetails['profileImageUrl'] == null
                ? Text(friendDetails['displayName']?[0] ?? '?')
                : null,
          ),
          title: Text(friendDetails['displayName'] ?? 'Unknown User'),
          subtitle: Text(friendData['lastMessage'] ?? 'No messages yet'),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (friendData['lastMessageTime'] != null)
                Text(
                  _formatDate(friendData['lastMessageTime']),
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              if (friendData['unreadCount'] > 0)
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    friendData['unreadCount'].toString(),
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PermanentChatScreen(
                  chatId: friendData['chatId'],
                  friendId: friendId,
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    DateTime now = DateTime.now();
    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day) {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}
