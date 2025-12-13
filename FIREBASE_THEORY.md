# Теоретичні відомості про Firebase Firestore

## Вступ

Firebase Firestore - це NoSQL база даних, яка зберігає дані у вигляді документів, організованих у колекції. Вона забезпечує реальний час синхронізації, автономну роботу та автоматичне масштабування.

## Основні поняття

### Колекції та документи

- **Колекція** - контейнер для документів (аналог таблиці в SQL)
- **Документ** - об'єкт, що містить пари ключ-значення (аналог рядка в SQL)
- **Підколекція** - колекція всередині документа

**Структура:**
```
chat_rooms (колекція)
  └── chatId1 (документ)
      ├── name: "Чат 1"
      ├── createdBy: "user123"
      └── messages (підколекція)
          └── messageId1 (документ)
              ├── text: "Привіт"
              └── sender: "user@example.com"
```

### Типи даних

Firestore підтримує такі типи даних:
- String (рядок)
- Number (число)
- Boolean (булеве значення)
- Map (об'єкт)
- Array (масив)
- Timestamp (дата/час)
- GeoPoint (геокоординати)
- Null
- Reference (посилання на інший документ)

## Робота з Firestore у Flutter

### Підключення

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

final firestore = FirebaseFirestore.instance;
```

### Читання даних

#### Один раз (get)

```dart
// Отримати один документ
final doc = await firestore.collection('chat_rooms').doc('chatId').get();
final data = doc.data(); // Map<String, dynamic>

// Отримати всі документи в колекції
final snapshot = await firestore.collection('chat_rooms').get();
final docs = snapshot.docs; // List<QueryDocumentSnapshot>
```

#### У реальному часі (Stream)

```dart
// Потік одного документа
firestore.collection('chat_rooms').doc('chatId')
  .snapshots()
  .listen((doc) {
    if (doc.exists) {
      final data = doc.data();
    }
  });

// Потік колекції
firestore.collection('chat_rooms')
  .snapshots()
  .listen((snapshot) {
    for (var doc in snapshot.docs) {
      print(doc.data());
    }
  });
```

### Запис даних

#### Створити документ

```dart
// Автоматичний ID
await firestore.collection('chat_rooms').add({
  'name': 'Новий чат',
  'createdAt': FieldValue.serverTimestamp(),
});

// З вказаним ID
await firestore.collection('chat_rooms').doc('myChatId').set({
  'name': 'Новий чат',
  'createdAt': FieldValue.serverTimestamp(),
});
```

#### Оновити документ

```dart
await firestore.collection('chat_rooms').doc('chatId').update({
  'name': 'Оновлена назва',
});
```

#### Видалити документ

```dart
await firestore.collection('chat_rooms').doc('chatId').delete();
```

### Запити

```dart
// Фільтрація
firestore.collection('chat_rooms')
  .where('createdBy', isEqualTo: 'user123')
  .get();

// Сортування
firestore.collection('chat_rooms')
  .orderBy('createdAt', descending: true)
  .get();

// Обмеження
firestore.collection('chat_rooms')
  .limit(10)
  .get();

// Комбінація
firestore.collection('chat_rooms')
  .where('createdBy', isEqualTo: 'user123')
  .orderBy('createdAt', descending: true)
  .limit(10)
  .get();
```

## Правила безпеки (Security Rules)

Правила доступу визначають, хто може читати та записувати дані.

### Структура правил

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Правила тут
  }
}
```

### Функції

```javascript
function isAuthenticated() {
  return request.auth != null;
}

function isOwner(userId) {
  return isAuthenticated() && request.auth.uid == userId;
}
```

### Приклади правил

```javascript
// Дозволити читання тільки авторизованим
match /chat_rooms/{chatId} {
  allow read: if request.auth != null;
  
  // Дозволити створення тільки авторизованим
  allow create: if request.auth != null
    && request.resource.data.createdBy == request.auth.uid;
  
  // Дозволити оновлення тільки власнику
  allow update: if request.auth != null
    && resource.data.createdBy == request.auth.uid;
  
  // Дозволити видалення тільки власнику
  allow delete: if request.auth != null
    && resource.data.createdBy == request.auth.uid;
}
```

### Змінні

- `request.auth` - інформація про авторизованого користувача
- `request.resource` - дані, які намагаються записати
- `resource` - існуючі дані в документі
- `resource.data` - дані документа

## Паттерн Repository

Repository - це паттерн проектування, який інкапсулює логіку доступу до даних.

### Переваги

1. **Розділення відповідальностей** - логіка даних відокремлена від бізнес-логіки
2. **Тестування** - легко створити mock-репозиторії
3. **Гнучкість** - можна змінити джерело даних без зміни UI

### Структура

```dart
// Абстрактний інтерфейс
abstract class ChatsRepository {
  Future<List<ChatModel>> getChats();
  Future<String> createChat(String name);
}

// Реалізація через Firestore
class FirestoreChatsRepository implements ChatsRepository {
  final FirebaseFirestore _firestore;
  
  @override
  Future<List<ChatModel>> getChats() async {
    final snapshot = await _firestore.collection('chat_rooms').get();
    return snapshot.docs.map((doc) => 
      ChatModel.fromFirestore(doc.id, doc.data())
    ).toList();
  }
}

// Використання в BLoC
class ChatsBloc extends Bloc<ChatsEvent, ChatsState> {
  final ChatsRepository _repository;
  
  ChatsBloc(this._repository);
}
```

## Інтеграція з BLoC

### Використання Stream у BLoC

```dart
class ChatsBloc extends Bloc<ChatsEvent, ChatsState> {
  StreamSubscription? _chatsSubscription;
  
  Future<void> _onLoadChats(...) async {
    emit(ChatsLoadingState());
    
    // Підписка на потік
    _chatsSubscription = _repository.getChatsStream().listen(
      (chats) {
        emit(ChatsDataState(data: chats));
      },
      onError: (error) {
        emit(ChatsErrorState(error: error.toString()));
      },
    );
  }
  
  @override
  Future<void> close() {
    _chatsSubscription?.cancel();
    return super.close();
  }
}
```

### Обробка станів створення/оновлення

```dart
// BLoC для створення
class CreateChatBloc extends Bloc<CreateChatEvent, CreateChatState> {
  final ChatsRepository _repository;
  
  Future<void> _onCreateChat(...) async {
    emit(CreateChatCreatingState());
    
    try {
      final chatId = await _repository.createChat(name: event.name);
      emit(CreateChatSuccessState(chatId: chatId));
    } catch (e) {
      emit(CreateChatErrorState(error: e.toString()));
    }
  }
}
```

## Оптимізація

### Індекси

Для складних запитів потрібно створити індекси:

```dart
// Запит, який потребує індексу
firestore.collection('chat_rooms')
  .where('createdBy', isEqualTo: 'user123')
  .orderBy('createdAt', descending: true)
  .get();
```

Firebase автоматично запропонує створити індекс.

### Batch операції

```dart
final batch = firestore.batch();

batch.set(firestore.collection('users').doc('user1'), {...});
batch.update(firestore.collection('users').doc('user2'), {...});
batch.delete(firestore.collection('users').doc('user3'));

await batch.commit();
```

### Transaction

```dart
await firestore.runTransaction((transaction) async {
  final docRef = firestore.collection('chat_rooms').doc('chatId');
  final doc = await transaction.get(docRef);
  
  if (doc.exists) {
    transaction.update(docRef, {
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }
});
```

## Обробка помилок

```dart
try {
  await firestore.collection('chat_rooms').add({...});
} on FirebaseException catch (e) {
  if (e.code == 'permission-denied') {
    print('Немає прав доступу');
  } else if (e.code == 'unavailable') {
    print('Сервіс недоступний');
  }
} catch (e) {
  print('Загальна помилка: $e');
}
```

## Найкращі практики

1. **Використовуйте індекси** для складних запитів
2. **Обмежуйте кількість даних** через `limit()`
3. **Використовуйте `serverTimestamp()`** для точних часових міток
4. **Валідуйте дані** в правилах безпеки
5. **Використовуйте Repository pattern** для абстракції
6. **Обробляйте помилки** належним чином
7. **Використовуйте Stream** для реального часу
8. **Оптимізуйте структуру даних** для мінімізації запитів

---

**Дата створення:** 2025  
**Версія:** 1.0

