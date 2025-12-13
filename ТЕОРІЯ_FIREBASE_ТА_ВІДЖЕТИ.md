# 📚 Теорія Firebase та віджети для лабораторної роботи

## 📋 ЗМІСТ 
1. [Firebase - загальна інформація](#firebase-загальна-інформація)
2. [Firebase сервіси в проєкті](#firebase-сервіси-в-проєкті)
3. [Cloud Firestore - база даних](#cloud-firestore)
4. [Firebase Authentication](#firebase-authentication)
5. [Firebase Analytics та Crashlytics](#firebase-analytics-та-crashlytics)
6. [Віджети для роботи з Firebase](#віджети-для-роботи-з-firebase)
7. [Основні Flutter віджети в проєкті](#основні-flutter-віджети)
8. [Практичні приклади використання](#практичні-приклади)

---

## 🔥 FIREBASE - ЗАГАЛЬНА ІНФОРМАЦІЯ

### Що таке Firebase?

**Firebase** - це платформа від Google для розробки мобільних та веб-додатків, яка надає набір інструментів та сервісів для backend-функціональності без необхідності писати власний серверний код.

### Основні переваги Firebase:

1. **Backend as a Service (BaaS)** - готові сервіси без необхідності налаштування серверів
2. **Real-time синхронізація** - автоматичне оновлення даних між клієнтами
3. **Масштабованість** - автоматичне масштабування під навантаження
4. **Безпека** - вбудовані правила безпеки та аутентифікація
5. **Кросплатформенність** - працює на Android, iOS, Web, Desktop

### Архітектура Firebase в проєкті:

```
Flutter App
    │
    ├── Firebase Core (ініціалізація)
    ├── Firebase Auth (аутентифікація)
    ├── Cloud Firestore (база даних)
    ├── Firebase Analytics (аналітика)
    └── Firebase Crashlytics (звіти про помилки)
```

---

## 🔧 FIREBASE СЕРВІСИ В ПРОЄКТІ

### 1. Firebase Core (`firebase_core`)

**Призначення:** Базовий пакет для ініціалізації Firebase в додатку.

**Використання в проєкті:**
```dart
// lib/main.dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

**Що робить:**
- Ініціалізує Firebase для всіх платформ (Android, iOS, Web)
- Налаштовує підключення до Firebase проекту
- Має бути викликаний перед використанням інших Firebase сервісів

**Важливо:**
- Викликається один раз при старті додатку
- `WidgetsFlutterBinding.ensureInitialized()` має бути викликаний перед ініціалізацією

---

### 2. Firebase Authentication (`firebase_auth`)

**Призначення:** Сервіс для аутентифікації користувачів (вхід, реєстрація, вихід).

**Основні можливості:**
- Email/Password аутентифікація
- Анонімна аутентифікація
- Соціальні мережі (Google, Facebook, тощо)
- Керування сесіями користувачів

**Використання в проєкті:**

```dart
// Отримання поточного користувача
final user = FirebaseAuth.instance.currentUser;

// Реєстрація
await FirebaseAuth.instance.createUserWithEmailAndPassword(
  email: email,
  password: password,
);

// Вхід
await FirebaseAuth.instance.signInWithEmailAndPassword(
  email: email,
  password: password,
);

// Вихід
await FirebaseAuth.instance.signOut();
```

**Обробка помилок:**
```dart
try {
  await AuthRepository().signIn(email: email, password: password);
} on FirebaseAuthException catch (e) {
  // Обробка помилок аутентифікації
  print(e.message);
}
```

**Основні типи помилок:**
- `user-not-found` - користувач не знайдений
- `wrong-password` - невірний пароль
- `email-already-in-use` - email вже використовується
- `weak-password` - слабкий пароль

**Властивості User:**
- `uid` - унікальний ідентифікатор користувача
- `email` - email адреса
- `displayName` - відображуване ім'я
- `photoURL` - URL фото профілю

---

### 3. Cloud Firestore (`cloud_firestore`)

**Призначення:** NoSQL база даних для зберігання та синхронізації даних в реальному часі.

**Структура даних:**
```
Firestore
  └── Колекції (Collections)
      └── Документи (Documents)
          ├── Поля (Fields)
          └── Підколекції (Subcollections)
```

**Структура в проєкті:**
```
chat_rooms (колекція)
  └── {chatId} (документ)
      ├── name: "Назва чату"
      ├── lastMessage: {...}
      ├── lastMessageTime: Timestamp
      └── messages (підколекція)
          └── {messageId} (документ)
              ├── text: "Текст повідомлення"
              ├── sender: "email@example.com"
              ├── senderId: "userId"
              ├── timestamp: Timestamp
              └── reactions: {...}

saved_messages (колекція)
  └── {savedId} (документ)
      ├── userId: "userId"
      ├── messageId: "messageId"
      ├── text: "Текст"
      └── savedAt: Timestamp
```

**Основні операції:**

**1. Читання даних (одноразове):**
```dart
// Отримати один документ
final doc = await FirebaseFirestore.instance
    .collection('chat_rooms')
    .doc(chatId)
    .get();

if (doc.exists) {
  final data = doc.data(); // Map<String, dynamic>
}
```

**2. Читання даних (real-time):**
```dart
// Stream для автоматичного оновлення
Stream<DocumentSnapshot> stream = FirebaseFirestore.instance
    .collection('chat_rooms')
    .doc(chatId)
    .snapshots();

// Або для колекції
Stream<QuerySnapshot> stream = FirebaseFirestore.instance
    .collection('chat_rooms')
    .snapshots();
```

**3. Додавання даних:**
```dart
// Додати документ з автоматичним ID
await FirebaseFirestore.instance
    .collection('chat_rooms')
    .add({
      'name': 'Новий чат',
      'createdAt': FieldValue.serverTimestamp(),
    });

// Додати документ з конкретним ID
await FirebaseFirestore.instance
    .collection('chat_rooms')
    .doc('chatId123')
    .set({
      'name': 'Новий чат',
      'createdAt': FieldValue.serverTimestamp(),
    });
```

**4. Оновлення даних:**
```dart
await FirebaseFirestore.instance
    .collection('chat_rooms')
    .doc(chatId)
    .update({
      'lastMessage': {'text': 'Нове повідомлення'},
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
```

**5. Видалення даних:**
```dart
await FirebaseFirestore.instance
    .collection('chat_rooms')
    .doc(chatId)
    .delete();
```

**6. Запити з умовами:**
```dart
// Сортування
FirebaseFirestore.instance
    .collection('messages')
    .orderBy('timestamp', descending: true)
    .limit(50)
    .snapshots();

// Фільтрація
FirebaseFirestore.instance
    .collection('chat_rooms')
    .where('lastMessageTime', isGreaterThan: yesterday)
    .snapshots();
```

**Спеціальні значення:**
- `FieldValue.serverTimestamp()` - серверний час (автоматично встановлюється Firebase)
- `FieldValue.delete()` - видалити поле
- `FieldValue.arrayUnion([...])` - додати до масиву
- `FieldValue.arrayRemove([...])` - видалити з масиву

**Типи даних:**
- String, Number, Boolean
- Map (об'єкт)
- List (масив)
- Timestamp (дата/час)
- GeoPoint (геолокація)
- Reference (посилання на інший документ)

---

### 4. Firebase Analytics (`firebase_analytics`)

**Призначення:** Збір аналітичних даних про використання додатку.

**Використання в проєкті:**
```dart
// Логування подій
FirebaseAnalytics.instance.logEvent(name: 'login');
FirebaseAnalytics.instance.logEvent(name: 'register');

// Логування з параметрами
FirebaseAnalytics.instance.logEvent(
  name: 'message_sent',
  parameters: {
    'chat_id': chatId,
    'message_length': text.length,
  },
);
```

**Що відстежується:**
- Події користувачів (login, register, message_sent)
- Екрани, які відвідуються
- Помилки та винятки
- Користувацькі параметри

---

### 5. Firebase Crashlytics (`firebase_crashlytics`)

**Призначення:** Збір та аналіз звітів про збої та помилки додатку.

**Використання в проєкті:**
```dart
// Налаштування обробки помилок
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

// Обробка асинхронних помилок
runZonedGuarded<Future<void>>(
  () async => runApp(const MiniChatApp()),
  (error, stack) => FirebaseCrashlytics.instance.recordError(
    error, 
    stack, 
    fatal: true,
  ),
);

// Логування подій
await FirebaseCrashlytics.instance.log('Manual test crash');

// Тестовий збій
FirebaseCrashlytics.instance.crash();
```

**Що робить:**
- Автоматично збирає звіти про збої
- Надає stack trace для діагностики
- Групує подібні помилки
- Надсилає звіти в Firebase Console

---

## 🎨 ВІДЖЕТИ ДЛЯ РОБОТИ З FIREBASE

### 1. StreamBuilder

**Призначення:** Віджет, який автоматично оновлює UI при зміні даних у Stream (потоку даних).

**Синтаксис:**
```dart
StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('chat_rooms')
      .snapshots(),
  builder: (context, snapshot) {
    // snapshot має стани: connectionState, hasData, hasError, data
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    }
    
    if (snapshot.hasError) {
      return Text('Помилка: ${snapshot.error}');
    }
    
    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return Text('Немає даних');
    }
    
    final docs = snapshot.data!.docs;
    return ListView.builder(
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final data = doc.data() as Map<String, dynamic>;
        return ListTile(title: Text(data['name']));
      },
    );
  },
)
```

**Стани StreamBuilder:**
- `ConnectionState.waiting` - очікування даних
- `ConnectionState.active` - отримання даних
- `ConnectionState.done` - потік завершено

**Використання в проєкті:**
- Список чатів (`chats_screen.dart`)
- Список повідомлень (`chat_room_screen.dart`)
- Збережені повідомлення (`saved_messages_screen.dart`)

**Переваги:**
- Автоматичне оновлення UI при зміні даних
- Не потрібно вручну оновлювати дані
- Real-time синхронізація між клієнтами

---

### 2. QuerySnapshot

**Призначення:** Результат запиту до колекції Firestore, що містить масив документів.

**Властивості:**
- `docs` - список DocumentSnapshot
- `size` - кількість документів
- `metadata` - метадані запиту

**Використання:**
```dart
StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('chat_rooms')
      .snapshots(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return SizedBox();
    
    final querySnapshot = snapshot.data!;
    final docs = querySnapshot.docs; // List<QueryDocumentSnapshot>
    
    return ListView.builder(
      itemCount: querySnapshot.size,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final data = doc.data() as Map<String, dynamic>;
        return Text(data['name']);
      },
    );
  },
)
```

---

### 3. DocumentSnapshot

**Призначення:** Результат читання одного документа з Firestore.

**Властивості:**
- `id` - ID документа
- `data()` - дані документа (Map<String, dynamic>?)
- `exists` - чи існує документ
- `reference` - посилання на документ

**Використання:**
```dart
StreamBuilder<DocumentSnapshot>(
  stream: FirebaseFirestore.instance
      .collection('chat_rooms')
      .doc(chatId)
      .snapshots(),
  builder: (context, snapshot) {
    if (!snapshot.hasData || !snapshot.data!.exists) {
      return Text('Документ не знайдено');
    }
    
    final doc = snapshot.data!;
    final data = doc.data() as Map<String, dynamic>?;
    
    if (data == null) return SizedBox();
    
    return Text(data['name'] ?? 'Без назви');
  },
)
```

---

## 🎯 ОСНОВНІ FLUTTER ВІДЖЕТИ В ПРОЄКТІ

### Layout віджети

#### 1. Scaffold
**Призначення:** Базовий контейнер для Material Design екранів.

**Використання:**
```dart
Scaffold(
  appBar: AppBar(title: Text('Заголовок')),
  body: Center(child: Text('Контент')),
  bottomNavigationBar: NavigationBar(...),
)
```

#### 2. Column / Row
**Призначення:** Розташування віджетів вертикально (Column) або горизонтально (Row).

```dart
Column(
  children: [
    Text('Елемент 1'),
    Text('Елемент 2'),
  ],
)

Row(
  children: [
    Icon(Icons.star),
    Text('Рейтинг'),
  ],
)
```

#### 3. Container
**Призначення:** Універсальний контейнер з можливістю стилізації.

```dart
Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.blue,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [...],
  ),
  child: Text('Текст'),
)
```

#### 4. Expanded / Flexible
**Призначення:** Займає доступний простір в Row/Column.

```dart
Row(
  children: [
    Icon(Icons.star),
    Expanded(
      child: Text('Текст займає весь доступний простір'),
    ),
    Icon(Icons.favorite),
  ],
)
```

### Списки та дані

#### 5. ListView.builder
**Призначення:** Ефективне відображення списків (створює елементи "на льоту").

```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ListTile(title: Text(items[index]));
  },
)
```

#### 6. Card
**Призначення:** Material Design картка для відображення інформації.

```dart
Card(
  elevation: 2,
  child: ListTile(
    leading: Icon(Icons.chat),
    title: Text('Назва чату'),
    subtitle: Text('Останнє повідомлення'),
  ),
)
```

### Форми та введення

#### 7. TextField / TextFormField
**Призначення:** Поле для введення тексту.

```dart
TextField(
  controller: _controller,
  decoration: InputDecoration(
    hintText: 'Введіть текст',
    border: OutlineInputBorder(),
  ),
  onSubmitted: (value) {
    // Обробка введеного тексту
  },
)
```

#### 8. Form
**Призначення:** Контейнер для полів форми з валідацією.

```dart
Form(
  key: _formKey,
  child: Column(
    children: [
      TextFormField(
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Поле обов\'язкове';
          }
          return null;
        },
      ),
      ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            // Форма валідна
          }
        },
        child: Text('Відправити'),
      ),
    ],
  ),
)
```

### Діалоги та сповіщення

#### 9. AlertDialog
**Призначення:** Модальне діалогове вікно.

```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Підтвердження'),
    content: Text('Ви впевнені?'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('Скасувати'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context, true),
        child: Text('Підтвердити'),
      ),
    ],
  ),
);
```

#### 10. SnackBar
**Призначення:** Тимчасове повідомлення внизу екрану.

```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Повідомлення збережено'),
    duration: Duration(seconds: 2),
    behavior: SnackBarBehavior.floating,
  ),
);
```

### Кнопки

#### 11. ElevatedButton
**Призначення:** Кнопка з ефектом підняття.

```dart
ElevatedButton(
  onPressed: () {
    // Дія
  },
  child: Text('Натиснути'),
)
```

#### 12. IconButton
**Призначення:** Кнопка з іконкою.

```dart
IconButton(
  icon: Icon(Icons.send),
  onPressed: () {
    // Дія
  },
)
```

### Інші корисні віджети

#### 13. SafeArea
**Призначення:** Додає відступи для системних елементів (notch, status bar).

```dart
SafeArea(
  child: Column(
    children: [...],
  ),
)
```

#### 14. Padding / SizedBox
**Призначення:** Додавання відступів.

```dart
Padding(
  padding: EdgeInsets.all(16),
  child: Text('Текст'),
)

