import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';

abstract class MessagesRepository {
  Stream<List<MessageModel>> getMessagesStream(String chatId);
  
  Future<List<MessageModel>> getMessages(String chatId, {int? limit});
  
  Future<String> createMessage({
    required String chatId,
    required String text,
  });
  
  Future<void> updateMessage({
    required String chatId,
    required String messageId,
    required String newText,
  });
  
  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
  });
  
  Future<void> addReaction({
    required String chatId,
    required String messageId,
    required String emoji,
  });
  
  Future<void> removeReaction({
    required String chatId,
    required String messageId,
    required String emoji,
  });
}

class FirestoreMessagesRepository implements MessagesRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirestoreMessagesRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  @override
  Stream<List<MessageModel>> getMessagesStream(String chatId) {
    return _firestore
        .collection('chat_rooms')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  @override
  Future<List<MessageModel>> getMessages(String chatId, {int? limit}) async {
    try {
      Query query = _firestore
          .collection('chat_rooms')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => MessageModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Помилка завантаження повідомлень: $e');
    }
  }

  @override
  Future<String> createMessage({
    required String chatId,
    required String text,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Користувач не авторизований');
      }

      final messageData = {
        'text': text.trim(),
        'sender': user.email ?? '',
        'senderId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'reactions': <String, List<String>>{},
        'isEdited': false,
      };

      final messageRef = await _firestore
          .collection('chat_rooms')
          .doc(chatId)
          .collection('messages')
          .add(messageData);

      final timestamp = FieldValue.serverTimestamp();
      await _firestore.collection('chat_rooms').doc(chatId).update({
        'lastMessage': {
          'text': text.trim(),
          'sender': user.email ?? '',
        },
        'lastMessageTime': timestamp,
      });

      return messageRef.id;
    } catch (e) {
      throw Exception('Помилка створення повідомлення: $e');
    }
  }

  @override
  Future<void> updateMessage({
    required String chatId,
    required String messageId,
    required String newText,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Користувач не авторизований');
      }

      final messageDoc = await _firestore
          .collection('chat_rooms')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .get();

      if (!messageDoc.exists) {
        throw Exception('Повідомлення не знайдено');
      }

      final messageData = messageDoc.data() as Map<String, dynamic>;
      if (messageData['senderId'] != user.uid) {
        throw Exception('Немає прав для редагування цього повідомлення');
      }

      await _firestore
          .collection('chat_rooms')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
        'text': newText.trim(),
        'isEdited': true,
        'editedAt': FieldValue.serverTimestamp(),
      });

      final lastMessage = messageData['text'] as String?;
      if (lastMessage != null) {
        await _firestore.collection('chat_rooms').doc(chatId).update({
          'lastMessage.text': newText.trim(),
        });
      }
    } catch (e) {
      throw Exception('Помилка оновлення повідомлення: $e');
    }
  }

  @override
  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Користувач не авторизований');
      }

      final messageDoc = await _firestore
          .collection('chat_rooms')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .get();

      if (!messageDoc.exists) {
        throw Exception('Повідомлення не знайдено');
      }

      final messageData = messageDoc.data() as Map<String, dynamic>;
      if (messageData['senderId'] != user.uid) {
        throw Exception('Немає прав для видалення цього повідомлення');
      }

      await _firestore
          .collection('chat_rooms')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      throw Exception('Помилка видалення повідомлення: $e');
    }
  }

  @override
  Future<void> addReaction({
    required String chatId,
    required String messageId,
    required String emoji,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Користувач не авторизований');
      }

      await _firestore
          .collection('chat_rooms')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
        'reactions.$emoji': FieldValue.arrayUnion([user.uid]),
      });
    } catch (e) {
      throw Exception('Помилка додавання реакції: $e');
    }
  }

  @override
  Future<void> removeReaction({
    required String chatId,
    required String messageId,
    required String emoji,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Користувач не авторизований');
      }

      await _firestore
          .collection('chat_rooms')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
        'reactions.$emoji': FieldValue.arrayRemove([user.uid]),
      });
    } catch (e) {
      throw Exception('Помилка видалення реакції: $e');
    }
  }
}
