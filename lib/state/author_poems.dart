import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:test_app/model.dart';
// lib/cubits/author_poems/author_poems_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:test_app/services/contract.dart';
enum AuthorPoemsStatus { initial, loading, success, failure }

class AuthorPoemsState extends Equatable {
  final List<Poem> poems;
  final AuthorPoemsStatus status;
  final String? error;
  final bool hasMore;

  const AuthorPoemsState({
    this.poems = const [],
    this.status = AuthorPoemsStatus.initial,
    this.error,
    this.hasMore = true,
  });

  AuthorPoemsState copyWith({
    List<Poem>? poems,
    AuthorPoemsStatus? status,
    String? error,
    bool? hasMore,
  }) {
    return AuthorPoemsState(
      poems: poems ?? this.poems,
      status: status ?? this.status,
      error: error ?? this.error,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  @override
  List<Object?> get props => [poems, status, error, hasMore];
}



class AuthorPoemsCubit extends Cubit<AuthorPoemsState> {
  final PoetsLoomService _poetsLoomService;
  static const int _pageSize = 10;

  AuthorPoemsCubit({
    required PoetsLoomService poetsLoomService,
  })  : _poetsLoomService = poetsLoomService,
        super(const AuthorPoemsState());

  Future<void> loadAuthorPoems() async {
    if (state.status == AuthorPoemsStatus.loading) return;

    emit(state.copyWith(
      status: AuthorPoemsStatus.loading,
      error: null,
    ));

    try {
      final poems = await getAuthorPoems();
      emit(state.copyWith(
        poems: poems,
        status: AuthorPoemsStatus.success,
        hasMore: poems.length >= _pageSize,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthorPoemsStatus.failure,
        error: 'Failed to load your poems. Please try again.',
      ));
    }
  }

  Future<void> refreshPoems() async {
    emit(state.copyWith(status: AuthorPoemsStatus.loading));
    try {
      final poems = await getAuthorPoems();
      emit(state.copyWith(
        poems: poems,
        status: AuthorPoemsStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthorPoemsStatus.failure,
        error: 'Failed to refresh poems',
      ));
    }
  }

  Future<List<Poem>> getAuthorPoems() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString("user_data");
    
    if (userData == null) {
      throw Exception('User data not found');
    }

    final user = json.decode(userData);
    final userId = user["id"];

    if (userId == null) {
      throw Exception('User ID not found');
    }

    final poemsData = await _poetsLoomService.getAuthorPoems(BigInt.from( int.parse(userId)));
    
    final transformedPoems = await Future.wait(
      poemsData.map((poemData) async {
        try {
          final date = _convertBlockchainTimestamp(poemData[4]);
          final content = await _poetsLoomService.retrievePoemContent(poemData[1]);
          final avatarUrl = 'https://api.dicebear.com/7.x/avataaars/svg?seed=${poemData[2]}';
                            final likes = await _poetsLoomService.retrieveLikes( poemData[1]);


         final poem_content = content!["content"] as String;
          final poem_title = content!["title"] as String;
          return Poem(
            id: poemData[5]?.toString() ?? 'unknown',
            title: poem_title  ?? 'Untitled',
            content: poem_content ?? "Error: No content to display",
            authorAddress: poemData[2]?.toString() ?? 'unknown',
            authorId: int.parse(poemData[3]!.toString()) ,
            authorName: poemData[8]?.toString() ?? 'Anonymous',
            authorUsername: poemData[8]?.toString() ?? 'anonymous',
            poemHash: poemData[1]?.toString() ?? 'unknown',
            authorAvatar: avatarUrl,
            likes: likes?? 0,
            rewards: 0,
            isLiked:  false,
            createdAt: date,
            liked: poemData[7] == 0 ? [BigInt.from(0)] : (poemData[7] as List).cast<BigInt>(),
          );
        } catch (e) {
          print("Error processing author poem: $e");
          return null;
        }
      }),
    );

    return transformedPoems.where((poem) => poem != null).cast<Poem>().toList();
  }

  DateTime _convertBlockchainTimestamp(dynamic timestamp) {
    if (timestamp is BigInt) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp.toInt() * 1000);
    } else if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    } else if (timestamp is String) {
      try {
        int timestampInt = int.parse(timestamp);
        return DateTime.fromMillisecondsSinceEpoch(timestampInt * 1000);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  Future<void> likePoem(Poem poem) async {
    try {
      await _poetsLoomService.likePoem(poem.poemHash, poem.likes + 1 , int.parse(poem.id));
      
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
    } catch (e) {
      emit(state.copyWith(
        error: 'Failed to like poem',
        status: state.status,
      ));
    }
  }

 Future<void> updatePoem({
    required String title,
    required String content,
    required String hash
  }) async {


    // final encryptedIpfsHash = await _poetsLoomService.uploadToIpfs(content);
    final _prefs = await SharedPreferences.getInstance();
    final userId = await  json.decode(_prefs.getString("user_data")!)["id"] ?? "Anonymous";
    print("Uplaoding peoms");
    final contentHash =  await _poetsLoomService.updatePoem(title, content , int.parse(userId) , hash) ;
 
}
  Future<void> deletePoem(String poemId) async {
    try {
      // Add the delete poem functionality in your service
      // await _poetsLoomService.deletePoem(BigInt.from(int.parse(poemId)));
      
      final updatedPoems = state.poems.where((p) => p.id != poemId).toList();
      emit(state.copyWith(poems: updatedPoems));
    } catch (e) {
      emit(state.copyWith(
        error: 'Failed to delete poem',
        status: state.status,
      ));
    }
  }
}