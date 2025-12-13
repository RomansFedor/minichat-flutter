import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/chats_repository.dart';
import 'create_chat_event.dart';
import 'create_chat_state.dart';

class CreateChatBloc extends Bloc<CreateChatEvent, CreateChatState> {
  final ChatsRepository _chatsRepository;

  CreateChatBloc({
    required ChatsRepository chatsRepository,
  })  : _chatsRepository = chatsRepository,
        super(const CreateChatInitialState()) {
    on<CreateChatRequestedEvent>(_onCreateChatRequested);
    on<CreateChatResetEvent>(_onCreateChatReset);
  }

  Future<void> _onCreateChatRequested(
    CreateChatRequestedEvent event,
    Emitter<CreateChatState> emit,
  ) async {
    emit(const CreateChatCreatingState());

    try {
      final chatId = await _chatsRepository.createChat(
        name: event.chatName,
      );

      emit(CreateChatSuccessState(
        chatId: chatId,
        chatName: event.chatName,
      ));
    } catch (e) {
      emit(CreateChatErrorState(e.toString()));
    }
  }

  void _onCreateChatReset(
    CreateChatResetEvent event,
    Emitter<CreateChatState> emit,
  ) {
    emit(const CreateChatInitialState());
  }
}
