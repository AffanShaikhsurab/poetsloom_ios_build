import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:test_app/model.dart';
import 'package:test_app/services/contract.dart';

enum AuthorPoemsStatus { initial, loading, refreshing, success, failure }

class AuthorPoemsState extends Equatable {
  final List<Poem> poems;
  final AuthorPoemsStatus status;
  final String? error;
  final bool hasMore;
  final bool isRefreshing;

  const AuthorPoemsState({
    this.poems = const [],
    this.status = AuthorPoemsStatus.initial,
    this.error,
    this.hasMore = true,
    this.isRefreshing = false,
  });

  AuthorPoemsState copyWith({
    List<Poem>? poems,
    AuthorPoemsStatus? status,
    String? error,
    bool? hasMore,
    bool? isRefreshing,
  }) {
    return AuthorPoemsState(
      poems: poems ?? this.poems,
      status: status ?? this.status,
      error: error ?? this.error,
      hasMore: hasMore ?? this.hasMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [poems, status, error, hasMore, isRefreshing];
}

class AuthorPoemsCubit extends Cubit<AuthorPoemsState> {
  final PoetsLoomService _poetsLoomService;
  static const int _pageSize = 10;
  
  // Add debounce timer
  Timer? _debounceTimer;

  AuthorPoemsCubit({
    required PoetsLoomService poetsLoomService,
  })  : _poetsLoomService = poetsLoomService,
        super(const AuthorPoemsState());

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }

  Future<void> loadAuthorPoems() async {
    if (state.status == AuthorPoemsStatus.loading) return;

    emit(state.copyWith(
      status: AuthorPoemsStatus.loading,
      error: null,
    ));

    try {
      final poems = await _getAuthorPoemsWithRetry();
      if (isClosed) return;
      
      emit(state.copyWith(
        poems: poems,
        status: AuthorPoemsStatus.success,
        hasMore: poems.length >= _pageSize,
      ));
    } catch (e) {
      if (isClosed) return;
      
      emit(state.copyWith(
        status: AuthorPoemsStatus.failure,
        error: _getErrorMessage(e),
      ));
    }
  }

  Future<void> refreshPoems() async {
    if (state.isRefreshing) return;

    emit(state.copyWith(
      status: AuthorPoemsStatus.refreshing,
      isRefreshing: true,
    ));

    try {
      final poems = await _getAuthorPoemsWithRetry();
      if (isClosed) return;
      
      emit(state.copyWith(
        poems: poems,
        status: AuthorPoemsStatus.success,
        isRefreshing: false,
      ));
    } catch (e) {
      if (isClosed) return;
      
      emit(state.copyWith(
        status: AuthorPoemsStatus.failure,
        error: _getErrorMessage(e),
        isRefreshing: false,
      ));
    }
  }

  // Add retry mechanism
  Future<List<Poem>> _getAuthorPoemsWithRetry({int retries = 3}) async {
    for (int i = 0; i < retries; i++) {
      try {
        return await getAuthorPoems();
      } catch (e) {
        if (i == retries - 1) rethrow;
        await Future.delayed(Duration(seconds: i + 1));
      }
    }
    throw Exception('Failed to load poems after $retries attempts');
  }

  Future<List<Poem>> getAuthorPoems() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString("user_data");
    
    if (userData == null) {
      throw const AuthException('User data not found');
    }

    final user = json.decode(userData);
    final userId = user["id"];

    if (userId == null) {
      throw const AuthException('User ID not found');
    }

    final poemsData = await _poetsLoomService.getAuthorPoems(
      BigInt.from(int.parse(userId))
    );
    
    return await _processPoems(poemsData);
  }

  Future<List<Poem>> _processPoems(List<dynamic> poemsData) async {
    final transformedPoems = await Future.wait(
      poemsData.map((poemData) async {
        try {
          return await _transformPoemData(poemData);
        } catch (e) {
          print("Error processing poem: $e");
          return null;
        }
      }),
    );

    return transformedPoems.whereType<Poem>().toList();
  }

  Future<Poem?> _transformPoemData(dynamic poemData) async {
    try {
      final date = _convertBlockchainTimestamp(poemData[4]);
      final content = await _poetsLoomService.retrievePoemContent(poemData[1]);
      final avatarUrl = await _poetsLoomService.getProfile(
        int.parse(poemData[3]!.toString())
      );
      final likes = await _poetsLoomService.retrieveLikes(poemData[1]);

      if (content == null) throw Exception('Failed to retrieve poem content');

      final poemContent = content["content"] as String;
      final poemTitle = content["title"] as String;
      final rewards = content["rewards"] as int? ?? 0;
      final poemTags = (content["tags"] as List?)?.cast<String>() ?? [];

      return Poem(
        id: poemData[5]?.toString() ?? 'unknown',
        title: poemTitle,
        content: poemContent,
        authorAddress: poemData[2]?.toString() ?? 'unknown',
        authorId: int.parse(poemData[3]!.toString()),
        authorName: poemData[8]?.toString() ?? 'Anonymous',
        authorUsername: poemData[8]?.toString() ?? 'anonymous',
        poemHash: poemData[1]?.toString() ?? 'unknown',
        authorAvatar: avatarUrl,
        likes: likes ?? 0,
        rewards: rewards,
        tags: poemTags,
        isLiked: false,
        createdAt: date,
        liked: poemData[7] == 0 
          ? [BigInt.from(0)] 
          : (poemData[7] as List).cast<BigInt>(),
      );
    } catch (e) {
      print("Error transforming poem data: $e");
      return null;
    }
  }

  // Add debounced like functionality
  Future<void> likePoem(Poem poem) async {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        final updatedPoems = state.poems.map((p) {
          if (p.id == poem.id) {
            return p.copyWith(
              isLiked: !p.isLiked,
              likes: p.isLiked ? p.likes - 1 : p.likes + 1,
            );
          }
          return p;
        }).toList();

        emit(state.copyWith(poems: updatedPoems));

        await _poetsLoomService.likePoem(
          poem.poemHash,
          poem.likes + 1,
          int.parse(poem.id)
        );
      } catch (e) {
        // Revert on failure
        emit(state.copyWith(
          poems: state.poems,
          error: 'Failed to like poem',
        ));
      }
    });
  }

  Future<void> updatePoem({
    required String title,
    required String content,
    required String hash,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = await json.decode(prefs.getString("user_data")!);
      final userId = userData["id"] ?? "Anonymous";

      await _poetsLoomService.updatePoem(
        title,
        content,
        int.parse(userId),
        hash
      );

      // Refresh poems after update
      await refreshPoems();
    } catch (e) {
      emit(state.copyWith(
        error: 'Failed to update poem: ${_getErrorMessage(e)}',
      ));
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is AuthException) return error.message;
    return error.toString().replaceAll('Exception:', '').trim();
  }

  DateTime _convertBlockchainTimestamp(dynamic timestamp) {
    try {
      if (timestamp is BigInt) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp.toInt() * 1000);
      } else if (timestamp is int) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      } else if (timestamp is String) {
        final timestampInt = int.parse(timestamp);
        return DateTime.fromMillisecondsSinceEpoch(timestampInt * 1000);
      }
    } catch (e) {
      print("Error converting timestamp: $e");
    }
    return DateTime.now();
  }
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  
  @override
  String toString() => message;
}