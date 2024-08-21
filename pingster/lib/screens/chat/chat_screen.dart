import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/chat_message_model.dart';
import '../../services/encryption_service.dart';
import '../../theme.dart';

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
  bool _isRecording = false;
  final EncryptionService _encryptionService = EncryptionService();
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    print('Debug: ChatScreen initialized with chatId: ${widget.chatId}');
    _checkAndRequestPermissions();
  }

  Future<void> _checkAndRequestPermissions() async {
    final microphoneStatus = await Permission.microphone.status;
    final storageStatus = await Permission.storage.status;

    if (microphoneStatus.isGranted && storageStatus.isGranted) {
      _permissionsGranted = true;
      _initializeRecorderAndPlayer();
    } else {
      final statuses = await [
        Permission.microphone,
        Permission.storage,
      ].request();

      _permissionsGranted = statuses[Permission.microphone]!.isGranted &&
          statuses[Permission.storage]!.isGranted;

      if (_permissionsGranted) {
        _initializeRecorderAndPlayer();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Permissions are required for full functionality')),
        );
      }
    }
  }

  Future<void> _initializeRecorderAndPlayer() async {
    if (_permissionsGranted) {
      await _recorder.openRecorder();
      await _player.openPlayer();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _recorder.closeRecorder();
    _player.closePlayer();
    super.dispose();
  }

  Future<void> _sendMessage(String content, MessageType type) async {
    if (content.isNotEmpty) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);

      String encryptedContent = await _encryptionService.encrypt(content);

      ChatMessage message = ChatMessage(
        id: '',
        senderId: authProvider.user!.uid,
        content: encryptedContent,
        timestamp: DateTime.now(),
        type: type,
      );

      await chatProvider.sendMessage(widget.chatId, message);
      _messageController.clear();
    }
  }

  Future<void> _pickAndSendFile() async {
    if (!_permissionsGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Storage permission is required for file attachments')),
      );
      return;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File file = File(result.files.single.path!);
      String fileUrl = await Provider.of<ChatProvider>(context, listen: false)
          .uploadFile(file);
      await _sendMessage(fileUrl, MessageType.file);
    }
  }

  Future<void> _toggleRecording() async {
    if (!_permissionsGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Microphone permission is required for audio messages')),
      );
      return;
    }

    if (!_isRecording) {
      await _recorder.startRecorder(toFile: 'temp_audio.aac');
    } else {
      final path = await _recorder.stopRecorder();
      if (path != null) {
        String audioUrl =
            await Provider.of<ChatProvider>(context, listen: false)
                .uploadFile(File(path));
        await _sendMessage(audioUrl, MessageType.audio);
      }
    }
    setState(() {
      _isRecording = !_isRecording;
    });
  }

  Future<void> _playAudio(String url) async {
    await _player.startPlayer(
      fromURI: url,
      whenFinished: () {
        setState(() {});
      },
    );
  }

  Future<void> _openFile(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open the file')),
      );
    }
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return FutureBuilder<String>(
      future: _encryptionService.decrypt(message.content),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        String decryptedContent = snapshot.data ?? 'Error decrypting message';

        Widget messageContent;
        switch (message.type) {
          case MessageType.text:
            messageContent = Text(decryptedContent);
            break;
          case MessageType.audio:
            messageContent = IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () => _playAudio(decryptedContent),
            );
            break;
          case MessageType.file:
            messageContent = TextButton(
              child: const Text('Open File'),
              onPressed: () => _openFile(decryptedContent),
            );
            break;
        }

        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMe ? PingsterTheme.primary100 : Colors.grey[300],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                messageContent,
                const SizedBox(height: 4),
                Text(
                  message.timestamp.toString(),
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat ${widget.chatId}'),
        backgroundColor: PingsterTheme.primary200,
      ),
      body: Column(
        children: [
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
                return ListView.builder(
                  reverse: true,
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final message = snapshot.data![index];
                    final isMe = message.senderId == authProvider.user!.uid;
                    return _buildMessageBubble(message, isMe);
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                  onPressed: _toggleRecording,
                ),
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: _pickAndSendFile,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () =>
                      _sendMessage(_messageController.text, MessageType.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
