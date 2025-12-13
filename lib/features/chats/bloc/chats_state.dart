import 'package:equatable/equatable.dart';
import '../models/chat_model.dart';

abstract class ChatsState extends Equatable {
  final List<ChatModel> data;

  const ChatsState({required this.data});

  @override
  List<Object?> get props => [data];
}

class ChatsInitialState extends ChatsState {
  const ChatsInitialState() : super(data: const []);
}

class ChatsLoadingState extends ChatsState {
  const ChatsLoadingState({required super.data});
}

class ChatsDataState extends ChatsState {
  const ChatsDataState({required super.data});
}

class ChatsErrorState extends ChatsState {
  final String error;

  const ChatsErrorState({
    required this.error,
    required super.data,
  });

  @override
  List<Object?> get props => [error, data];
}
