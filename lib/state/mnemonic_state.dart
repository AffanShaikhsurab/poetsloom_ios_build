
// lib/cubits/mnemonic_state.dart
import 'package:equatable/equatable.dart';
// lib/cubits/mnemonic_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_app/services/mnemonic.dart';
abstract class MnemonicState extends Equatable {
  const MnemonicState();
  
  @override
  List<Object?> get props => [];
}

class MnemonicInitial extends MnemonicState {}

class MnemonicLoading extends MnemonicState {}

class MnemonicError extends MnemonicState {
  final String message;
  
  const MnemonicError(this.message);
  
  @override
  List<Object?> get props => [message];
}

class KeyGenerated extends MnemonicState {
  final String key;
  final String mnemonic;
  final String iv;
  
  const KeyGenerated({
    required this.key,
    required this.mnemonic,
    required this.iv,
  });
  
  @override
  List<Object?> get props => [key, mnemonic, iv];
}

class MnemonicConverted extends MnemonicState {
  final String key;
  final String mnemonic;
  
  const MnemonicConverted({
    required this.key,
    required this.mnemonic,
  });
  
  @override
  List<Object?> get props => [key, mnemonic];
}

class MnemonicVerified extends MnemonicState {
  final bool isValid;
  final String? regeneratedMnemonic;
  
  const MnemonicVerified({
    required this.isValid,
    this.regeneratedMnemonic,
  });
  
  @override
  List<Object?> get props => [isValid, regeneratedMnemonic];
}



class MnemonicCubit extends Cubit<MnemonicState> {
  final MnemonicService _service;
  
  MnemonicCubit(this._service) : super(MnemonicInitial());

  Future<void> generateKey() async {
    try {
      emit(MnemonicLoading());
      final result = await _service.generateKey();
      emit(KeyGenerated(
        key: result['key'],
        mnemonic: result['mnemonic'],
        iv: result['iv'],
      ));
    } catch (e) {
      emit(MnemonicError(e.toString()));
    }
  }

  Future<void> convertKeyToMnemonic(String key) async {
    try {
      emit(MnemonicLoading());
      final result = await _service.keyToMnemonic(key);
      emit(MnemonicConverted(
        key: result['key'],
        mnemonic: result['mnemonic'],
      ));
    } catch (e) {
      emit(MnemonicError(e.toString()));
    }
  }

  Future<void> convertMnemonicToKey(String mnemonic) async {
    try {
      emit(MnemonicLoading());
      final result = await _service.mnemonicToKey(mnemonic);
      emit(MnemonicConverted(
        key: result['key'],
        mnemonic: result['mnemonic'],
      ));
    } catch (e) {
      emit(MnemonicError(e.toString()));
    }
  }

  Future<void> verifyMnemonic(String mnemonic) async {
    try {
      emit(MnemonicLoading());
      final result = await _service.verifyMnemonic(mnemonic);
      emit(MnemonicVerified(
        isValid: result['valid'],
        regeneratedMnemonic: result['regenerated_mnemonic'],
      ));
    } catch (e) {
      emit(MnemonicError(e.toString()));
    }
  }
}
