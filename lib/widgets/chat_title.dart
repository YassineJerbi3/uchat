import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uchat/chat_screen.dart'; // Import the intl package

class ChatTitle extends StatelessWidget {
  final String chatId;
  final String lastMessage;
  final DateTime timestamp;
  final Map<String, dynamic> receiverData;

  const ChatTitle({
    super.key,
    required this.chatId,
    required this.lastMessage,
    required this.timestamp,
    required this.receiverData,
  });

  @override
  Widget build(BuildContext context) {
    final String imageUrl = receiverData['imageUrl'] ?? '';
    final String name = receiverData['name'] ?? 'Unknown';

    return lastMessage.isNotEmpty
        ? ListTile(
            leading: CircleAvatar(
              radius: 25,
              backgroundImage: imageUrl.isNotEmpty
                  ? NetworkImage(imageUrl)
                  : AssetImage('assets/default_avatar.png') as ImageProvider,
              onBackgroundImageError: (error, stackTrace) {
                // Handle image loading error if needed
              },
            ),
            title: Text(name),
            subtitle: Text(
              lastMessage,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              DateFormat('HH:mm').format(timestamp), // Use DateFormat to format the timestamp
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    chatId: chatId,
                    receiverId: receiverData['uid'],
                  ),
                ),
              );
            },
          )
        : Container();
  }
}
