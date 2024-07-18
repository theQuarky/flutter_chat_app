import 'package:flutter/material.dart';

class FriendsListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Friends'),
      ),
      body: Center(
        child: Text(
          'Friends List Placeholder',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
