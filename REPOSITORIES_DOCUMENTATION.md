# Документація репозиторіїв та BLoC

## Репозиторії

### 1. ChatsRepository

**Розташування:** `lib/features/chats/repositories/chats_repository.dart`

**Абстрактний інтерфейс:**
```dart
abstract class ChatsRepository {
  Future<List<ChatModel>> getChats();
  Stream<List<ChatModel>> getChatsStream();
  Future<ChatModel?> getChatById(String chatId);
  Future<String> createChat({required String name});
  Future<void> updateChat({required String chatId, String? name});
  Future<void> deleteChat(String chatId);
  Future<void> updateLastMessage({...});
}
```

**Реалізація:** `FirestoreChatsRepository`

**Методи:**

- `getChats()` - отримує список чатів один раз
- `getChatsStream()` - потік чатів для реактивного оновлення
- `getChatById(String chatId)` - отримує конкретний чат
- `createChat({required String name})` - створює новий чат (автоматично додає createdBy з поточного користувача)
- `updateChat({required String chatId, String? name})` - оновлює назву чату (тільки для власника)
- `deleteChat(String chatId)` - видаляє чат та всі повідомлення в ньому (тільки для власника)
- `updateLastMessage({...})` - оновлює інформацію про останнє повідомлення

**Приклад використання:**
```dart
final repository = FirestoreChatsRepository();

// Створити чат
final chatId = await repository.createChat(name: 'Новий чат');

// Отримати чати
final chats = await repository.getChats();

// Підписатися на оновлення
repository.getChatsStream().listen((chats) {
  print('Оновлено: ${chats.length} чатів');
});
```

---

### 2. MessagesRepository

**Розташування:** `lib/features/chats/repositories/messages_repository.dart`

**Абстрактний інтерфейс:**
```dart
abstract class MessagesRepository {
  Stream<List<MessageModel>> getMessagesStream(String chatId);
  Future<List<MessageModel>> getMessages(String chatId, {int? limit});
  Future<String> createMessage({required String chatId, required String text});
  Future<void> updateMessage({...});
  Future<void> deleteMessage({...});
  Future<void> addReaction({...});
  Future<void> removeReaction({...});
}
```

**Реалізація:** `FirestoreMessagesRepository`

**Методи:**

- `getMessagesStream(String chatId)` - потік повідомлень для чату
- `getMessages(String chatId, {int? limit})` - отримує повідомлення (з опціональним лімітом)
- `createMessage({required String chatId, required String text})` - створює повідомлення та оновлює lastMessage в чаті
- `updateMessage({...})` - оновлює текст повідомлення (тільки для автора)
- `deleteMessage({...})` - видаляє повідомлення (тільки для автора)
- `addReaction({...})` - додає реакцію на повідомлення
- `removeReaction({...})` - видаляє реакцію з повідомлення

**Приклад використання:**
```dart
final repository = FirestoreMessagesRepository();

// Надіслати повідомлення
final messageId = await repository.createMessage(
  chatId: 'chat123',
  text: 'Привіт!',
);

// Підписатися на повідомлення
repository.getMessagesStream('chat123').listen((messages) {
  print('Нові повідомлення: ${messages.length}');
});

// Додати реакцію
await repository.addReaction(
  chatId: 'chat123',
  messageId: messageId,
  emoji: '❤️',
);
```

---

### 3. SavedMessagesRepository

**Розташування:** `lib/features/chats/repositories/saved_messages_repository.dart`

**Абстрактний інтерфейс:**
```dart
abstract class SavedMessagesRepository {
  Stream<List<SavedMessageModel>> getSavedMessagesStream(String userId);
  Future<List<SavedMessageModel>> getSavedMessages(String userId);
  Future<String> saveMessage({...});
  Future<void> updateNote({...});
  Future<void> deleteSavedMessage(String savedMessageId);
}
```

**Реалізація:** `FirestoreSavedMessagesRepository`

**Методи:**

- `getSavedMessagesStream(String userId)` - потік збережених повідомлень
- `getSavedMessages(String userId)` - отримує збережені повідомлення
- `saveMessage({...})` - зберігає повідомлення (перевіряє, чи не збережено вже)
- `updateNote({...})` - оновлює примітку до збереженого повідомлення
- `deleteSavedMessage(String savedMessageId)` - видаляє збережене повідомлення

