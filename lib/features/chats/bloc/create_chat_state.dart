import 'package:equatable/equatable.dart';

abstract class CreateChatState extends Equatable {
  const CreateChatState();

  @override
  List<Object?> get props => [];
}

class CreateChatInitialState extends CreateChatState {
  const CreateChatInitialState();
}

class CreateChatCreatingState extends CreateChatState {
  const CreateChatCreatingState();
}

class CreateChatSuccessState extends CreateChatState {
  final String chatId;
  final String chatName;

  const CreateChatSuccessState({
    required this.chatId,
    required this.chatName,
  });

  @override
  List<Object?> get props => [chatId, chatName];
}

class CreateChatErrorState extends CreateChatState {
  final String error;

  const CreateChatErrorState(this.error);

  @override
  List<Object?> get props => [error];
}
