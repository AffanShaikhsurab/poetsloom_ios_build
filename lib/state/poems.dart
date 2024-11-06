import 'package:equatable/equatable.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

import 'package:test_app/model.dart';
import 'package:test_app/services/contract.dart';

enum PoetryStatus { initial, loading, success, failure }

class PoetryState extends Equatable {
  final List<Poem> forYouPoems;
  final List<Poem> followingPoems;
  final List<Poem> trendingPoems;
  final List<Poem> newPoems;
  final List<Poem> authorPoems; // Added for author poems
  final PoetryStatus status;
  final String? error;
  final bool hasMorePoems;

  const PoetryState({
    this.forYouPoems = const [],
    this.followingPoems = const [],
    this.trendingPoems = const [],
    this.newPoems = const [],
    this.authorPoems = const [], // Initialize author poems
    this.status = PoetryStatus.initial,
    this.error,
    this.hasMorePoems = true,
  });

  PoetryState copyWith({
    List<Poem>? forYouPoems,
    List<Poem>? followingPoems,
    List<Poem>? trendingPoems,
    List<Poem>? newPoems,
    List<Poem>? authorPoems, // Add to copyWith
    PoetryStatus? status,
    String? error,
    bool? hasMorePoems,
  }) {
    return PoetryState(
      forYouPoems: forYouPoems ?? this.forYouPoems,
      followingPoems: followingPoems ?? this.followingPoems,
      trendingPoems: trendingPoems ?? this.trendingPoems,
      newPoems: newPoems ?? this.newPoems,
      authorPoems: authorPoems ?? this.authorPoems, // Include in copyWith
      status: status ?? this.status,
      error: error ?? this.error,
      hasMorePoems: hasMorePoems ?? this.hasMorePoems,
    );
  }

  @override
  List<Object?> get props => [
        forYouPoems,
        followingPoems,
        trendingPoems,
        newPoems,
        authorPoems, // Add to props
        status,
        error,
        hasMorePoems,
      ];
}


// lib/cubits/poetry_cubit.dart

class PoetryCubit extends Cubit<PoetryState> {
  final PoetsLoomService _poetsLoomService;
  static const int _pageSize = 10;

  PoetryCubit({
    required PoetsLoomService poetsLoomService,
  })  : _poetsLoomService = poetsLoomService,
        super(const PoetryState());

  Future<void> loadInitialPoems(int tabIndex) async {
    if (state.status == PoetryStatus.loading) return;

    emit(state.copyWith(
      status: PoetryStatus.loading,
      error: null,
    ));

    try {
      
      
      switch (tabIndex) {

        case 0:
        final poems = await _fetchAndTransformPoems();
          emit(state.copyWith(
            forYouPoems: poems,
            status: PoetryStatus.success,
            hasMorePoems: poems.length >= _pageSize,
          ));
          break;
        case 1:
        final poems = await getFollowedPoems();
          emit(state.copyWith(
            followingPoems: poems ?? state.newPoems,
            status: PoetryStatus.success,
            hasMorePoems: poems!.length >= _pageSize,
          ));
          break;
        case 2:
        final poems = await _fetchAndTransformPoems();
          emit(state.copyWith(
            trendingPoems: poems,
            status: PoetryStatus.success,
            hasMorePoems: poems.length >= _pageSize,
          ));
          break;
        case 3:
        final poems = await _fetchAndTransformPoems();
          emit(state.copyWith(
            newPoems: poems,
            status: PoetryStatus.success,
            hasMorePoems: poems.length >= _pageSize,
          ));
          break;
      }
    } catch (e) {
      emit(state.copyWith(
        status: PoetryStatus.failure,
        error: 'Failed to load poems. Please check your connection and try again.',
      ));
    }
  }

