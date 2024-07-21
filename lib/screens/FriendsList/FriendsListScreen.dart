import 'package:chat_app/services/ChatService.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FriendsListScreen extends StatelessWidget {
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Friends')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _chatService.getUserFriends(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Text('Error: ${snapshot.error}');
          if (snapshot.connectionState == ConnectionState.waiting)
            return CircularProgressIndicator();

          Map<String, dynamic>? userData =
              snapshot.data?.data() as Map<String, dynamic>?;
          Map<String, dynamic> friends = userData?['friends'] ?? {};

          return ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context, index) {
              String friendId = friends.keys.elementAt(index);
              Map<String, dynamic> friendData = friends[friendId];

              return FutureBuilder<Map<String, dynamic>>(
                future: _chatService.getFriendDetails(friendId),
                builder: (context, friendSnapshot) {
                  if (friendSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return ListTile(title: Text('Loading...'));
                  }

                  Map<String, dynamic> friendDetails =
                      friendSnapshot.data ?? {};

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          NetworkImage(friendDetails['photoURL'] ?? ''),
                    ),
                    title: Text(friendDetails['displayName'] ?? 'Unknown User'),
                    subtitle:
                        Text(friendData['lastMessage'] ?? 'No messages yet'),
                    trailing: friendData['unreadCount'] > 0
                        ? CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.red,
                            child: Text(
                              friendData['unreadCount'].toString(),
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          )
                        : null,
                    onTap: () {
                      // Navigate to chat screen
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
