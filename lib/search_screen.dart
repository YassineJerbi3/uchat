import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uchat/chat_provider.dart';
import 'package:uchat/chat_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _auth = FirebaseAuth.instance;
  User? loggedInUser;
  String searchQuery = '';

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

  void handleSearch(String query) {
    setState(() {
      searchQuery = query;
    });
  }

  Stream<List<UserTitle>> _fetchUsers() async* {
    if (searchQuery.isEmpty) {
      yield [];
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: searchQuery)
          .where('name', isLessThanOrEqualTo: searchQuery + '\uf8ff')
          .get();

      final users = snapshot.docs.map((doc) {
        final userData = doc.data() as Map<String, dynamic>;
        if (userData['uid'] != loggedInUser!.uid &&
            userData['name'].contains(searchQuery)) {
          return UserTitle(
            userId: userData['uid'],
            name: userData['name'],
            email: userData['email'],
            imageUrl: userData['imageUrl'],
          );
        } else {
          return null;
        }
      }).whereType<UserTitle>().toSet().toList();

      yield users;
    } catch (e) {
      print('Error fetching users: $e');
      yield [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Search Users"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search Users...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: handleSearch,
            ),
          ),
          Expanded(
            child: StreamBuilder<List<UserTitle>>(
              stream: _fetchUsers(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                final users = snapshot.data!;
                if (users.isEmpty) {
                  return const Center(
                    child: Text("No users found"),
                  );
                }
                return ListView(
                  children: users,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class UserTitle extends StatelessWidget {
  final String userId;
  final String name;
  final String email;
  final String imageUrl;

  const UserTitle({
    super.key,
    required this.userId,
    required this.name,
    required this.email,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(imageUrl),
      ),
      title: Text(name),
      subtitle: Text(email),
      onTap: () async {
        final chatId = await chatProvider.getChatRoom(userId) ??
            await chatProvider.createChatRoom(userId);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: chatId,
              receiverId: userId,
            ),
          ),
        );
      },
    );
  }
}
