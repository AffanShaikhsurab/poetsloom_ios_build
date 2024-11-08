import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_app/services/contract.dart';

// Add Poem States
abstract class AddPoemState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AddPoemInitial extends AddPoemState {}

class AddPoemLoading extends AddPoemState {}

class AddPoemSuccess extends AddPoemState {
  final String transactionHash;

  AddPoemSuccess(this.transactionHash);

  @override
  List<Object?> get props => [transactionHash];
}

class AddPoemFailure extends AddPoemState {
  final String error;

  AddPoemFailure(this.error);

  @override
  List<Object?> get props => [error];
}

// Add Poem Cubit
class AddPoemCubit extends Cubit<AddPoemState> {
  final PoetsLoomService _poetsLoomService;

  AddPoemCubit(this._poetsLoomService) : super(AddPoemInitial());


  Future<void> addPoem({
    required String title,
    required String content,
    required List<String> tags
  }) async {
    emit(AddPoemLoading());

    // final encryptedIpfsHash = await _poetsLoomService.uploadToIpfs(content);
    final _prefs = await SharedPreferences.getInstance();
    final authorName = await  json.decode(_prefs.getString("user_data")!)["username"] ?? "Anonymous";
    print("Uplaoding peoms");
    final contentHash =  await _poetsLoomService.uploadPoemWithHashedKey(title, content , tags) ;
 
    try {
      final transactionHash = await _poetsLoomService.addPoem(
        title,
        contentHash! ,
        authorName!,
      );
      emit(AddPoemSuccess(transactionHash));
    } catch (e) {
      emit(AddPoemFailure(e.toString()));
    }
  }
}

// Withdrawal States
abstract class WithdrawState extends Equatable {
  @override
  List<Object?> get props => [];
}

class WithdrawInitial extends WithdrawState {}

class WithdrawLoading extends WithdrawState {}

class WithdrawSuccess extends WithdrawState {
  final String transactionHash;

  WithdrawSuccess(this.transactionHash);

  @override
  List<Object?> get props => [transactionHash];
}

class WithdrawFailure extends WithdrawState {
  final String error;

  WithdrawFailure(this.error);

  @override
  List<Object?> get props => [error];
}

// Withdrawal Cubit
class WithdrawCubit extends Cubit<WithdrawState> {
  final PoetsLoomService _poetsLoomService;

  WithdrawCubit(this._poetsLoomService) : super(WithdrawInitial());

  Future<void> withdrawRewards() async {
    emit(WithdrawLoading());

    try {
      final transactionHash = await _poetsLoomService.withdrawAmount();
      emit(WithdrawSuccess(transactionHash));
    } catch (e) {
      emit(WithdrawFailure(e.toString()));
    }
  }

 
}