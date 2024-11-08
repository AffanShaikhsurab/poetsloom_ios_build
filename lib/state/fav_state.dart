// favorite_poems_cubit.dart
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_app/model.dart';
import 'package:test_app/services/contract.dart';
import 'package:test_app/state/poems.dart';

enum FavoritePoemsStatus { initial, loading, success, failure }

class FavoritePoemsState {
  final List<Poem> favoritePoems;
  final FavoritePoemsStatus status;
  final String? error;
  
  FavoritePoemsState({
    this.favoritePoems = const [],
    this.status = FavoritePoemsStatus.initial,
    this.error,
  });

  FavoritePoemsState copyWith({
    
    List<Poem>? favoritePoems,
    FavoritePoemsStatus? status,
    String? error,
  }) {
    return FavoritePoemsState(
      favoritePoems: favoritePoems ?? this.favoritePoems,
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }
}

class FavoritePoemsCubit extends Cubit<FavoritePoemsState> {
  final PoetryCubit poetryCubit;
  final PoetsLoomService poetsLoomService;

  FavoritePoemsCubit({required this.poetryCubit , required this.poetsLoomService}) : super(FavoritePoemsState());

  Future<void> loadFavoritePoems() async {
    try {
      emit(state.copyWith(status: FavoritePoemsStatus.loading));
      
      // TODO: Implement filtering logic here
      // This is where you would get poems from poetryCubit and filter favorites
      final allPoems = poetryCubit.state.forYouPoems;

      // get user liked poem id from supabase and filter them




      final favoritePoems =   await poetsLoomService.getFavorites();

      final poems = allPoems.where((poem) => favoritePoems.contains(int.parse(poem.id))).toList();
      
      emit(state.copyWith(
        status: FavoritePoemsStatus.success,
        favoritePoems: poems, // Replace with filtered poems
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FavoritePoemsStatus.failure,
        error: e.toString(),
      ));
    }
  }

  void removeFromFavorites(Poem poem) {
    // TODO: Implement remove from favorites logic
    final updatedPoems = List<Poem>.from(state.favoritePoems)
      ..removeWhere((p) => p.id == poem.id);
    
    emit(state.copyWith(favoritePoems: updatedPoems));
  }



}