import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/saved_message_model.dart';

abstract class SavedMessagesRepository {
  Stream<List<SavedMessageModel>> getSavedMessagesStream(String userId);
  
  Future<List<SavedMessageModel>> getSavedMessages(String userId);
  
  Future<String> saveMessage({
    required String userId,
    required String messageId,
    required String chatId,
    required String messageText,
    required String sender,
    String? note,
  });
  
  Future<void> updateNote({
    required String savedMessageId,
    required String note,
  });
  
  Future<void> deleteSavedMessage(String savedMessageId);
}

class FirestoreSavedMessagesRepository implements SavedMessagesRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirestoreSavedMessagesRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  @override
  Stream<List<SavedMessageModel>> getSavedMessagesStream(String userId) {
    return _firestore
        .collection('saved_messages')
        .where('userId', isEqualTo: userId)
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SavedMessageModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  @override
  Future<List<SavedMessageModel>> getSavedMessages(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('saved_messages')
          .where('userId', isEqualTo: userId)
          .orderBy('savedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => SavedMessageModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Помилка завантаження збережених повідомлень: $e');
    }
  }

  @override
  Future<String> saveMessage({
    required String userId,
    required String messageId,
    required String chatId,
    required String messageText,
    required String sender,
    String? note,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Користувач не авторизований');
      }

      if (userId != user.uid) {
        throw Exception('Неможливо зберегти повідомлення для іншого користувача');
      }

      final existingSnapshot = await _firestore
          .collection('saved_messages')
          .where('userId', isEqualTo: userId)
          .where('messageId', isEqualTo: messageId)
          .limit(1)
          .get();

      if (existingSnapshot.docs.isNotEmpty) {
        throw Exception('Повідомлення вже збережено');
      }

      final savedMessageData = {
        'userId': userId,
        'messageId': messageId,
        'chatId': chatId,
        'messageText': messageText,
        'sender': sender,
        'savedAt': FieldValue.serverTimestamp(),
        if (note != null && note.isNotEmpty) 'note': note,
      };

      final docRef = await _firestore.collection('saved_messages').add(savedMessageData);
      return docRef.id;
    } catch (e) {
      throw Exception('Помилка збереження повідомлення: $e');
    }
  }

  @override
  Future<void> updateNote({
    required String savedMessageId,
    required String note,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Користувач не авторизований');
      }

      final doc = await _firestore.collection('saved_messages').doc(savedMessageId).get();
      
      if (!doc.exists) {
        throw Exception('Збережене повідомлення не знайдено');
      }

      final data = doc.data() as Map<String, dynamic>;
      if (data['userId'] != user.uid) {
        throw Exception('Немає прав для редагування цього повідомлення');
      }

      await _firestore.collection('saved_messages').doc(savedMessageId).update({
        'note': note.trim(),
      });
    } catch (e) {
      throw Exception('Помилка оновлення примітки: $e');
    }
  }

  @override
  Future<void> deleteSavedMessage(String savedMessageId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Користувач не авторизований');
      }

      final doc = await _firestore.collection('saved_messages').doc(savedMessageId).get();
      
      if (!doc.exists) {
        throw Exception('Збережене повідомлення не знайдено');
      }

      final data = doc.data() as Map<String, dynamic>;
      if (data['userId'] != user.uid) {
        throw Exception('Немає прав для видалення цього повідомлення');
      }

      await _firestore.collection('saved_messages').doc(savedMessageId).delete();
    } catch (e) {
      throw Exception('Помилка видалення збереженого повідомлення: $e');
    }
  }
}
