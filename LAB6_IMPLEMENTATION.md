# Лабораторна робота №6 - Реалізація Firestore

## Звіт про виконання завдань

### Завдання 1: Підключення Firestore Database та створення колекцій ✅

#### Створені колекції:

1. **`chat_rooms`** - колекція чатів
   - Поля: `name`, `createdBy`, `createdAt`, `lastMessage`, `lastMessageTime`
   - Підколекція: `messages` - повідомлення в чаті

2. **`saved_messages`** - колекція збережених повідомлень
   - Поля: `userId`, `messageId`, `chatId`, `messageText`, `sender`, `savedAt`, `note`

**Документація:** `FIRESTORE_COLLECTIONS.md` містить повний опис всіх колекцій та полів.

---

### Завдання 2: Налаштування правил доступу ✅

Створено файл `firestore.rules` з правилами безпеки:

- **chat_rooms:** Читати можуть авторизовані користувачі, створювати/редагувати/видаляти - тільки власник (createdBy)
- **messages:** Читати можуть авторизовані, створювати/редагувати/видаляти - тільки відправник (senderId)
- **saved_messages:** Читати/створювати/редагувати/видаляти можуть тільки власник (userId)

**Файл:** `firestore.rules`

---

### Завдання 3: Репозиторії для роботи з колекціями ✅

#### Створені репозиторії:

1. **ChatsRepository** (`lib/features/chats/repositories/chats_repository.dart`)
   - `getChats()` - отримати список чатів
   - `getChatsStream()` - потік чатів для реактивного оновлення
   - `getChatById()` - отримати чат за ID
   - `createChat()` - створити новий чат
   - `updateChat()` - оновити чат
   - `deleteChat()` - видалити чат
   - `updateLastMessage()` - оновити інформацію про останнє повідомлення

2. **MessagesRepository** (`lib/features/chats/repositories/messages_repository.dart`)
   - `getMessagesStream()` - потік повідомлень
   - `getMessages()` - отримати повідомлення
   - `createMessage()` - створити повідомлення
   - `updateMessage()` - оновити повідомлення
   - `deleteMessage()` - видалити повідомлення
   - `addReaction()` / `removeReaction()` - робота з реакціями

3. **SavedMessagesRepository** (`lib/features/chats/repositories/saved_messages_repository.dart`)
   - `getSavedMessagesStream()` - потік збережених повідомлень
   - `getSavedMessages()` - отримати збережені повідомлення
   - `saveMessage()` - зберегти повідомлення
   - `updateNote()` - оновити примітку
   - `deleteSavedMessage()` - видалити збережене повідомлення

#### Створені моделі:

- `ChatModel` - модель чату
- `MessageModel` - модель повідомлення
- `SavedMessageModel` - модель збереженого повідомлення

**Документація:** `REPOSITORIES_DOCUMENTATION.md`

---

### Завдання 4: Використання репозиторіїв для завантаження даних ✅

Репозиторії інтегровані в існуючий код:

1. **ChatsBloc** оновлено для використання `ChatsRepository`:
   - Завантаження чатів через репозиторій
   - Використання потоку для реактивного оновлення
   - Створення чатів через репозиторій

2. **Моделі даних** оновлено з методами конвертації з/в Firestore

**Файли:**
- `lib/features/chats/bloc/chats_bloc.dart` - інтегрований репозиторій
- `lib/features/chats/models/chat_model.dart` - модель з конвертацією

---

### Завдання 5: Реалізація створення та редагування через BLoC ✅

#### Створені BLoC:

1. **CreateChatBloc** (`lib/features/chats/bloc/create_chat_bloc.dart`)
   - **Події:** `CreateChatRequestedEvent`, `CreateChatResetEvent`
   - **Стани:** 
     - `CreateChatInitialState`
     - `CreateChatCreatingState` (loading)
     - `CreateChatSuccessState` (успіх)
     - `CreateChatErrorState` (помилка)

2. **UpdateChatBloc** (`lib/features/chats/bloc/update_chat_bloc.dart`)
   - **Події:** `UpdateChatRequestedEvent`, `UpdateChatResetEvent`
   - **Стани:**
     - `UpdateChatInitialState`
     - `UpdateChatUpdatingState` (loading)
     - `UpdateChatSuccessState` (успіх)
     - `UpdateChatErrorState` (помилка)

**Приклад використання:**
```dart
// Створення чату
final createChatBloc = CreateChatBloc(
  chatsRepository: FirestoreChatsRepository(),
);
createChatBloc.add(CreateChatRequestedEvent('Новий чат'));

// Редагування чату
final updateChatBloc = UpdateChatBloc(
  chatsRepository: FirestoreChatsRepository(),
);
updateChatBloc.add(UpdateChatRequestedEvent(
  chatId: 'chat123',
  chatName: 'Оновлена назва',
));
```

---

### Завдання 6: Firebase Storage (не обов'язково) ⚪

Firebase Storage не реалізовано, оскільки в поточній версії застосунку не потрібне збереження файлів. Якщо в майбутньому знадобиться завантажувати зображення або файли, можна додати:

- `firebase_storage` пакет
- Репозиторій для роботи з Storage
- BLoC для завантаження файлів

---

### Завдання 7: REST API (не обов'язково) ⚪

REST API не реалізовано, оскільки застосунок використовує тільки Firebase сервіси.

---

## Структура файлів

```
lib/
├── features/
│   └── chats/
│       ├── models/
│       │   ├── chat_model.dart
│       │   ├── message_model.dart
│       │   └── saved_message_model.dart
│       ├── repositories/
│       │   ├── chats_repository.dart
│       │   ├── messages_repository.dart
│       │   └── saved_messages_repository.dart
│       └── bloc/
│           ├── chats_bloc.dart (оновлено)
│           ├── create_chat_bloc.dart (ново)
│           ├── update_chat_bloc.dart (ново)
│           └── ...
├── core/
│   └── auth_repository.dart
└── ...

Документація:
├── FIRESTORE_COLLECTIONS.md
├── firestore.rules
├── REPOSITORIES_DOCUMENTATION.md
├── FIREBASE_THEORY.md
└── LAB6_IMPLEMENTATION.md (цей файл)
```

---

## Основні досягнення

✅ Створено структуровану систему репозиторіїв  
✅ Реалізовано паттерн Repository для абстракції доступу до даних  
✅ Інтегровано репозиторії з BLoC для керування станом  
✅ Створено BLoC для створення та редагування чатів  
✅ Налаштовано правила безпеки Firestore  
✅ Документовано всі колекції та їх поля  
✅ Створено теоретичну документацію  

---

## Наступні кроки (опціонально)

1. Додати Firebase Storage для завантаження файлів
2. Додати пагінацію для великих списків
3. Реалізувати офлайн-режим з кешуванням
4. Додати unit-тести для репозиторіїв
5. Додати інтеграційні тести для BLoC

---

**Дата створення:** 2025  
**Версія:** 1.0