  Future<void> getAuthorPoems() async {
    if (state.status == PoetryStatus.loading) return;

    emit(state.copyWith(
      status: PoetryStatus.loading,
      error: null,
    ));

    try {
      final _prefs = await SharedPreferences.getInstance();
      final userData = _prefs.getString("user_data");
      
      if (userData == null) {
        throw Exception('User data not found');
      }

      final user = json.decode(userData);
      final userId = user["id"];

      if (userId == null) {
        throw Exception('User ID not found');
      }
      print("get authors poems for user $userId");
      // Get all poems from blockchain
      final poemsData = await _poetsLoomService.getAuthorPoems(BigInt.from(int.parse(userId)));
      
      // Filter poems for the current author and transform them


      // Transform the filtered poems
      final transformedPoems = await Future.wait(
        poemsData.map((poemData) async {
          try {
            final date = convertBlockchainTimestamp(poemData[4]);
            final content = await _poetsLoomService.retrievePoemContent(poemData[1]);
            final avatarUrl = 'https://api.dicebear.com/7.x/avataaars/svg?seed=${poemData[2]}';
                      final likes = await _poetsLoomService.retrieveLikes( poemData[1]);

            print("Liked Users are ${poemData[7].toString()}");
                    print("Author Name is ${poemData[8].toString()}");
                    print("Poem likes are ${poemData[6].toString()}");
          final isLiked = await _poetsLoomService.isLikedPoem(poemData[5]);
 final poem_content = content!["content"] as String;
          final poem_title = content!["title"] as String;
          var rewards = 0;

          if(content["rewards"] != null){
              rewards = content!["rewards"] as int ?? 0;
          }         return Poem(
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
            rewards: rewards,
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

      print("the transformedPoems are $transformedPoems");

      // Filter out null poems and sort by creation date (newest first)
        final filteredPoems = transformedPoems.where((poem) => poem != null).cast<Poem>().toList();
    
    print("Successfully transformed ${filteredPoems.length} poems");

      emit(state.copyWith(
        authorPoems: filteredPoems,
        status: PoetryStatus.success,
        hasMorePoems: filteredPoems.length >= _pageSize,
      ));
    } catch (e) {
      print("Error fetching author poems: $e");
      emit(state.copyWith(
        status: PoetryStatus.failure,
        error: 'Failed to load your poems. Please try again.',
      ));
    }
  }

  

  Future<void> loadMorePoems(int tabIndex) async {
    if (state.status == PoetryStatus.loading || !state.hasMorePoems) return;

    emit(state.copyWith(status: PoetryStatus.loading));

    try {
      final newPoems = await _fetchAndTransformPoems();
      
      switch (tabIndex) {
        case 0:
          emit(state.copyWith(
            forYouPoems: [...state.forYouPoems, ...newPoems],
            status: PoetryStatus.success,
            hasMorePoems: newPoems.length >= _pageSize,
          ));
          break;
        case 1:
          emit(state.copyWith(
            followingPoems: [...state.followingPoems, ...newPoems],
            status: PoetryStatus.success,
            hasMorePoems: newPoems.length >= _pageSize,
          ));
          break;
        case 2:
          emit(state.copyWith(
            trendingPoems: [...state.trendingPoems, ...newPoems],
            status: PoetryStatus.success,
            hasMorePoems: newPoems.length >= _pageSize,
          ));
          break;
        case 3:
          emit(state.copyWith(
            newPoems: [...state.newPoems, ...newPoems],
            status: PoetryStatus.success,
            hasMorePoems: newPoems.length >= _pageSize,
          ));
          break;
      }
    } catch (e) {
      emit(state.copyWith(
        status: PoetryStatus.failure,
        error: 'Failed to load more poems',
      ));
    }
  }

  Future<void> likePoem(Poem poem) async {
    try {
      await _poetsLoomService.likePoem(poem.poemHash, poem.likes + 1 , int.parse(poem.id));
      
      final updatedPoem = poem.copyWith(
        isLiked: !poem.isLiked,
        likes: poem.isLiked ? poem.likes - 1 : poem.likes + 1,
      );

      _updatePoemInLists(poem.id, updatedPoem);
    } catch (e) {
      emit(state.copyWith(
        error: 'Failed to like poem',
        status: state.status, // Preserve current status
      ));
    }
  }

Future<void> addFollower(Poem poem) async {
    try {
      await _poetsLoomService.addFollower(poem.authorId);

         } catch (e) {
      emit(state.copyWith(
        error: 'Failed to follow the author of poem ${poem.id}',
        status: state.status, // Preserve current status
      ));
    }
  }


  Future<void> rewardPoem(Poem poem, BigInt amount) async {
    try {
      await _poetsLoomService.rewardPoem(
        BigInt.from(int.parse(poem.id)),
        amount,poem.authorId
        ,poem.poemHash
        ,poem.rewards + 1
      );
      
      final updatedPoem = poem.copyWith(rewards: poem.rewards + 1);
      _updatePoemInLists(poem.id, updatedPoem);
    } catch (e) {
      emit(state.copyWith(
        error: 'Failed to reward poem',
        status: state.status,
      ));
    }
  }

  void _updatePoemInLists(String poemId, Poem updatedPoem) {
    emit(state.copyWith(
      forYouPoems: _updatePoemInList(state.forYouPoems, poemId, updatedPoem),
      followingPoems: _updatePoemInList(state.followingPoems, poemId, updatedPoem),
      trendingPoems: _updatePoemInList(state.trendingPoems, poemId, updatedPoem),
      newPoems: _updatePoemInList(state.newPoems, poemId, updatedPoem),
    ));
  }

  List<Poem> _updatePoemInList(List<Poem> poems, String poemId, Poem updatedPoem) {
    return poems.map((poem) => poem.id == poemId ? updatedPoem : poem).toList();
  }

  DateTime convertBlockchainTimestamp(dynamic timestamp) {
  // Blockchain timestamps are typically in seconds since epoch
  // Convert to milliseconds for Dart DateTime
  if (timestamp is BigInt) {
    return DateTime.fromMillisecondsSinceEpoch(timestamp.toInt() * 1000);
  } else if (timestamp is int) {
    return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  } else if (timestamp is String) {
    // Try parsing the string as an integer
    try {
      int timestampInt = int.parse(timestamp);
      return DateTime.fromMillisecondsSinceEpoch(timestampInt * 1000);
    } catch (e) {
      print('Error parsing timestamp: $e');
      return DateTime.now(); // Fallback to current time
    }
  }
  return DateTime.now(); // Fallback to current time
}

  // Rest of the code remains the same...

  // Future<void> getFollowedPoems() async {
  //   if (state.status == PoetryStatus.loading) return;

  //   emit(state.copyWith(
  //     status: PoetryStatus.loading,
  //     error: null,
  //   ));

  //   try {
  //     final _prefs = await SharedPreferences.getInstance();
  //     final userData = _prefs.getString("user_data");

  //     if (userData == null) {
  //       throw Exception('User data not found');
  //     }

  //     final user = json.decode(userData);
  //     final userId = user["id"];

  //     if (userId == null) {
  //       throw Exception('User ID not found');
  //     }

  //     // Get all followed poems from blockchain
  //     final followedPoemsData = getFollowedPoems();

  //     // Transform the followed poems data
  //     final transformedFollowedPoems = await Future.wait(
  //       followedPoemsData.map((poemData) async {
  //         try {
  //           final date = convertBlockchainTimestamp(poemData[4]);
  //           final content = await _poetsLoomService.retrievePoemContent(poemData[1]);
  //           final avatarUrl = 'https://api.dicebear.com/7.x/avataaars/svg?seed=${poemData[2]}';
  //           final likes = await _poetsLoomService.retrieveLikes(poemData[1]);
  //           final isLiked = await _poetsLoomService.isLikedPoem(poemData[5]);
  //           final poem_content = content!["content"] as String;
  //           final poem_title = content!["title"] as String;

  //           return Poem(
  //             id: poemData[5]?.toString() ?? 'unknown',
  //             title: poem_title ?? 'Untitled',
  //             content: poem_content ?? "Error: No content to display",
  //             authorAddress: poemData[2]?.toString() ?? 'unknown',
  //             authorId: int.parse(poemData[3]!.toString()),
  //             authorName: poemData[8]?.toString() ?? 'Anonymous',
  //             authorUsername: poemData[8]?.toString() ?? 'anonymous',
  //             poemHash: poemData[1]?.toString() ?? 'unknown',
  //             authorAvatar: avatarUrl,
  //             likes: likes ?? 0,
  //             rewards: 0,
  //             isLiked: isLiked,
  //             createdAt: date,
  //             liked: poemData[7] == 0 ? [BigInt.from(0)] : (poemData[7] as List).cast<BigInt>(),
  //           );
  //         } catch (e) {
  //           print("Error processing followed poem: $e");
  //           return null;
  //         }
  //       }),
  //     );

  //     // Filter out null poems and sort by creation date (newest first)
  //     final filteredFollowedPoems = transformedFollowedPoems.where((poem) => poem != null).cast<Poem>().toList();
  //     filteredFollowedPoems.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  //     emit(state.copyWith(
  //       followingPoems: filteredFollowedPoems,
  //       status: PoetryStatus.success,
  //       hasMorePoems: filteredFollowedPoems.length >= _pageSize,
  //     ));
  //   } catch (e) {
  //     print("Error fetching followed poems: $e");
  //     emit(state.copyWith(
  //       status: PoetryStatus.failure,
  //       error: 'Failed to load your followed poems. Please try again.',
  //     ));
  //   }
  // }




Future<List<Poem>?> getFollowedPoems() async {
  final supabaseClient = SupabaseClient('https://tfxbcnluzthdrwhtrntb.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRmeGJjbmx1enRoZHJ3aHRybnRiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzA0NjI2NjksImV4cCI6MjA0NjAzODY2OX0.at0R_6S9vUk666sS1xJA_2jIoRLez_YN2PBLo_822vM');
  final _prefs = await SharedPreferences.getInstance();
  final userId = json.decode(_prefs.getString('user_data')!)["id"];

  // Fetch the followed authors from the "following" table
  final results = await supabaseClient
      .from("following")
      .select("*")
      .eq("userId", userId);

  if (results.isEmpty) {
    print("Error fetching followed authors: ${results.toString()}");
    return [];
  }

  final authorIds = results.map((result) => result["authorId"] as int).toList();
  print("you followed authors are $authorIds");

  print("the new poems are ${state.forYouPoems}");
  // Fetch the poems for the followed authors from the "poems" table
      final followedPoems = await Future.wait(
      state.forYouPoems.map((poemData) async {
        print("the author id is ${poemData.authorId}");
            if(authorIds.contains( poemData.authorId)){
              return poemData;
            }
        })
    );
      print("you followed poems are $followedPoems");

  // Flatten the list of lists
    final filteredPoems = followedPoems.where((poem) => poem != null).cast<Poem>().toList();

  
  // Sort the poems by creation date (newest first)
  filteredPoems.sort((a, b) => b!.createdAt!.compareTo(a!.createdAt));

  return filteredPoems;
}
  // Rest of the code remains the same...

Future<List<Poem>> _fetchAndTransformPoems() async {
  try {
    // Fetch poems data from the service
    final poemsData = await _poetsLoomService.getPoems();
    final _prefs = await SharedPreferences.getInstance();
    final user = json.decode(_prefs.getString('user_data')!);
    print("Fetching poems data from server...");

    // Transform the fetched data into a list of Poem objects
    // Use Future.wait to handle multiple async operations
    final transformedPoems = await Future.wait(
      poemsData.map((poemData) async {
        // Basic null check for poem data
        if (poemData == null) {
          print("Warning: Found null poem data");
          return null;
        }

        try {
          // Convert timestamp to date
          final date = convertBlockchainTimestamp(poemData[4]);
          
          // Fetch poem content
          final content = await _poetsLoomService.retrievePoemContent(poemData[1]);
          final likes = await _poetsLoomService.retrieveLikes( poemData[1]);
          // Create avatar URL using author ID for uniqueness
          final avatarUrl = 'https://api.dicebear.com/7.x/avataaars/svg?seed=${poemData[2]}';
          print("Liked Users are ${poemData[7].toString()}");
          print("Author Name is ${poemData[8].toString()}");
          print("Poem likes are ${poemData[6].toString()}");
          final _isLiked = await _poetsLoomService.isLikedPoem(poemData[5]);
          final poem_content = content!["content"] as String;
          final poem_title = content!["title"] as String;
                    var rewards = 0;

          if(content["rewards"] != null){
              rewards = content!["rewards"] as int ?? 0;
          }
          print("Is liked is $_isLiked");
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
            rewards: rewards,
            isLiked:  false,
            createdAt: date,
            liked: poemData[7] == 0 ? [BigInt.from(0)] : (poemData[7] as List).cast<BigInt>(),
          );
        } catch (e) {
          print("Error processing poem: $e");
          return null;
        }
      }),
    );

    // Filter out null poems after awaiting all Future results
    final filteredPoems = transformedPoems.where((poem) => poem != null).cast<Poem>().toList();
    
    print("Successfully transformed ${filteredPoems.length} poems");
    return filteredPoems;
  } catch (e) {
    print("Error fetching or transforming poems: $e");
    return [];
  }
}
}
