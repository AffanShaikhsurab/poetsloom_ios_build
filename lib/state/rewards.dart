import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_app/component/wallet_manager.dart';
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
  final PoetsLoomService _service;
  
  RewardsCubit(this._service) : super(RewardsLoading());

  Future<void> loadAllRewardsData() async {
    try {
      emit(RewardsLoading());
      
      final hasKey = await WalletManager.hasPrivateKey();
      if (!hasKey) {
        emit(RewardsError('Private key required to view rewards'));
        return;
      }

      final privateKey = await WalletManager.getPrivateKey();
      if (privateKey == null) {
        emit(RewardsError('Unable to access private key'));
        return;
      }

      final unclaimedBalance = await _service.getAuthorRewards(privateKey);
      final transactionHistory = await _service.getRewards();
      final totalTransactions = transactionHistory.fold(0.0, (a, b) => a + b);

      emit(RewardsData(
        unclaimedBalance: unclaimedBalance,
        transactionHistory: transactionHistory,
        isWithdrawing: false,
      ));
    } catch (e) {
      emit(RewardsError(e.toString()));
    }
  }

  Future<void> withdrawBalance() async {
    if (state is! RewardsData) return;
    final currentState = state as RewardsData;

    try {
      emit(currentState.copyWith(isWithdrawing: true));

      final hasKey = await WalletManager.hasPrivateKey();
      if (!hasKey) {
        emit(RewardsError('Private key required to withdraw'));
        return;
      }

      final privateKey = await WalletManager.getPrivateKey();
      if (privateKey == null) {
        emit(RewardsError('Unable to access private key'));
        return;
      }

      await _service.withdrawAmount(privateKey);
      await loadAllRewardsData();

    } catch (e) {
      emit(RewardsError(e.toString()));
    }
  }
}