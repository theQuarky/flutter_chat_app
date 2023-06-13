import 'package:chat_app/ChatScreen.dart';
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
            friendList.sort((a, b) {
              final aTime = (a['lastMessage'] as Timestamp).toDate();
              final bTime = (b['lastMessage'] as Timestamp).toDate();
              return bTime.compareTo(aTime); // Sort in descending order
            });

            print(friendList);

            return ListView.builder(
              itemCount: friendList.length,
              itemBuilder: (context, index) {
                final friendId = friendList[index]['uid'];
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
                          leading: Image.network(
                            avatar,
                            errorBuilder: (context, error, stackTrace) {
                              print('Error loading image: $error');
                              // Provide a fallback image or placeholder
                              return const CircleAvatar(
                                backgroundColor: Colors.grey,
                                child: Icon(Icons.person),
                              );
                            },
                          ),
                          title: Text(
                            friendName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
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
