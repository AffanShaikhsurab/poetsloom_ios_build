// comments_state.dart
import 'package:equatable/equatable.dart';
import 'package:test_app/model.dart';
// comments_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_app/model.dart';
import 'package:test_app/services/contract.dart';
enum CommentsStatus { initial, loading, success, failure }

class CommentsState extends Equatable {
  final List<Comment> comments;
  final CommentsStatus status;
  final String? error;

  const CommentsState({
    this.comments = const [],
    this.status = CommentsStatus.initial,
    this.error,
  });

  CommentsState copyWith({
    List<Comment>? comments,
    CommentsStatus? status,
    String? error,
  }) {
    return CommentsState(
      comments: comments ?? this.comments,
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [comments, status, error];
}



class CommentsCubit extends Cubit<CommentsState> {
  final PoetsLoomService _poetsLoomService;

  CommentsCubit({
    required PoetsLoomService poetsLoomService,
  })  : _poetsLoomService = poetsLoomService,
        super(const CommentsState());
  Future<void> loadComments(int poemId) async {
    emit(state.copyWith(status: CommentsStatus.loading));
    
    try {
      final comments = await _poetsLoomService.getComments(poemId);
      emit(state.copyWith(
        comments: comments,
        status: CommentsStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CommentsStatus.failure,
        error: e.toString(),
      ));
    }
  }

  Future<void> addComment(String content , int poemId) async {
    try {
      await _poetsLoomService.addComment(poemId, content);
      // Reload comments after adding
      await loadComments(poemId);
    } catch (e) {
      emit(state.copyWith(
        status: CommentsStatus.failure,
        error: e.toString(),
      ));
    }
  }
}