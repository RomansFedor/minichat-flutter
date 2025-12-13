import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import '../../core/app_theme.dart';
import '../widgets/message_bubble.dart';
import 'saved_messages_screen.dart';

class ChatRoomScreen extends StatefulWidget {
  final String chatId;
  final String chatName;

  const ChatRoomScreen({
    super.key,
    required this.chatId,
    required this.chatName,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _controller = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _scrollController = ScrollController();
  bool _showEmojiPicker = false;
  FocusNode? _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode!.addListener(() {
      if (_focusNode!.hasFocus) {
        setState(() {
          _showEmojiPicker = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) return;

    final timestamp = FieldValue.serverTimestamp();
    

    await _firestore
        .collection('chat_rooms')
        .doc(widget.chatId)
        .collection('messages')
        .add({
      'text': text,
      'sender': user.email,
      'senderId': user.uid,
      'timestamp': timestamp,
      'reactions': {},
    });

    await _firestore.collection('chat_rooms').doc(widget.chatId).update({
      'lastMessage': {
        'text': text,
        'sender': user.email,
      },
      'lastMessageTime': timestamp,
    });

    _controller.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
      if (_showEmojiPicker) {
        _focusNode?.unfocus();
      } else {
        _focusNode?.requestFocus();
      }
    });
  }

  void _onEmojiSelected(Emoji emoji) {
    _controller.text += emoji.emoji;
  }

  void _addReaction(String messageId, String emoji) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final messageRef = _firestore
        .collection('chat_rooms')
        .doc(widget.chatId)
        .collection('messages')
        .doc(messageId);
    final messageDoc = await messageRef.get();

    if (!messageDoc.exists) return;

    final data = messageDoc.data() as Map<String, dynamic>;
    final reactions = Map<String, dynamic>.from(data['reactions'] ?? {});
    final emojiReactions = List<String>.from(reactions[emoji] ?? []);

    if (emojiReactions.contains(user.uid)) {
      emojiReactions.remove(user.uid);
      if (emojiReactions.isEmpty) {
        reactions.remove(emoji);
      } else {
        reactions[emoji] = emojiReactions;
      }
    } else {
      emojiReactions.add(user.uid);
      reactions[emoji] = emojiReactions;
    }

    await messageRef.update({'reactions': reactions});
  }

  void _forwardToSaved(String messageId, String text, String sender) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('saved_messages').add({
      'userId': user.uid,
      'messageId': messageId,
      'chatId': widget.chatId,
      'text': text,
      'originalSender': sender,
      'savedAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Повідомлення збережено'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Map<String, List<String>> _parseReactions(Map<String, dynamic>? reactions) {
    if (reactions == null) return {};

    final parsed = <String, List<String>>{};
    reactions.forEach((emoji, users) {
      if (users is List) {
        parsed[emoji] = List<String>.from(users);
      }
    });
    return parsed;
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.chatName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            StreamBuilder<DocumentSnapshot>(
              stream: _firestore
                  .collection('chat_rooms')
                  .doc(widget.chatId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }
                final data = snapshot.data!.data() as Map<String, dynamic>?;
                if (data == null) return const SizedBox.shrink();
                
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            tooltip: 'Збережені повідомлення',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SavedMessagesScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chat_rooms')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Почніть розмову!',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final text = data['text'] as String? ?? '';
                    final sender = data['sender'] as String? ?? 'Anonymous';
                    final senderId = data['senderId'] as String? ?? '';
                    final isMe = senderId == user?.uid;
                    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
                    final reactions = _parseReactions(data['reactions'] as Map<String, dynamic>?);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: MessageBubble(
                        text: text,
                        isMe: isMe,
                        messageId: doc.id,
                        sender: sender,
                        currentUserId: user?.uid,
                        timestamp: timestamp,
                        reactions: reactions.isNotEmpty ? reactions : null,
                        onReact: (emoji) => _addReaction(doc.id, emoji),
                        onLongPress: () => _forwardToSaved(doc.id, text, sender),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_showEmojiPicker)
            SizedBox(
              height: 250,
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  _onEmojiSelected(emoji);
                },
                config: Config(
                  height: 256,
                  checkPlatformCompatibility: true,
                  emojiViewConfig: EmojiViewConfig(
                    emojiSizeMax: 28 * (1.0),
                    backgroundColor: Colors.white,
                  ),
                  skinToneConfig: const SkinToneConfig(),
                  categoryViewConfig: const CategoryViewConfig(),
                  bottomActionBarConfig: const BottomActionBarConfig(),
                ),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined,
                        color: AppTheme.primary,
                      ),
                      onPressed: _toggleEmojiPicker,
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          decoration: InputDecoration(
                            hintText: 'Введіть повідомлення...',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                            ),
                          ),
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.primary, AppTheme.secondary],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
