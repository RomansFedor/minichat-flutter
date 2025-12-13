import 'package:equatable/equatable.dart';

abstract class UpdateChatState extends Equatable {
  const UpdateChatState();

  @override
  List<Object?> get props => [];
}

class UpdateChatInitialState extends UpdateChatState {
  const UpdateChatInitialState();
}

class UpdateChatUpdatingState extends UpdateChatState {
  const UpdateChatUpdatingState();
}

class UpdateChatSuccessState extends UpdateChatState {
  final String chatId;

  const UpdateChatSuccessState({required this.chatId});

  @override
  List<Object?> get props => [chatId];
}

class UpdateChatErrorState extends UpdateChatState {
  final String error;

  const UpdateChatErrorState(this.error);

  @override
  List<Object?> get props => [error];
}
