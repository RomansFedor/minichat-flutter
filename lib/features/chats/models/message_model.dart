class MessageModel {
  final String id;
  final String text;
  final String sender;
  final String senderId;
  final DateTime timestamp;
  final Map<String, List<String>> reactions;
  final bool isEdited;
  final DateTime? editedAt;

  MessageModel({
    required this.id,
    required this.text,
    required this.sender,
    required this.senderId,
    required this.timestamp,
    this.reactions = const {},
    this.isEdited = false,
    this.editedAt,
  });

  factory MessageModel.fromFirestore(String id, Map<String, dynamic> data) {
    final reactionsData = data['reactions'] as Map<String, dynamic>? ?? {};
    final reactions = <String, List<String>>{};
    
    reactionsData.forEach((key, value) {
      if (value is List) {
        reactions[key] = value.cast<String>();
      }
    });

    return MessageModel(
      id: id,
      text: data['text'] as String? ?? '',
      sender: data['sender'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      timestamp: (data['timestamp'] as dynamic)?.toDate() ?? DateTime.now(),
      reactions: reactions,
      isEdited: data['isEdited'] as bool? ?? false,
      editedAt: (data['editedAt'] as dynamic)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'text': text,
      'sender': sender,
      'senderId': senderId,
      'timestamp': timestamp,
      'reactions': reactions,
      'isEdited': isEdited,
      if (editedAt != null) 'editedAt': editedAt,
    };
  }

  MessageModel copyWith({
    String? id,
    String? text,
    String? sender,
    String? senderId,
    DateTime? timestamp,
    Map<String, List<String>>? reactions,
    bool? isEdited,
    DateTime? editedAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      text: text ?? this.text,
      sender: sender ?? this.sender,
      senderId: senderId ?? this.senderId,
      timestamp: timestamp ?? this.timestamp,
      reactions: reactions ?? this.reactions,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
    );
  }
}
