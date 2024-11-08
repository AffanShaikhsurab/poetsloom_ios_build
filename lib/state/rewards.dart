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

class RewardsData extends RewardsState {
  final BigInt unclaimedBalance;
  final List<double> transactionHistory;
  final bool isWithdrawing;
  
  RewardsData({
    required this.unclaimedBalance,
    this.transactionHistory = const [],
    this.isWithdrawing = false,
  });
  
  double get totalTransactions => 
      transactionHistory.fold(0.0, (sum, amount) => sum + amount);
  
  RewardsData copyWith({
    BigInt? unclaimedBalance,
    List<double>? transactionHistory,
    bool? isWithdrawing,
  }) {
    return RewardsData(
      unclaimedBalance: unclaimedBalance ?? this.unclaimedBalance,
      transactionHistory: transactionHistory ?? this.transactionHistory,
      isWithdrawing: isWithdrawing ?? this.isWithdrawing,
    );
  }
  
  @override
  List<Object?> get props => [unclaimedBalance, transactionHistory, isWithdrawing];
}

class RewardsError extends RewardsState {
  final String message;
  
  RewardsError(this.message);
  
  @override
  List<Object?> get props => [message];
}

// rewards_cubit.dart
class RewardsCubit extends Cubit<RewardsState> {
  final PoetsLoomService _poetsLoomService;
  
  RewardsCubit(this._poetsLoomService) : super(RewardsInitial());
  
  Future<void> loadAllRewardsData() async {
    emit(RewardsLoading());
    try {
      final unclaimedBalance = await _poetsLoomService.getAuthorRewards();
      final transactionHistory = await _poetsLoomService.getRewards();
      
      emit(RewardsData(
        unclaimedBalance: unclaimedBalance,
        transactionHistory: transactionHistory,
      ));
    } catch (e) {
      emit(RewardsError('Failed to load rewards: ${e.toString()}'));
    }
  }

  Future<void> withdrawBalance() async {
    final currentState = state;
    if (currentState is RewardsData) {
      emit(currentState.copyWith(isWithdrawing: true));
      
      try {
        await _poetsLoomService.withdrawAmount();
        await loadAllRewardsData();
      } catch (e) {
        emit(RewardsError('Failed to withdraw balance: ${e.toString()}'));
      }
    }
  }
}
