import 'package:chat_app/ChatScreen.dart';
import 'package:chat_app/SearchScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FriendListScreen extends StatefulWidget {
  const FriendListScreen({Key? key}) : super(key: key);

  @override
  State<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _firestore.collection('users').doc(user?.uid ?? '').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return const Center(
              child: Text('Something went wrong'),
            );
          } else if (snapshot.hasData) {
            final data = snapshot.data?.data() as Map<String, dynamic>;
            List<dynamic> friendList = data['friends'] ?? [];

            if (friendList.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('You don\'t have any friends yet',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Text('Search for your friends to start chatting',
                        style: TextStyle(fontSize: 16)),
                    ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SearchScreen()));
                        },
                        child: Text("Search"))
                  ],
                ),
              );
            }

            friendList.sort((a, b) {
              return b['lastMessage']['time'] - a['lastMessage']['time'];
            });

            return ListView.builder(
              itemCount: friendList.length,
              itemBuilder: (context, index) {
                final friendId = friendList[index]['uid'];
                var _lastMessage = friendList[index]['lastMessage']['text'];

                final lastMessage =
                    _lastMessage is String ? _lastMessage : "Media file";

                final isSeen =
                    friendList[index]['lastMessage']['seen'] ?? false;

                final showUnread = isSeen == false &&
                    friendList[index]['lastMessage']['by'] != user?.uid;

                return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  future: _firestore.collection('users').doc(friendId).get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    } else if (snapshot.hasError) {
                      return const Center(
                        child: Text('Something went wrong'),
                      );
                    } else if (snapshot.hasData) {
                      final friendData =
                          snapshot.data?.data() as Map<String, dynamic>;
                      final friendName = friendData['displayName'] as String;
                      final avatar = friendData['image'] ?? '';

                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ChatScreen(partnerId: friendId),
                          ),
                        ),
                        child: ListTile(
                            leading: avatar == null || avatar == ""
                                ? const CircleAvatar(
                                    backgroundColor: Colors.grey,
                                    child: Icon(Icons.person),
                                  )
                                : CircleAvatar(
                                    backgroundImage:
                                        Image.network(avatar).image,
                                    maxRadius: 20,
                                  ),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      friendName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 5),
                                    Icon(
                                      Icons.circle,
                                      size: 10,
                                      color: showUnread
                                          ? Colors.green
                                          : Colors.transparent,
                                    )
                                  ],
                                ),
                                SizedBox(height: 5),
                                Text(
                                  lastMessage,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.normal,
                                      fontSize: 12),
                                )
                              ],
                            )),
                      );
                    } else {
                      return const Center(
                        child: Text('You don\'t have any friends!'),
                      );
                    }
                  },
                );
              },
            );
          } else {
            return const Center(
              child: Text('You don\'t have any friends!'),
            );
          }
        },
      ),
    );
  }
}
