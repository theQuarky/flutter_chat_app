import 'package:chat_app/SearchScreen.dart';
import 'package:chat_app/components/ChatTile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FriendListScreen extends StatelessWidget {
  const FriendListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: FriendListStreamWidget(
        firestore: FirebaseFirestore.instance,
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
      ),
    );
  }
}

class FriendListStreamWidget extends StatefulWidget {
  final FirebaseFirestore firestore;
  final String userId;

  const FriendListStreamWidget({
    Key? key,
    required this.firestore,
    required this.userId,
  }) : super(key: key);

  @override
  _FriendListStreamWidgetState createState() => _FriendListStreamWidgetState();
}

class _FriendListStreamWidgetState extends State<FriendListStreamWidget> {
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _friendList = [];
  int _itemsPerPage = 10;
  int _currentMaxItems = 10;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream:
          widget.firestore.collection('users').doc(widget.userId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }

        final friendList =
            (snapshot.data?.data()?['friends'] as List<dynamic>?) ?? [];

        if (friendList.isEmpty) {
          return _buildEmptyFriendList(context);
        }

        friendList.sort(
            (a, b) => b['lastMessage']['time'] - a['lastMessage']['time']);

        _friendList
            .addAll(friendList.map((friend) => friend as Map<String, dynamic>));
        List duplicateHelper = [];
        _friendList.removeWhere((friend) {
          if (duplicateHelper.contains(friend['uid'])) {
            return true;
          }
          duplicateHelper.add(friend['uid']);
          return false;
        });
        return ListView.builder(
          controller: _scrollController,
          itemCount: _friendList.length - 1,
          itemBuilder: (context, index) {
            return _buildFriendTile(_friendList[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyFriendList(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'You don\'t have any friends yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Search for your friends to start chatting',
            style: TextStyle(fontSize: 16),
          ),
          ElevatedButton(
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => SearchScreen())),
            child: const Text("Search"),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendTile(Map<String, dynamic> friend) {
    final friendId = friend['uid'];
    String lastMessage;

    if (friend['lastMessage']?['isImage'] != null) {
      lastMessage = 'Media file';
    } else {
      // Check if 'lastMessage' is a Map and 'text' is a String
      final lastMessageMap = friend['lastMessage'] as Map<String, dynamic>?;
      if (lastMessageMap != null && lastMessageMap['text'] is String) {
        lastMessage = lastMessageMap['text'] ?? "No Message";
      } else {
        lastMessage = 'No message';
      }
    }
    final showUnread = friend['lastMessage']['seen'] == false &&
        friend['lastMessage']['by'] != widget.userId;

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: widget.firestore.collection('users').doc(friendId).get(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox();
        }

        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final friendData = snapshot.data!.data()!;
        // return Text('${friendData['displayName']} : $friendId');
        return ChatTile(
          friendId: friendId,
          avatar: friendData['image'] ?? '',
          friendName: friendData['displayName'],
          showUnread: showUnread,
          lastMessage: lastMessage,
        );
      },
    );
  }
}
