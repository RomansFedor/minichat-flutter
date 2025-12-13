import 'package:equatable/equatable.dart';

abstract class UpdateChatEvent extends Equatable {
  const UpdateChatEvent();

  @override
  List<Object?> get props => [];
}

class UpdateChatRequestedEvent extends UpdateChatEvent {
  final String chatId;
  final String? chatName;

  const UpdateChatRequestedEvent({
    required this.chatId,
    this.chatName,
  });

  @override
  List<Object?> get props => [chatId, chatName];
}

class UpdateChatResetEvent extends UpdateChatEvent {
  const UpdateChatResetEvent();
}
