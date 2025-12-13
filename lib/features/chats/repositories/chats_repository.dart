import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_model.dart';

abstract class ChatsRepository {
  Future<List<ChatModel>> getChats();
  
  Stream<List<ChatModel>> getChatsStream();
  
  Future<ChatModel?> getChatById(String chatId);
  
  Future<String> createChat({
    required String name,
  });
  
  Future<void> updateChat({
    required String chatId,
    String? name,
  });
  
  Future<void> deleteChat(String chatId);
  
  Future<void> updateLastMessage({
    required String chatId,
    required String text,
    required String sender,
    required DateTime timestamp,
  });
}

class FirestoreChatsRepository implements ChatsRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirestoreChatsRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  @override
  Future<List<ChatModel>> getChats() async {
    try {
      final snapshot = await _firestore
          .collection('chat_rooms')
          .orderBy('lastMessageTime', descending: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ChatModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Помилка завантаження чатів: $e');
    }
  }

  @override
  Stream<List<ChatModel>> getChatsStream() {
    return _firestore
        .collection('chat_rooms')
        .snapshots()
        .map((snapshot) {
      final chats = snapshot.docs
          .map((doc) => ChatModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
          .toList();

      chats.sort((a, b) {
        if (a.lastMessageTime != null && b.lastMessageTime != null) {
          return b.lastMessageTime!.compareTo(a.lastMessageTime!);
        }
        if (a.lastMessageTime != null && b.lastMessageTime == null) return -1;
        if (a.lastMessageTime == null && b.lastMessageTime != null) return 1;

        if (a.createdAt != null && b.createdAt != null) {
          return b.createdAt!.compareTo(a.createdAt!);
        }

        return 0;
      });

      return chats;
    });
  }

  @override
  Future<ChatModel?> getChatById(String chatId) async {
    try {
      final doc = await _firestore.collection('chat_rooms').doc(chatId).get();
      
      if (!doc.exists) {
        return null;
      }

      return ChatModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Помилка отримання чату: $e');
    }
  }

  @override
  Future<String> createChat({
    required String name,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Користувач не авторизований');
      }

      final chatData = {
        'name': name,
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': null,
        'lastMessageTime': null,
      };

      final docRef = await _firestore.collection('chat_rooms').add(chatData);
      return docRef.id;
    } catch (e) {
      throw Exception('Помилка створення чату: $e');
    }
  }

  @override
  Future<void> updateChat({
    required String chatId,
    String? name,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Користувач не авторизований');
      }

      final chat = await getChatById(chatId);
      if (chat == null) {
        throw Exception('Чат не знайдено');
      }

      if (chat.createdBy != user.uid) {
        throw Exception('Немає прав для редагування цього чату');
      }

      final updateData = <String, dynamic>{};
      if (name != null) {
        updateData['name'] = name;
      }

      if (updateData.isEmpty) {
        return;
      }

      await _firestore.collection('chat_rooms').doc(chatId).update(updateData);
    } catch (e) {
      throw Exception('Помилка оновлення чату: $e');
    }
  }

  @override
  Future<void> deleteChat(String chatId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Користувач не авторизований');
      }

      final chat = await getChatById(chatId);
      if (chat == null) {
        throw Exception('Чат не знайдено');
      }

      if (chat.createdBy != user.uid) {
        throw Exception('Немає прав для видалення цього чату');
      }

      final messagesSnapshot = await _firestore
          .collection('chat_rooms')
          .doc(chatId)
          .collection('messages')
          .get();

      final batch = _firestore.batch();
      for (final doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      batch.delete(_firestore.collection('chat_rooms').doc(chatId));
      
      await batch.commit();
    } catch (e) {
      throw Exception('Помилка видалення чату: $e');
    }
  }

  @override
  Future<void> updateLastMessage({
    required String chatId,
    required String text,
    required String sender,
    required DateTime timestamp,
  }) async {
    try {
      await _firestore.collection('chat_rooms').doc(chatId).update({
        'lastMessage': {
          'text': text,
          'sender': sender,
        },
        'lastMessageTime': Timestamp.fromDate(timestamp),
      });
    } catch (e) {
      throw Exception('Помилка оновлення останнього повідомлення: $e');
    }
  }
}
