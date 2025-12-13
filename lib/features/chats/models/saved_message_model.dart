class SavedMessageModel {
  final String id;
  final String userId;
  final String messageId;
  final String chatId;
  final String messageText;
  final String sender;
  final DateTime savedAt;
  final String? note;

  SavedMessageModel({
    required this.id,
    required this.userId,
    required this.messageId,
    required this.chatId,
    required this.messageText,
    required this.sender,
    required this.savedAt,
    this.note,
  });

  factory SavedMessageModel.fromFirestore(String id, Map<String, dynamic> data) {
    return SavedMessageModel(
      id: id,
      userId: data['userId'] as String? ?? '',
      messageId: data['messageId'] as String? ?? '',
      chatId: data['chatId'] as String? ?? '',
      messageText: data['messageText'] as String? ?? '',
      sender: data['sender'] as String? ?? '',
      savedAt: (data['savedAt'] as dynamic)?.toDate() ?? DateTime.now(),
      note: data['note'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'messageId': messageId,
      'chatId': chatId,
      'messageText': messageText,
      'sender': sender,
      'savedAt': savedAt,
      if (note != null) 'note': note,
    };
  }

  SavedMessageModel copyWith({
    String? id,
    String? userId,
    String? messageId,
    String? chatId,
    String? messageText,
    String? sender,
    DateTime? savedAt,
    String? note,
  }) {
    return SavedMessageModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      messageId: messageId ?? this.messageId,
      chatId: chatId ?? this.chatId,
      messageText: messageText ?? this.messageText,
      sender: sender ?? this.sender,
      savedAt: savedAt ?? this.savedAt,
      note: note ?? this.note,
    );
  }
}
