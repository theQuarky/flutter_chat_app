import 'package:chat_app/ChatScreen.dart';
import 'package:flutter/material.dart';

class ChatTile extends StatelessWidget {
  const ChatTile({
    super.key,
    required this.friendId,
    required this.avatar,
    required this.friendName,
    required this.showUnread,
    required this.lastMessage,
  });

  final friendId;
  final avatar;
  final String friendName;
  final bool showUnread;
  final String lastMessage;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(partnerId: friendId),
        ),
      ),
      child: ListTile(
          leading: avatar == null || avatar == ""
              ? const CircleAvatar(
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person),
                )
              : CircleAvatar(
                  backgroundImage: Image.network(avatar).image,
                  maxRadius: 20,
                ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    friendName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 5),
                  Icon(
                    Icons.circle,
                    size: 10,
                    color: showUnread ? Colors.green : Colors.transparent,
                  )
                ],
              ),
              SizedBox(height: 5),
              Text(
                lastMessage,
                style: const TextStyle(
                    fontWeight: FontWeight.normal, fontSize: 12),
              )
            ],
          )),
    );
  }
}
