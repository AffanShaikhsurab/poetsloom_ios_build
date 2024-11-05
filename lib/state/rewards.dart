// rewards_state.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_app/services/contract.dart';
import 'package:web3dart/web3dart.dart';

abstract class RewardsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class RewardsInitial extends RewardsState {}

class RewardsLoading extends RewardsState {}

class RewardsLoaded extends RewardsState {
  final BigInt amount;
  
  RewardsLoaded(this.amount);
  
  @override
  List<Object?> get props => [amount];
}

class RewardsError extends RewardsState {
  final String message;
  
  RewardsError(this.message);
  
  @override
  List<Object?> get props => [message];
}


class RewardsCubit extends Cubit<RewardsState> {
  final PoetsLoomService _poetsLoomService;
  
  RewardsCubit(this._poetsLoomService) : super(RewardsInitial());
  
  Future<void> loadRewards() async {
    emit(RewardsLoading());
    try {
      final rewards = await _poetsLoomService.getAuthorRewards();
      emit(RewardsLoaded(rewards));
    } catch (e) {
      emit(RewardsError('Failed to load rewards: ${e.toString()}'));
    }
  }
}