SizedBox(height: 20) // Простір між елементами
```

#### 15. CircularProgressIndicator
**Призначення:** Індикатор завантаження.

```dart
CircularProgressIndicator()
```

---

## 💡 ПРАКТИЧНІ ПРИКЛАДИ ВИКОРИСТАННЯ

### Приклад 1: Список чатів з real-time оновленням

```dart
StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('chat_rooms')
      .orderBy('lastMessageTime', descending: true)
      .snapshots(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (snapshot.hasError) {
      return Center(child: Text('Помилка: ${snapshot.error}'));
    }
    
    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return Center(child: Text('Немає чатів'));
    }
    
    final chats = snapshot.data!.docs;
    return ListView.builder(
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];
        final data = chat.data() as Map<String, dynamic>;
        return Card(
          child: ListTile(
            title: Text(data['name'] ?? 'Без назви'),
            subtitle: Text(data['lastMessage']?['text'] ?? ''),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatRoomScreen(
                    chatId: chat.id,
                    chatName: data['name'],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  },
)
```

### Приклад 2: Відправка повідомлення

```dart
Future<void> _sendMessage() async {
  final text = _controller.text.trim();
  if (text.isEmpty) return;
  
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  
  try {
    // Додати повідомлення
    await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(chatId)
        .collection('messages')
        .add({
      'text': text,
      'sender': user.email,
      'senderId': user.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'reactions': {},
    });
    
    // Оновити інформацію про останнє повідомлення
    await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(chatId)
        .update({
      'lastMessage': {
        'text': text,
        'sender': user.email,
      },
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
    
    _controller.clear();
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Помилка: $e')),
    );
  }
}
```

### Приклад 3: Аутентифікація користувача

```dart
Future<void> _signIn() async {
  try {
    final credential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
    
    // Логування події
    FirebaseAnalytics.instance.logEvent(name: 'login');
    
    // Перехід на екран чатів
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => ChatsScreen()),
    );
  } on FirebaseAuthException catch (e) {
    String message = 'Помилка авторизації';
    switch (e.code) {
      case 'user-not-found':
        message = 'Користувач не знайдений';
        break;
      case 'wrong-password':
        message = 'Невірний пароль';
        break;
      case 'invalid-email':
        message = 'Невірний email';
        break;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
```

### Приклад 4: Додавання реакції до повідомлення

```dart
Future<void> _addReaction(String messageId, String emoji) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  
  final messageRef = FirebaseFirestore.instance
      .collection('chat_rooms')
      .doc(chatId)
      .collection('messages')
      .doc(messageId);
  
  final messageDoc = await messageRef.get();
  if (!messageDoc.exists) return;
  
  final data = messageDoc.data() as Map<String, dynamic>;
  final reactions = Map<String, dynamic>.from(data['reactions'] ?? {});
  final emojiReactions = List<String>.from(reactions[emoji] ?? []);
  
  if (emojiReactions.contains(user.uid)) {
    // Видалити реакцію
    emojiReactions.remove(user.uid);
    if (emojiReactions.isEmpty) {
      reactions.remove(emoji);
    } else {
      reactions[emoji] = emojiReactions;
    }
  } else {
    // Додати реакцію
    emojiReactions.add(user.uid);
    reactions[emoji] = emojiReactions;
  }
  
  await messageRef.update({'reactions': reactions});
}
```

---

## 🔐 ПРАВИЛА БЕЗПЕКИ FIRESTORE

### Security Rules (приклад)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Чати доступні тільки авторизованим користувачам
    match /chat_rooms/{chatId} {
      allow read, write: if request.auth != null;
      
      // Повідомлення доступні тільки авторизованим
      match /messages/{messageId} {
        allow read, write: if request.auth != null;
      }
    }
    
    // Збережені повідомлення доступні тільки власнику
    match /saved_messages/{savedId} {
      allow read, write: if request.auth != null 
        && resource.data.userId == request.auth.uid;
    }
  }
}
```

---

## 📊 СТРУКТУРА ДАНИХ В ПРОЄКТІ

### Колекція `chat_rooms`
```json
{
  "chatId": {
    "name": "Назва чату",
    "lastMessage": {
      "text": "Останнє повідомлення",
      "sender": "email@example.com"
    },
    "lastMessageTime": "2024-01-15T10:30:00Z",
    "messages": {
      "messageId": {
        "text": "Текст повідомлення",
        "sender": "email@example.com",
        "senderId": "userId",
        "timestamp": "2024-01-15T10:30:00Z",
        "reactions": {
          "👍": ["userId1", "userId2"],
          "❤️": ["userId3"]
        }
      }
    }
  }
}
```

### Колекція `saved_messages`
```json
{
  "savedId": {
    "userId": "userId",
    "messageId": "messageId",
    "chatId": "chatId",
    "text": "Текст повідомлення",
    "originalSender": "email@example.com",
    "savedAt": "2024-01-15T10:30:00Z"
  }
}
```

---

## ✅ ПІДСУМОК

### Ключові концепції:

1. **Firebase Core** - ініціалізація Firebase
2. **Firebase Auth** - аутентифікація користувачів
3. **Cloud Firestore** - база даних real-time
4. **StreamBuilder** - автоматичне оновлення UI
5. **QuerySnapshot / DocumentSnapshot** - робота з даними
6. **Firebase Analytics** - збір аналітики
7. **Firebase Crashlytics** - звіти про помилки

### Переваги використання Firebase:

✅ Швидка розробка без backend
✅ Real-time синхронізація
✅ Автоматичне масштабування
✅ Вбудована безпека
✅ Кросплатформенність

### Найважливіші віджети:

1. **StreamBuilder** - для real-time даних
2. **ListView.builder** - для списків
3. **TextField** - для введення
4. **Card** - для відображення інформації
5. **Scaffold** - базова структура екрану

---

*Документ створено для підготовки до захисту лабораторної роботи*

