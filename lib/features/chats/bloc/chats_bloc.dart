import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/chat_model.dart';
import '../repositories/chats_repository.dart';
import 'chats_event.dart';
import 'chats_state.dart';

class ChatsBloc extends Bloc<ChatsEvent, ChatsState> {
  final ChatsRepository _chatsRepository;

  ChatsBloc({
    ChatsRepository? chatsRepository,
  })  : _chatsRepository = chatsRepository ?? FirestoreChatsRepository(),
        super(const ChatsInitialState()) {
    on<LoadChatsEvent>(_onLoadChatsEvent);
    on<RefreshChatsEvent>(_onRefreshChatsEvent);
    on<CreateChatEvent>(_onCreateChatEvent);
  }

  Future<void> _onLoadChatsEvent(
    LoadChatsEvent event,
    Emitter<ChatsState> emit,
  ) async {
    emit(ChatsLoadingState(data: state.data));

    try {
      final chats = await _chatsRepository.getChats();
      emit(ChatsDataState(data: chats));
      
      await emit.forEach(
        _chatsRepository.getChatsStream(),
        onData: (updatedChats) => ChatsDataState(data: updatedChats),
        onError: (error, stackTrace) => ChatsErrorState(
          error: error.toString(),
          data: state.data,
        ),
      );
    } catch (e) {
      emit(ChatsErrorState(
        error: e.toString(),
        data: state.data,
      ));
    }
  }

  Future<void> _onRefreshChatsEvent(
    RefreshChatsEvent event,
    Emitter<ChatsState> emit,
  ) async {
    emit(ChatsLoadingState(data: state.data));

    try {
      final chats = await _chatsRepository.getChats();
      
      emit(ChatsDataState(data: chats));
    } catch (e) {
      emit(ChatsErrorState(
        error: e.toString(),
        data: state.data,
      ));
    }
  }

  Future<void> _onCreateChatEvent(
    CreateChatEvent event,
    Emitter<ChatsState> emit,
  ) async {
    try {
      await _chatsRepository.createChat(name: event.chatName);
      
      add(const RefreshChatsEvent());
    } catch (e) {
      emit(ChatsErrorState(
        error: 'Помилка створення чату: ${e.toString()}',
        data: state.data,
      ));
    }
  }
}
