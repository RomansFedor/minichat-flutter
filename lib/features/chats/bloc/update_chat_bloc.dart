import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/chats_repository.dart';
import 'update_chat_event.dart';
import 'update_chat_state.dart';

class UpdateChatBloc extends Bloc<UpdateChatEvent, UpdateChatState> {
  final ChatsRepository _chatsRepository;

  UpdateChatBloc({
    required ChatsRepository chatsRepository,
  })  : _chatsRepository = chatsRepository,
        super(const UpdateChatInitialState()) {
    on<UpdateChatRequestedEvent>(_onUpdateChatRequested);
    on<UpdateChatResetEvent>(_onUpdateChatReset);
  }

  Future<void> _onUpdateChatRequested(
    UpdateChatRequestedEvent event,
    Emitter<UpdateChatState> emit,
  ) async {
    emit(const UpdateChatUpdatingState());

    try {
      await _chatsRepository.updateChat(
        chatId: event.chatId,
        name: event.chatName,
      );

      emit(UpdateChatSuccessState(chatId: event.chatId));
    } catch (e) {
      emit(UpdateChatErrorState(e.toString()));
    }
  }

  void _onUpdateChatReset(
    UpdateChatResetEvent event,
    Emitter<UpdateChatState> emit,
  ) {
    emit(const UpdateChatInitialState());
  }
}
