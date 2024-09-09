import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream to get all chats for a specific user
  Stream<QuerySnapshot> getChats(String userId) {
    return _firestore
        .collection("chats")
        .where('users', arrayContains: userId)
        .snapshots();
  }

  // Stream to search users based on their email
  Stream<QuerySnapshot> searchUsers(String query) {
    return _firestore
        .collection("users")
        .where('email', isGreaterThanOrEqualTo: query)
        .where('email', isLessThanOrEqualTo: '$query\uf8ff') // Allows partial matching
        .snapshots();
  }

  // Function to send a message in a specific chat
  Future<void> sendMessage(
      String chatId, String message, String receiverId) async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      // Add message to the chat
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': currentUser.uid,
        'receiverId': receiverId,
        'messageBody': message,
        'timestamp': FieldValue.serverTimestamp(), // Correct timestamp spelling
      });

      // Update the chat metadata with the last message
      await _firestore.collection('chats').doc(chatId).set({
        'users': [currentUser.uid, receiverId],
        'lastMessage': message,
        'timestamp': FieldValue.serverTimestamp(), // Correct timestamp spelling
      }, SetOptions(merge: true));
    }
  }

  // Function to get a chat room if it exists between current user and receiver
  Future<String?> getChatRoom(String receiverId) async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      final chatQuery = await _firestore
          .collection("chats")
          .where('users', arrayContains: currentUser.uid)
          .get();
      final chats = chatQuery.docs
          .where((chat) => chat['users'].contains(receiverId))
          .toList();

      if (chats.isNotEmpty) {
        return chats.first.id; // Return the first chat room ID found
      }
    }
    return null;
  }

  // Function to create a new chat room between current user and receiver
  Future<String> createChatRoom(String receiverId) async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      // Create a new chat room
      final chatRoom = await _firestore.collection('chats').add({
        'users': [currentUser.uid, receiverId],
        'lastMessage': '',
        'timestamp': FieldValue.serverTimestamp(), // Correct timestamp spelling
      });

      return chatRoom.id; // Return the newly created chat room ID
    }
    throw Exception('Current user is null');
  }
}
