import 'package:equatable/equatable.dart';

abstract class ChatsEvent extends Equatable {
  const ChatsEvent();

  @override
  List<Object?> get props => [];
}

class LoadChatsEvent extends ChatsEvent {
  const LoadChatsEvent();
}

class RefreshChatsEvent extends ChatsEvent {
  const RefreshChatsEvent();
}

class CreateChatEvent extends ChatsEvent {
  final String chatName;

  const CreateChatEvent(this.chatName);

  @override
  List<Object?> get props => [chatName];
}