---

## BLoC для створення та редагування

### 1. CreateChatBloc

**Розташування:** `lib/features/chats/bloc/create_chat_bloc.dart`

**Події:**
- `CreateChatRequestedEvent(String chatName)` - створити чат
- `CreateChatResetEvent()` - скинути стан

**Стани:**
- `CreateChatInitialState` - початковий стан
- `CreateChatCreatingState` - створення чату (loading)
- `CreateChatSuccessState(chatId, chatName)` - успішне створення
- `CreateChatErrorState(String error)` - помилка

**Приклад використання:**
```dart
final createChatBloc = CreateChatBloc(
  chatsRepository: FirestoreChatsRepository(),
);

// Створити чат
createChatBloc.add(CreateChatRequestedEvent('Новий чат'));

// Слухати стани
createChatBloc.stream.listen((state) {
  if (state is CreateChatSuccessState) {
    print('Чат створено: ${state.chatId}');
  } else if (state is CreateChatErrorState) {
    print('Помилка: ${state.error}');
  }
});
```

---

### 2. UpdateChatBloc

**Розташування:** `lib/features/chats/bloc/update_chat_bloc.dart`

**Події:**
- `UpdateChatRequestedEvent(chatId, chatName)` - оновити чат
- `UpdateChatResetEvent()` - скинути стан

**Стани:**
- `UpdateChatInitialState` - початковий стан
- `UpdateChatUpdatingState` - оновлення чату (loading)
- `UpdateChatSuccessState(chatId)` - успішне оновлення
- `UpdateChatErrorState(String error)` - помилка

**Приклад використання:**
```dart
final updateChatBloc = UpdateChatBloc(
  chatsRepository: FirestoreChatsRepository(),
);

// Оновити чат
updateChatBloc.add(UpdateChatRequestedEvent(
  chatId: 'chat123',
  chatName: 'Нова назва',
));
```

---

## Інтеграція в застосунок

### Використання репозиторіїв у BLoC

Репозиторії інтегровані в BLoC через dependency injection:

```dart
// У main.dart
BlocProvider(
  create: (context) => ChatsBloc(
    chatsRepository: FirestoreChatsRepository(),
  ),
)

// У BLoC
class ChatsBloc extends Bloc<ChatsEvent, ChatsState> {
  final ChatsRepository _chatsRepository;

  ChatsBloc({ChatsRepository? chatsRepository})
    : _chatsRepository = chatsRepository ?? FirestoreChatsRepository(),
      super(const ChatsInitialState());
  
  // Використання репозиторію
  Future<void> _onLoadChats(...) async {
    final chats = await _chatsRepository.getChats();
    emit(ChatsDataState(data: chats));
  }
}
```

### Використання BLoC для створення чатів

```dart
// У UI
BlocProvider(
  create: (_) => CreateChatBloc(
    chatsRepository: FirestoreChatsRepository(),
  ),
  child: BlocConsumer<CreateChatBloc, CreateChatState>(
    listener: (context, state) {
      if (state is CreateChatSuccessState) {
        // Показати повідомлення про успіх
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Чат "${state.chatName}" створено!')),
        );
        // Скинути стан
        context.read<CreateChatBloc>().add(const CreateChatResetEvent());
      } else if (state is CreateChatErrorState) {
        // Показати помилку
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка: ${state.error}')),
        );
      }
    },
    builder: (context, state) {
      if (state is CreateChatCreatingState) {
        return CircularProgressIndicator();
      }
      return ElevatedButton(
        onPressed: () {
          context.read<CreateChatBloc>().add(
            CreateChatRequestedEvent('Новий чат'),
          );
        },
        child: Text('Створити чат'),
      );
    },
  ),
)
```

---

## Переваги використання репозиторіїв

1. **Розділення відповідальностей** - логіка роботи з даними відокремлена від UI
2. **Тестування** - легко створити mock-репозиторії для тестів
3. **Гнучкість** - можна легко змінити джерело даних (Firestore → REST API)
4. **Повторне використання** - репозиторії можуть використовуватися в різних місцях
5. **Обробка помилок** - централізована обробка помилок у репозиторіях

---

**Дата створення:** 2025  
**Версія:** 1.0

