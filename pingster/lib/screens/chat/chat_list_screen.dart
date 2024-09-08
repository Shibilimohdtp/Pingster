import 'package:flutter/material.dart';
import 'package:pingster/widgets/drawer_menu_item.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _searchQuery = '';
  bool _isSearching = false;
  String _currentFolder = 'All';
  List<String> _folders = ['All', 'Unassigned', 'Work', 'Family', 'Friends'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearching() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);

    if (authProvider.user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return GestureDetector(
      onTap: () {
        if (_isSearching) {
          _stopSearching();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: _buildAppBar(),
        drawer: _buildDrawer(context, authProvider),
        body: _isSearching
            ? _buildSearchResults(chatProvider, authProvider.user!.id)
            : _buildChatList(chatProvider, authProvider.user!.id),
        floatingActionButton: FloatingActionButton(
          onPressed: _startSearch,
          child: const Icon(Icons.add),
          backgroundColor: PingsterTheme.primary200,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 4,
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search chats or users...',
                border: InputBorder.none,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            )
          : const Text('Chats',
              style: TextStyle(
                  color: PingsterTheme.primary200,
                  fontWeight: FontWeight.bold)),
      leading: IconButton(
        icon: Icon(_isSearching ? Icons.arrow_back : Icons.menu,
            color: PingsterTheme.primary200),
        onPressed: _isSearching
            ? _stopSearching
            : () => _scaffoldKey.currentState?.openDrawer(),
      ),
      actions: [
        if (!_isSearching) ...[
          IconButton(
            icon: const Icon(Icons.search, color: PingsterTheme.primary200),
            onPressed: _startSearch,
          ),
          IconButton(
            icon: const Icon(Icons.folder_outlined,
                color: PingsterTheme.primary200),
            onPressed: () => _showFolderSelector(context),
          ),
        ],
      ],
    );
  }

  Widget _buildDrawer(BuildContext context, AuthProvider authProvider) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: const BoxDecoration(
              color: PingsterTheme.primary200,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: authProvider.user?.profilePicture != null
                      ? NetworkImage(authProvider.user!.profilePicture!)
                      : null,
                  child: authProvider.user?.profilePicture == null
                      ? Text(authProvider.user?.fullName[0].toUpperCase() ?? '',
                          style: const TextStyle(
                              fontSize: 24, color: Colors.white))
                      : null,
                ),
                const SizedBox(height: 10),
                Text(
                  authProvider.user?.fullName ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  authProvider.user?.email ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ...drawerMenuItems.map((item) => ListTile(
                leading: Icon(item.icon, color: PingsterTheme.primary200),
                title: Text(item.title),
                onTap: () {
                  Navigator.pop(context);
                  context.push(item.route);
                },
              )),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () => _showLogoutConfirmation(context, authProvider),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(
      BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Logout'),
              onPressed: () async {
                await authProvider.signOut();
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                context.go('/login');
              },
            ),
          ],
        );
      },
    );
  }

  void _showFolderSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Folder'),
          content: SingleChildScrollView(
            child: ListBody(
              children: _folders.map((String folder) {
                return ListTile(
                  title: Text(folder),
                  leading: Icon(
                    folder == _currentFolder
                        ? Icons.folder
                        : Icons.folder_outlined,
                    color: PingsterTheme.primary200,
                  ),
                  onTap: () {
                    setState(() {
                      _currentFolder = folder;
                    });
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchResults(ChatProvider chatProvider, String currentUserId) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        chatProvider.searchUsers(_searchQuery),
        chatProvider.getUserChats(currentUserId).first,
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData) {
          return const Center(child: Text('No results found'));
        }

        List<UserModel> users = snapshot.data![0];
        List<Chat> chats = snapshot.data![1];

        List<Chat> matchingChats = chats
            .where((chat) =>
                chat.otherUserName?.toLowerCase().contains(_searchQuery) ??
                false)
            .toList();

        return ListView(
          children: [
            if (matchingChats.isNotEmpty) ...[
              _buildSectionHeader('Chats'),
              ...matchingChats
                  .map((chat) => _buildChatListTile(chat, currentUserId)),
            ],
            if (users.isNotEmpty) ...[
              _buildSectionHeader('Users'),
              ...users.map((user) =>
                  _buildUserListTile(user, chatProvider, currentUserId)),
            ],
            if (matchingChats.isEmpty && users.isEmpty)
              const Center(child: Text('No results found')),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: PingsterTheme.primary200,
        ),
      ),
    );
  }

  Widget _buildChatList(ChatProvider chatProvider, String currentUserId) {
    return StreamBuilder<List<Chat>>(
      stream: chatProvider.getUserChats(currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No chats yet'));
        }
        return ListView.separated(
          itemCount: snapshot.data!.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final chat = snapshot.data![index];
            return _buildChatListTile(chat, currentUserId);
          },
        );
      },
    );
  }

  Widget _buildChatListTile(Chat chat, String currentUserId) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 28,
        backgroundImage: chat.otherUserProfilePicture != null
            ? NetworkImage(chat.otherUserProfilePicture!)
            : null,
        child: chat.otherUserProfilePicture == null
            ? Text(chat.otherUserName?[0].toUpperCase() ?? '',
                style: const TextStyle(fontSize: 20))
            : null,
      ),
      title: Text(
        chat.otherUserName ?? 'Unknown User',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Row(
        children: [
          _buildLastMessageIcon(chat.lastMessage),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getLastMessageText(chat.lastMessage),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatDate(chat.lastMessageTime),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          if (chat.unreadCount[currentUserId] != null &&
              chat.unreadCount[currentUserId]! > 0)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: PingsterTheme.accent200,
                shape: BoxShape.circle,
              ),
              child: Text(
                chat.unreadCount[currentUserId].toString(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
        ],
      ),
      onTap: () => context.push('/chat/${chat.id}'),
    );
  }

  Widget _buildUserListTile(
      UserModel user, ChatProvider chatProvider, String currentUserId) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 28,
        backgroundImage: user.profilePicture != null
            ? NetworkImage(user.profilePicture!)
            : null,
        child: user.profilePicture == null
            ? Text(user.fullName[0].toUpperCase(),
                style: const TextStyle(fontSize: 20))
            : null,
      ),
      title: Text(user.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(user.username, style: TextStyle(color: Colors.grey[600])),
      onTap: () async {
        String chatId =
            await chatProvider.createNewChat(currentUserId, user.id);
        context.push('/chat/$chatId');
      },
    );
  }

  Widget _buildLastMessageIcon(String lastMessage) {
    if (lastMessage.startsWith('http')) {
      if (lastMessage.endsWith('.mp3') || lastMessage.endsWith('.m4a')) {
        return const Icon(Icons.audiotrack,
            size: 16, color: PingsterTheme.primary200);
      } else if (lastMessage.endsWith('.jpg') ||
          lastMessage.endsWith('.png') ||
          lastMessage.endsWith('.gif')) {
        return const Icon(Icons.image,
            size: 16, color: PingsterTheme.primary200);
      } else if (lastMessage.endsWith('.mp4')) {
        return const Icon(Icons.video_library,
            size: 16, color: PingsterTheme.primary200);
      } else {
        return const Icon(Icons.attach_file,
            size: 16, color: PingsterTheme.primary200);
      }
    }
    return const SizedBox.shrink();
  }

  String _getLastMessageText(String lastMessage) {
    if (lastMessage.startsWith('http')) {
      if (lastMessage.endsWith('.mp3') || lastMessage.endsWith('.m4a')) {
        return 'Audio message';
      } else if (lastMessage.endsWith('.jpg') ||
          lastMessage.endsWith('.png') ||
          lastMessage.endsWith('.gif')) {
        return 'Image';
      } else if (lastMessage.endsWith('.mp4')) {
        return 'Video';
      } else {
        return 'File';
      }
    }
    return lastMessage;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return [
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat',
        'Sun'
      ][date.weekday - 1];
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
