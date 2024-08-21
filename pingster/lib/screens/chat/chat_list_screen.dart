import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/chat_model.dart';
import '../../models/user_model.dart';
import '../../theme.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);

    if (authProvider.user == null) {
      print('Debug: User is null, redirecting to login');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    print('Debug: Building ChatListScreen for user ${authProvider.user!.uid}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        backgroundColor: PingsterTheme.primary200,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
              context.go('/login');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                  _isSearching = _searchQuery.isNotEmpty;
                  print('Debug: Search query updated to $_searchQuery');
                });
              },
            ),
          ),
          Expanded(
            child: _isSearching
                ? FutureBuilder<List<UserModel>>(
                    future: chatProvider.searchUsers(_searchQuery),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('No users found'));
                      }
                      return ListView.builder(
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final user = snapshot.data![index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: user.profilePicture != null
                                  ? NetworkImage(user.profilePicture!)
                                  : null,
                              child: user.profilePicture == null
                                  ? Text(user.username[0].toUpperCase())
                                  : null,
                            ),
                            title: Text(user.fullName),
                            subtitle: Text(user.username),
                            onTap: () async {
                              // Implement starting a new chat
                              String chatId = await chatProvider.createNewChat(
                                  authProvider.user!.uid, user.id);
                              context.push('/chat/$chatId');
                            },
                          );
                        },
                      );
                    },
                  )
                : StreamBuilder<List<Chat>>(
                    stream: chatProvider.getUserChats(authProvider.user!.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('No chats yet'));
                      }
                      return ListView.builder(
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final chat = snapshot.data![index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: chat.otherUserProfilePicture !=
                                      null
                                  ? NetworkImage(chat.otherUserProfilePicture!)
                                  : null,
                              child: chat.otherUserProfilePicture == null
                                  ? Text(chat.otherUserName?[0].toUpperCase() ??
                                      '')
                                  : null,
                            ),
                            title: Text(chat.otherUserName ?? 'Unknown User'),
                            subtitle: Text(
                              chat.lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: chat.unreadCount[
                                            authProvider.user!.uid] !=
                                        null &&
                                    chat.unreadCount[authProvider.user!.uid]! >
                                        0
                                ? CircleAvatar(
                                    backgroundColor: PingsterTheme.accent200,
                                    radius: 12,
                                    child: Text(
                                      chat.unreadCount[authProvider.user!.uid]
                                          .toString(),
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 12),
                                    ),
                                  )
                                : null,
                            onTap: () {
                              context.push('/chat/${chat.id}');
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
        onPressed: () {
          // Implement new chat creation
          print('Debug: New chat button pressed');
        },
        child: const Icon(Icons.add),
        backgroundColor: PingsterTheme.primary200,
      ),
    );
  }
}
