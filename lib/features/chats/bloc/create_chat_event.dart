import 'package:equatable/equatable.dart';

abstract class CreateChatEvent extends Equatable {
  const CreateChatEvent();

  @override
  List<Object?> get props => [];
}

class CreateChatRequestedEvent extends CreateChatEvent {
  final String chatName;

  const CreateChatRequestedEvent(this.chatName);

  @override
  List<Object?> get props => [chatName];
}

class CreateChatResetEvent extends CreateChatEvent {
  const CreateChatResetEvent();
}
