import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uchat/chat_provider.dart';
import 'package:uchat/login_screen.dart';
import 'package:uchat/search_screen.dart';
import 'package:uchat/widgets/chat_title.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = FirebaseAuth.instance;
  User? loggedInUser;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        loggedInUser = user;
      });
    }
  }

  Future<Map<String, dynamic>> _fetchChatData(String chatID) async {
    try {
      final chatDoc =
          await FirebaseFirestore.instance.collection('chats').doc(chatID).get();
      final chatData = chatDoc.data();
      if (chatData == null) {
        throw Exception('Chat data not found');
      }
      final users = chatData['users'] as List<dynamic>;
      final receiverId = users.firstWhere((id) => id != loggedInUser!.uid);
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(receiverId)
          .get();
      final userData = userDoc.data();
      return {
        'chatId': chatID,
        'lastMessage': chatData['lastMessage'] ?? '',
        'timestamp': chatData['timestamp']?.toDate() ?? DateTime.now(),
        'userData': userData,
      };
    } catch (error) {
      // Handle errors here
      print('Error fetching chat data: $error');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    return WillPopScope(
      onWillPop: () async => false, // Prevent going back from HomeScreen
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("Chats"),
          actions: [
            IconButton(
              onPressed: () async {
                await _auth.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: chatProvider.getChats(loggedInUser!.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('No chats available'),
                    );
                  }
                  final chatDocs = snapshot.data!.docs;
                  return FutureBuilder<List<Map<String, dynamic>>>(
                    future: Future.wait(
                      chatDocs.map((chatDoc) => _fetchChatData(chatDoc.id)),
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}'),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text('No chat data available'),
                        );
                      }
                      final chatDataList = snapshot.data!;
                      return ListView.builder(
                        itemCount: chatDataList.length,
                        itemBuilder: (context, index) {
                          final chatData = chatDataList[index];
                          return ChatTitle(
                            chatId: chatData['chatId'],
                            lastMessage: chatData['lastMessage'],
                            timestamp: chatData['timestamp'],
                            receiverData: chatData['userData'],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF3876FD),
          foregroundColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SearchScreen(),
              ),
            );
          },
          child: const Icon(Icons.search),
        ),
      ),
    );
  }
}
