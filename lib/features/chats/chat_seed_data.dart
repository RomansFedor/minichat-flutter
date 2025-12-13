import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatSeedData {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> initializeTestChats() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final existingChats = await _firestore.collection('chat_rooms').limit(1).get();
    if (existingChats.docs.isNotEmpty) {
      return;
    }

    final now = DateTime.now();
    
    final chats = [
      {
        'name': 'Загальний чат',
        'createdBy': user.uid,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 2))),
        'lastMessage': {
          'text': 'Все добре, дякую! 😊',
          'sender': user.email,
        },
        'lastMessageTime': Timestamp.fromDate(now.subtract(const Duration(minutes: 15))),
      },
      {
        'name': 'Робота',
        'createdBy': user.uid,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 1))),
        'lastMessage': {
          'text': 'Коли зручно зустрітися?',
          'sender': user.email,
        },
        'lastMessageTime': Timestamp.fromDate(now.subtract(const Duration(minutes: 10))),
      },
      {
        'name': 'Друзі',
        'createdBy': user.uid,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(minutes: 30))),
        'lastMessage': {
          'text': 'Я готовий! 🍿',
          'sender': user.email,
        },
        'lastMessageTime': Timestamp.fromDate(now.subtract(const Duration(minutes: 5))),
      },
    ];

    final testMessages = [
      [
        {'text': 'Ласкаво просимо в загальний чат! 🎉', 'sender': 'System', 'senderId': 'system'},
        {'text': 'Привіт всім! 👋', 'sender': user.email, 'senderId': user.uid},
        {'text': 'Як справи?', 'sender': user.email, 'senderId': user.uid},
        {'text': 'Все добре, дякую! 😊', 'sender': user.email, 'senderId': user.uid},
      ],
      [
        {'text': 'Доброго ранку! ☀️', 'sender': user.email, 'senderId': user.uid},
        {'text': 'Потрібно обговорити проект', 'sender': user.email, 'senderId': user.uid},
        {'text': 'Коли зручно зустрітися?', 'sender': user.email, 'senderId': user.uid},
      ],
      [
        {'text': 'Привіт! 👋', 'sender': user.email, 'senderId': user.uid},
        {'text': 'Хто йде на кіно? 🎬', 'sender': user.email, 'senderId': user.uid},
        {'text': 'Я готовий! 🍿', 'sender': user.email, 'senderId': user.uid},
      ],
    ];

    for (int i = 0; i < chats.length; i++) {
      final chatData = Map<String, dynamic>.from(chats[i]);
      final chatCreatedAt = (chatData['createdAt'] as Timestamp).toDate();
      final chatRef = await _firestore.collection('chat_rooms').add(chatData);
      
      final messages = testMessages[i];
      DateTime baseTime = chatCreatedAt;
      
      List<DateTime> messageTimes = [];
      for (int j = 0; j < messages.length; j++) {
        final messageTime = baseTime.add(Duration(minutes: (j + 1) * 5));
        messageTimes.add(messageTime);
        await chatRef.collection('messages').add({
          ...messages[j],
          'timestamp': Timestamp.fromDate(messageTime),
          'reactions': {},
        });
      }
      
      if (messages.isNotEmpty && messageTimes.isNotEmpty) {
        final lastIndex = messages.length - 1;
        final lastMessage = messages[lastIndex];
        await chatRef.update({
          'lastMessageTime': Timestamp.fromDate(messageTimes.last),
          'lastMessage': {
            'text': lastMessage['text'],
            'sender': lastMessage['sender'],
          },
        });
      }
    }
  }

  Future<void> addTestChatsIfNeeded() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final existingChats = await _firestore.collection('chat_rooms').get();
    if (existingChats.docs.length < 3) {
      await initializeTestChats();
    }
  }
}

