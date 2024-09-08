import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/chat_message_model.dart';
import '../../theme.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;

  const ChatScreen({Key? key, required this.chatId}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _messageKeys = {};
  final TextEditingController _searchController = TextEditingController();

  bool _isRecording = false;
  String _otherUserName = 'Chat';
  String? _otherUserId;
  String? _otherUserProfilePicture;
  bool _isTyping = false;
  Timer? _typingTimer;
  ChatMessage? _replyingTo;
  ChatMessage? _editingMessage;
  List<ChatMessage> _pinnedMessages = [];
  String? _chatTheme;
  bool _isBlocked = false;
  bool _isSearching = false;
  String _searchQuery = '';

  String? _currentlyPlayingUrl;
  final Map<String, ValueNotifier<Duration>> _audioPositions = {};
  final Map<String, ValueNotifier<Duration>> _audioDurations = {};
  final Map<String, StreamSubscription?> _playerSubscriptions = {};
  final Map<String, bool> _isPlaying = {};

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    await _loadOtherUserInfo();
    await _markMessagesAsRead();
    await _initRecorder();
    await _initPlayer();
    _listenToTypingStatus();
    _loadPinnedMessages();
    _loadChatTheme();
    _checkBlockStatus();
    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> _initPlayer() async {
    await _player.openPlayer();
    _player.setSubscriptionDuration(const Duration(milliseconds: 100));
  }

  Future<void> _loadOtherUserInfo() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final chats = await chatProvider.getUserChats(authProvider.user!.id).first;
    final chat = chats.firstWhere((c) => c.id == widget.chatId);
    _otherUserId =
        chat.participants.firstWhere((id) => id != authProvider.user!.id);
    setState(() {
      _otherUserName = chat.otherUserName ?? 'Unknown User';
      _otherUserProfilePicture = chat.otherUserProfilePicture;
    });
  }

  void _listenToTypingStatus() {
    if (_otherUserId == null) return;
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider
        .getTypingStatus(widget.chatId, _otherUserId!)
        .listen((isTyping) {
      if (mounted) {
        setState(() {
          _isTyping = isTyping;
        });
      }
    });
  }

  Future<void> _markMessagesAsRead() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    await chatProvider.markMessagesAsRead(widget.chatId, authProvider.user!.id);
  }

  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw 'Microphone permission not granted';
    }
    await _recorder.openRecorder();
  }

  Future<void> _pickAndSendFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'mp4', 'mp3', 'm4a'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);

      if (await file.length() > 10 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File size must be less than 10 MB')),
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Uploading file..."),
              ],
            ),
          );
        },
      );

      try {
        String fileUrl = await Provider.of<ChatProvider>(context, listen: false)
            .uploadFile(file);

        MessageType messageType;
        if (fileUrl.endsWith('.jpg') ||
            fileUrl.endsWith('.jpeg') ||
            fileUrl.endsWith('.png') ||
            fileUrl.endsWith('.gif')) {
          messageType = MessageType.image;
        } else if (fileUrl.endsWith('.mp4')) {
          messageType = MessageType.video;
        } else if (fileUrl.endsWith('.mp3') || fileUrl.endsWith('.m4a')) {
          messageType = MessageType.audio;
        } else {
          messageType = MessageType.file;
        }

        await _sendMessage(fileUrl, messageType);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload file: $e')),
        );
      } finally {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _toggleRecording() async {
    if (!_isRecording) {
      try {
        await _recorder.startRecorder(toFile: 'temp_audio.aac');
        setState(() {
          _isRecording = true;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start recording: $e')),
        );
      }
    } else {
      try {
        final path = await _recorder.stopRecorder();
        setState(() {
          _isRecording = false;
        });
        if (path != null) {
          File audioFile = File(path);
          if (await audioFile.length() > 10 * 1024 * 1024) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Audio file size must be less than 10 MB')),
            );
            return;
          }
          String audioUrl =
              await Provider.of<ChatProvider>(context, listen: false)
                  .uploadFile(audioFile);
          await _sendMessage(audioUrl, MessageType.audio);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to stop recording: $e')),
        );
      }
    }
  }

  Future<void> _playAudio(String url, String messageId) async {
    if (_currentlyPlayingUrl == url) {
      if (_isPlaying[messageId] ?? false) {
        await _player.pausePlayer();
      } else {
        await _player.resumePlayer();
      }
    } else {
      if (_player.isPlaying) {
        await _player.stopPlayer();
        _playerSubscriptions[_currentlyPlayingUrl!]?.cancel();
      }

      try {
        await _player.startPlayer(
          fromURI: url,
          whenFinished: () {
            setState(() {
              _currentlyPlayingUrl = null;
              _isPlaying[messageId] = false;
            });
            _audioPositions[messageId]?.value = Duration.zero;
          },
        );

        _currentlyPlayingUrl = url;

        _playerSubscriptions[messageId] = _player.onProgress!.listen((event) {
          _audioPositions[messageId]?.value = event.position;
          _audioDurations[messageId]?.value = event.duration;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to play audio: $e')),
        );
      }
    }

    setState(() {
      _isPlaying[messageId] = !(_isPlaying[messageId] ?? false);
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  Future<void> _openFile(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the file')),
      );
    }
  }

  void _showMediaViewer(String url, MessageType type) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => MediaViewerScreen(url: url, type: type),
    ));
  }

  Future<void> _loadPinnedMessages() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    _pinnedMessages = await chatProvider.getPinnedMessages(widget.chatId);
    setState(() {});
  }

  Future<void> _loadChatTheme() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    _chatTheme = await chatProvider.getChatTheme(widget.chatId);
    setState(() {});
  }

  Future<void> _checkBlockStatus() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    _isBlocked = await chatProvider.isUserBlocked(widget.chatId, _otherUserId!);
    setState(() {});
  }

  Future<void> _sendMessage(String content, MessageType type) async {
    if (content.isNotEmpty) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);

      ChatMessage message = ChatMessage(
        id: '',
        senderId: authProvider.user!.id,
        content: content,
        timestamp: DateTime.now(),
        type: type,
        replyTo: _replyingTo?.id,
      );

      try {
        if (_editingMessage != null) {
          if (DateTime.now().difference(_editingMessage!.timestamp).inMinutes <=
              15) {
            await chatProvider.editMessage(
                widget.chatId, _editingMessage!, content);
            setState(() {
              _editingMessage = null;
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'Messages can only be edited within 15 minutes of sending')),
            );
          }
        } else {
          await chatProvider.sendMessage(widget.chatId, message);
        }

        _messageController.clear();
        setState(() {
          _replyingTo = null;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  Future<void> _sendSecretMessage(
      String content, MessageType type, Duration expirationDuration) async {
    if (content.isNotEmpty) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);

      ChatMessage message = ChatMessage(
        id: '',
        senderId: authProvider.user!.id,
        content: content,
        timestamp: DateTime.now(),
        type: type,
        isSecret: true,
      );

      try {
        await chatProvider.sendSecretMessage(
            widget.chatId, message, expirationDuration);
        _messageController.clear();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send secret message: $e')),
        );
      }
    }
  }

  void _showMessageOptions(ChatMessage message) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!message.isSecret &&
                DateTime.now().difference(message.timestamp).inMinutes <= 15)
              ListTile(
                leading:
                    const Icon(Icons.edit, color: PingsterTheme.primary200),
                title: const Text('Edit Message'),
                onTap: () {
                  Navigator.pop(context);
                  _startEditingMessage(message);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Message'),
              onTap: () {
                Navigator.pop(context);
                _deleteMessage(message);
              },
            ),
            if (!message.isPinned && _pinnedMessages.length < 3)
              ListTile(
                leading:
                    const Icon(Icons.push_pin, color: PingsterTheme.primary200),
                title: const Text('Pin Message'),
                onTap: () {
                  Navigator.pop(context);
                  _pinMessage(message);
                },
              ),
            if (message.isPinned)
              ListTile(
                leading: const Icon(Icons.push_pin_outlined,
                    color: PingsterTheme.primary200),
                title: const Text('Unpin Message'),
                onTap: () {
                  Navigator.pop(context);
                  _unpinMessage(message);
                },
              ),
          ],
        );
      },
    );
  }

  void _startEditingMessage(ChatMessage message) {
    setState(() {
      _editingMessage = message;
      _messageController.text = message.content;
    });
  }

  Future<void> _deleteMessage(ChatMessage message) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    try {
      await chatProvider.deleteMessage(widget.chatId, message.id);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete message: $e')),
      );
    }
  }

  Future<void> _pinMessage(ChatMessage message) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    try {
      await chatProvider.pinMessage(widget.chatId, message.id);
      _loadPinnedMessages();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pin message: $e')),
      );
    }
  }

  Future<void> _unpinMessage(ChatMessage message) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    try {
      await chatProvider.unpinMessage(widget.chatId, message.id);
      _loadPinnedMessages();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to unpin message: $e')),
      );
    }
  }

  Widget _buildAudioMessageContent(String audioUrl, String messageId) {
    if (!_audioPositions.containsKey(messageId)) {
      _audioPositions[messageId] = ValueNotifier(Duration.zero);
      _audioDurations[messageId] = ValueNotifier(Duration.zero);
      _isPlaying[messageId] = false;
    }

    return Container(
      width: 280,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Audio Message',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: Icon(
                    _isPlaying[messageId]! ? Icons.pause : Icons.play_arrow),
                onPressed: () => _playAudio(audioUrl, messageId),
                color: PingsterTheme.primary200,
              ),
              Expanded(
                child: ValueListenableBuilder<Duration>(
                  valueListenable: _audioPositions[messageId]!,
                  builder: (context, position, _) {
                    return ValueListenableBuilder<Duration>(
                      valueListenable: _audioDurations[messageId]!,
                      builder: (context, duration, _) {
                        return Slider(
                          value: position.inMilliseconds.toDouble(),
                          max: duration.inMilliseconds.toDouble(),
                          onChanged: (value) {
                            _player.seekToPlayer(
                                Duration(milliseconds: value.toInt()));
                          },
                          activeColor: PingsterTheme.primary200,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ValueListenableBuilder<Duration>(
                  valueListenable: _audioPositions[messageId]!,
                  builder: (context, position, _) {
                    return Text(_formatDuration(position));
                  },
                ),
                ValueListenableBuilder<Duration>(
                  valueListenable: _audioDurations[messageId]!,
                  builder: (context, duration, _) {
                    return Text(_formatDuration(duration));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    _messageKeys[message.id] = GlobalKey();

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        key: _messageKeys[message.id],
        onTap: message.replyTo != null
            ? () => _scrollToMessage(message.replyTo!)
            : null,
        onLongPress: () => _showMessageOptions(message),
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! < 0) {
            setState(() {
              _replyingTo = message;
            });
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: message.isSecret
                ? Colors.red[100]
                : (isMe ? PingsterTheme.primary100 : Colors.grey[200]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.isPinned)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.push_pin, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('Pinned',
                          style:
                              TextStyle(fontSize: 10, color: Colors.grey[600])),
                    ],
                  ),
                ),
              if (message.replyTo != null)
                GestureDetector(
                  onTap: () => _scrollToMessage(message.replyTo!),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Replying to a message',
                        style: TextStyle(
                            fontStyle: FontStyle.italic, fontSize: 12)),
                  ),
                ),
              _buildMessageContent(message),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('HH:mm').format(message.timestamp),
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                  if (isMe) const SizedBox(width: 4),
                  if (isMe)
                    Icon(
                      message.isRead ? Icons.done_all : Icons.done,
                      size: 12,
                      color: message.isRead ? Colors.blue : Colors.grey[600],
                    ),
                  if (message.isEdited) const SizedBox(width: 4),
                  if (message.isEdited)
                    Text(
                      '(edited)',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageContent(ChatMessage message) {
    switch (message.type) {
      case MessageType.text:
        return Text(message.content);
      case MessageType.audio:
        return _buildAudioMessageContent(message.content, message.id);
      case MessageType.image:
        return GestureDetector(
          onTap: () => _showMediaViewer(message.content, MessageType.image),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: message.content,
              placeholder: (context, url) => const CircularProgressIndicator(),
              errorWidget: (context, url, error) => const Icon(Icons.error),
              width: 200,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
        );
      case MessageType.video:
        return GestureDetector(
          onTap: () => _showMediaViewer(message.content, MessageType.video),
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl:
                      message.content.replaceAll('.mp4', '_thumbnail.jpg'),
                  placeholder: (context, url) =>
                      const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              const Icon(Icons.play_circle_filled,
                  color: Colors.white, size: 50),
            ],
          ),
        );
      case MessageType.file:
        return ElevatedButton.icon(
          icon: const Icon(Icons.file_present),
          label: const Text('Open File'),
          onPressed: () => _openFile(message.content),
          style: ElevatedButton.styleFrom(
            backgroundColor: PingsterTheme.primary200,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
    }
  }

  Widget _buildPinnedMessagesBar() {
    if (_pinnedMessages.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _pinnedMessages.length,
        itemBuilder: (context, index) {
          final message = _pinnedMessages[index];
          return GestureDetector(
            onTap: () => _scrollToMessage(message.id),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.push_pin, size: 16),
                  const SizedBox(width: 4),
                  Text(message.content,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReplyingToBar() {
    if (_replyingTo == null) return const SizedBox.shrink();

    Widget replyContent;
    switch (_replyingTo!.type) {
      case MessageType.text:
        replyContent = Text(_replyingTo!.content,
            maxLines: 1, overflow: TextOverflow.ellipsis);
        break;
      case MessageType.audio:
        replyContent = const Row(
          children: [
            Icon(Icons.audiotrack, size: 16),
            SizedBox(width: 8),
            Text('Audio message'),
          ],
        );
        break;
      case MessageType.image:
        replyContent = const Row(
          children: [
            Icon(Icons.image, size: 16),
            SizedBox(width: 8),
            Text('Image'),
          ],
        );
        break;
      case MessageType.video:
        replyContent = const Row(
          children: [
            Icon(Icons.videocam, size: 16),
            SizedBox(width: 8),
            Text('Video'),
          ],
        );
        break;
      case MessageType.file:
        replyContent = const Row(
          children: [
            Icon(Icons.insert_drive_file, size: 16),
            SizedBox(width: 8),
            Text('File'),
          ],
        );
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.grey[200],
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Replying to:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                replyContent,
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () => setState(() => _replyingTo = null),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Loading...',
              style: TextStyle(color: PingsterTheme.primary200)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: PingsterTheme.primary200),
            onPressed: () => context.go('/chat'),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final authProvider = Provider.of<AuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);

    return GestureDetector(
      onTap: () {
        if (_isSearching) {
          setState(() {
            _isSearching = false;
            _searchQuery = '';
            _searchController.clear();
          });
        }
      },
      child: Scaffold(
        appBar: _buildAppBar(),
        body: Column(
          children: [
            _buildPinnedMessagesBar(),
            Expanded(
              child: StreamBuilder<List<ChatMessage>>(
                stream: chatProvider.getChatMessages(widget.chatId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No messages yet'));
                  }
                  List<ChatMessage> messages = snapshot.data!;
                  if (_isSearching && _searchQuery.isNotEmpty) {
                    messages = messages
                        .where((message) => message.content
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()))
                        .toList();
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.senderId == authProvider.user!.id;
                      return _buildMessageBubble(message, isMe);
                    },
                  );
                },
              ),
            ),
            _buildReplyingToBar(),
            if (!_isBlocked) _buildInputArea(),
            if (_isBlocked)
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[300],
                child: const Text('You cannot send messages to this user.'),
              ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(_isSearching ? Icons.arrow_back : Icons.arrow_back,
            color: PingsterTheme.primary200),
        onPressed: () {
          if (_isSearching) {
            setState(() {
              _isSearching = false;
              _searchQuery = '';
              _searchController.clear();
            });
          } else {
            context.go('/chat');
          }
        },
      ),
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search messages...',
                border: InputBorder.none,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            )
          : Row(
              children: [
                CircleAvatar(
                  backgroundImage: _otherUserProfilePicture != null
                      ? NetworkImage(_otherUserProfilePicture!)
                      : null,
                  child: _otherUserProfilePicture == null
                      ? Text(_otherUserName[0].toUpperCase())
                      : null,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_otherUserName,
                        style: const TextStyle(
                            color: PingsterTheme.primary200, fontSize: 20)),
                    if (_isTyping)
                      const Text(
                        'Typing...',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                  ],
                ),
              ],
            ),
      actions: [
        IconButton(
          icon: Icon(_isSearching ? Icons.clear : Icons.search,
              color: PingsterTheme.primary200),
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchQuery = '';
                _searchController.clear();
              }
            });
          },
        ),
        if (!_isSearching)
          IconButton(
            icon: const Icon(Icons.more_vert, color: PingsterTheme.primary200),
            onPressed: () => _showChatOptions(),
          ),
      ],
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(_isRecording ? Icons.stop : Icons.mic,
                color: PingsterTheme.primary200),
            onPressed: _toggleRecording,
          ),
          if (!_isRecording)
            IconButton(
              icon: const Icon(Icons.attach_file,
                  color: PingsterTheme.primary200),
              onPressed: _pickAndSendFile,
            ),
          if (_isRecording)
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mic, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Recording...', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ),
          if (!_isRecording)
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: _editingMessage != null
                      ? 'Edit message...'
                      : 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.timer,
                        color: PingsterTheme.primary200),
                    onPressed: () => _showSecretMessageDialog(),
                  ),
                ),
                onChanged: (value) {
                  _typingTimer?.cancel();
                  Provider.of<ChatProvider>(context, listen: false)
                      .setTypingStatus(
                          widget.chatId,
                          Provider.of<AuthProvider>(context, listen: false)
                              .user!
                              .id,
                          true);
                  _typingTimer = Timer(const Duration(seconds: 2), () {
                    Provider.of<ChatProvider>(context, listen: false)
                        .setTypingStatus(
                            widget.chatId,
                            Provider.of<AuthProvider>(context, listen: false)
                                .user!
                                .id,
                            false);
                  });
                },
              ),
            ),
          if (!_isRecording)
            IconButton(
              icon: const Icon(Icons.send, color: PingsterTheme.primary200),
              onPressed: () =>
                  _sendMessage(_messageController.text, MessageType.text),
            ),
        ],
      ),
    );
  }

  void _showSecretMessageDialog() {
    String secretMessage = '';
    Duration? selectedDuration;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Send Secret Message'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration:
                    const InputDecoration(hintText: 'Enter secret message'),
                onChanged: (value) {
                  secretMessage = value;
                },
              ),
              DropdownButton<Duration>(
                items: const [
                  DropdownMenuItem(
                      child: Text('30 seconds'), value: Duration(seconds: 30)),
                  DropdownMenuItem(
                      child: Text('1 minute'), value: Duration(minutes: 1)),
                  DropdownMenuItem(
                      child: Text('5 minutes'), value: Duration(minutes: 5)),
                ],
                onChanged: (Duration? value) {
                  selectedDuration = value;
                },
                hint: const Text('Select expiration time'),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Send'),
              onPressed: () {
                if (secretMessage.isNotEmpty && selectedDuration != null) {
                  _sendSecretMessage(
                      secretMessage, MessageType.text, selectedDuration!);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Please enter a message and select an expiration time')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  const Icon(Icons.folder, color: PingsterTheme.primary200),
              title: const Text('Move to Folder'),
              onTap: () {
                Navigator.pop(context);
                _showFolderSelector();
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.color_lens, color: PingsterTheme.primary200),
              title: const Text('Change Chat Theme'),
              onTap: () {
                Navigator.pop(context);
                _showThemeSelector();
              },
            ),
            ListTile(
              leading: Icon(_isBlocked ? Icons.block : Icons.person_add,
                  color: _isBlocked ? Colors.red : PingsterTheme.primary200),
              title: Text(_isBlocked ? 'Unblock User' : 'Block User'),
              onTap: () {
                Navigator.pop(context);
                _toggleBlockUser();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Chat'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteChatConfirmation();
              },
            ),
          ],
        );
      },
    );
  }

  void _showFolderSelector() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Folder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Unassigned'),
                onTap: () => _setChatFolder(null),
              ),
              ListTile(
                title: const Text('Work'),
                onTap: () => _setChatFolder('Work'),
              ),
              ListTile(
                title: const Text('Family'),
                onTap: () => _setChatFolder('Family'),
              ),
              ListTile(
                title: const Text('Friends'),
                onTap: () => _setChatFolder('Friends'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showThemeSelector() {
    // Implement theme selection logic
  }

  Future<void> _toggleBlockUser() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    try {
      if (_isBlocked) {
        await chatProvider.unblockUser(widget.chatId, _otherUserId!);
      } else {
        await chatProvider.blockUser(widget.chatId, _otherUserId!);
      }
      _checkBlockStatus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Failed to ${_isBlocked ? 'unblock' : 'block'} user: $e')),
      );
    }
  }

  void _showDeleteChatConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Chat'),
          content: const Text(
              'Are you sure you want to delete this chat? This action cannot be undone.'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteChat();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteChat() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    try {
      await chatProvider.deleteChat(widget.chatId);
      context.go('/chat');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete chat: $e')),
      );
    }
  }

  Future<void> _setChatFolder(String? folder) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    try {
      await chatProvider.setChatFolder(widget.chatId, folder);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Chat moved to ${folder ?? 'Unassigned'} folder')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to move chat: $e')),
      );
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = '';
      }
    });
  }

  void _scrollToMessage(String messageId) {
    if (_messageKeys.containsKey(messageId)) {
      Scrollable.ensureVisible(
        _messageKeys[messageId]!.currentContext!,
        alignment: 0.5,
        duration: const Duration(milliseconds: 300),
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _recorder.closeRecorder();
    _player.closePlayer();
    for (var subscription in _playerSubscriptions.values) {
      subscription?.cancel();
    }
    _typingTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }
}

class MediaViewerScreen extends StatefulWidget {
  final String url;
  final MessageType type;

  const MediaViewerScreen({Key? key, required this.url, required this.type})
      : super(key: key);

  @override
  _MediaViewerScreenState createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> {
  late VideoPlayerController _videoPlayerController;

  @override
  void initState() {
    super.initState();
    if (widget.type == MessageType.video) {
      _initializeVideoPlayer();
    }
  }

  Future<void> _initializeVideoPlayer() async {
    _videoPlayerController = VideoPlayerController.network(widget.url);
    await _videoPlayerController.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    if (widget.type == MessageType.video) {
      _videoPlayerController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: widget.type == MessageType.image
            ? PhotoView(
                imageProvider: CachedNetworkImageProvider(widget.url),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
              )
            : _videoPlayerController.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _videoPlayerController.value.aspectRatio,
                    child: VideoPlayer(_videoPlayerController),
                  )
                : const CircularProgressIndicator(),
      ),
      floatingActionButton: widget.type == MessageType.video
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _videoPlayerController.value.isPlaying
                      ? _videoPlayerController.pause()
                      : _videoPlayerController.play();
                });
              },
              child: Icon(
                _videoPlayerController.value.isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
              ),
            )
          : null,
    );
  }
}
