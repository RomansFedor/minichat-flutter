class ChatModel {
  final String id;
  final String name;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? lastMessageTime;
  final LastMessage? lastMessage;

  ChatModel({
    required this.id,
    required this.name,
    this.createdBy,
    this.createdAt,
    this.lastMessageTime,
    this.lastMessage,
  });

  factory ChatModel.fromFirestore(String id, Map<String, dynamic> data) {
    return ChatModel(
      id: id,
      name: data['name'] as String? ?? 'Без назви',
      createdBy: data['createdBy'] as String?,
      createdAt: (data['createdAt'] as dynamic)?.toDate(),
      lastMessageTime: (data['lastMessageTime'] as dynamic)?.toDate(),
      lastMessage: data['lastMessage'] != null
          ? LastMessage.fromMap(data['lastMessage'] as Map<String, dynamic>)
          : null,
    );
  }

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'] as String,
      name: json['name'] as String,
      createdBy: json['createdBy'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.parse(json['lastMessageTime'] as String)
          : null,
      lastMessage: json['lastMessage'] != null
          ? LastMessage.fromMap(json['lastMessage'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdBy': createdBy,
      'createdAt': createdAt?.toIso8601String(),
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'lastMessage': lastMessage?.toMap(),
    };
  }

  ChatModel copyWith({
    String? id,
    String? name,
    String? createdBy,
    DateTime? createdAt,
    DateTime? lastMessageTime,
    LastMessage? lastMessage,
  }) {
    return ChatModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }
}

class LastMessage {
  final String text;
  final String? sender;

  LastMessage({
    required this.text,
    this.sender,
  });

  factory LastMessage.fromMap(Map<String, dynamic> map) {
    return LastMessage(
      text: map['text'] as String? ?? '',
      sender: map['sender'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'sender': sender,
    };
  }
}
