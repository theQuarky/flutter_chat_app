import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat_app/screens/Profile/ProfileEditScreen.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;

  ProfileScreen({Key? key, this.userId}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? userData;
  bool isCurrentUser = false;

  @override
  void initState() {
    super.initState();
    isCurrentUser =
        widget.userId == null || widget.userId == _auth.currentUser?.uid;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    String uid = widget.userId ?? _auth.currentUser!.uid;
    DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
    setState(() {
      userData = doc.data() as Map<String, dynamic>?;
    });
  }

  void _editProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfileEditScreen()),
    ).then((_) => _loadUserData());
  }

  void _logout() async {
    await _auth.signOut();
    Navigator.of(context).pushReplacementNamed('/auth');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: userData == null
          ? Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 200.0,
                  floating: false,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Image.network(
                      userData!['profileImageUrl'] ??
                          'https://via.placeholder.com/400x200',
                      fit: BoxFit.cover,
                    ),
                  ),
                  actions: isCurrentUser
                      ? [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: _editProfile,
                          ),
                          IconButton(
                            icon: Icon(Icons.logout),
                            onPressed: _logout,
                          ),
                        ]
                      : null,
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userData!['displayName'] ?? 'No Name',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        if (isCurrentUser)
                          Text(
                            _auth.currentUser?.email ?? 'No Email',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        SizedBox(height: 16),
                        Text(
                          userData!['bio'] ?? 'No bio available',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(Icons.cake, size: 20, color: Colors.grey),
                            SizedBox(width: 8),
                            Text(
                              userData!['birthDate'] != null
                                  ? 'Born ${userData!['birthDate'].toDate().toString().split(' ')[0]}'
                                  : 'Birth date not set',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              userData!['gender'] == 'Male'
                                  ? Icons.male
                                  : Icons.female,
                              size: 20,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 8),
                            Text(
                              userData!['gender'] ?? 'Gender not set',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
