import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String messageId;
  final Map<String, List<String>>? reactions;
  final String? sender;
  final String? currentUserId;
  final DateTime? timestamp;
  final VoidCallback? onLongPress;
  final Function(String emoji)? onReact;

  const MessageBubble({
    super.key,
    required this.text,
    required this.isMe,
    required this.messageId,
    this.reactions,
    this.sender,
    this.currentUserId,
    this.timestamp,
    this.onLongPress,
    this.onReact,
  });

  void _showReactionMenu(BuildContext context) {
    final emojis = ['❤️', '😂', '😮', '😢', '🙏', '👍', '👎', '🔥'];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: emojis.map((emoji) {
            return GestureDetector(
              onTap: () {
                if (onReact != null) {
                  onReact!(emoji);
                }
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showMessageMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_reaction_outlined),
              title: const Text('Реагувати'),
              onTap: () {
                Navigator.pop(context);
                _showReactionMenu(context);
              },
            ),
            if (onLongPress != null)
              ListTile(
                leading: const Icon(Icons.forward_outlined),
                title: const Text('Переслати в збережені'),
                onTap: () {
                  Navigator.pop(context);
                  onLongPress!();
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showMessageMenu(context),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe && sender != null)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Text(
                sender!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      sender != null && sender!.isNotEmpty
                          ? sender![0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  margin: EdgeInsets.only(
                    bottom: reactions != null && reactions!.isNotEmpty ? 8 : 0,
                  ),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  decoration: BoxDecoration(
                    gradient: isMe
                        ? LinearGradient(
                            colors: [
                              AppTheme.primary,
                              AppTheme.secondary,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isMe ? null : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isMe ? 20 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text,
                        style: TextStyle(
                          color: isMe ? Colors.white : AppTheme.textDark,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      if (timestamp != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${timestamp!.hour.toString().padLeft(2, '0')}:${timestamp!.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: isMe
                                ? Colors.white.withOpacity(0.7)
                                : Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      sender != null && sender!.isNotEmpty
                          ? sender![0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (reactions != null && reactions!.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                left: isMe ? 0 : 48,
                right: isMe ? 48 : 0,
                top: 4,
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                alignment: isMe ? WrapAlignment.end : WrapAlignment.start,
                children: reactions!.entries.map((entry) {
                  final emoji = entry.key;
                  final users = entry.value;
                  final hasUserReacted = currentUserId != null && users.contains(currentUserId);
                  
                  return GestureDetector(
                    onTap: () {
                      if (onReact != null) {
                        onReact!(emoji);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: hasUserReacted
                            ? AppTheme.primary.withOpacity(0.1)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasUserReacted
                              ? AppTheme.primary.withOpacity(0.3)
                              : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            emoji,
                            style: const TextStyle(fontSize: 14),
                          ),
                          if (users.length > 1) ...[
                            const SizedBox(width: 4),
                            Text(
                              '${users.length}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
