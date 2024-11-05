
// rewards_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_app/state/rewards.dart';
import 'package:test_app/state/user.dart';
import 'package:web3dart/web3dart.dart';

class RewardsScreen extends StatefulWidget {
  @override
  _RewardsScreenState createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  bool _isWithdrawing = false;

  String _formatEther(BigInt wei) {
    final ether = EtherAmount.fromBigInt(EtherUnit.wei, wei)
        .getValueInUnit(EtherUnit.ether);
    return ether.toStringAsFixed(6);
  }

  @override
  void initState() {
    super.initState();
    // Load rewards when screen opens
    context.read<RewardsCubit>().loadRewards();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Rewards'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<RewardsCubit>().loadRewards(
          );
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          'Available Balance',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        BlocBuilder<RewardsCubit, RewardsState>(
                          builder: (context, state) {
                            if (state is RewardsLoading) {
                              return const CircularProgressIndicator();
                            } else if (state is RewardsLoaded) {
                              return Text(
                                '${_formatEther(state.amount)} ETH',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              );
                            } else if (state is RewardsError) {
                              return Text(
                                'Error: ${state.message}',
                                style: const TextStyle(color: Colors.red),
                              );
                            }
                            return const Text('--');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                BlocBuilder<RewardsCubit, RewardsState>(
                  builder: (context, rewardsState) {
                    return BlocBuilder<WithdrawCubit, WithdrawState>(
                      builder: (context, withdrawState) {
                        final bool hasRewards = rewardsState is RewardsLoaded && 
                            rewardsState.amount > BigInt.zero;
                        
                        return Column(
                          children: [
                            FilledButton.icon(
                              onPressed: !hasRewards || _isWithdrawing ? null : () async {
                                setState(() => _isWithdrawing = true);
                                try {
                                  await context.read<WithdrawCubit>().withdrawRewards();
                                  // Refresh rewards after withdrawal
                                  await context.read<RewardsCubit>().loadRewards(
                                  );
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Withdrawal successful!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Withdrawal failed: ${e.toString()}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() => _isWithdrawing = false);
                                  }
                                }
                              },
                              icon: _isWithdrawing
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.currency_exchange),
                              label: Text(_isWithdrawing ? 'Processing...' : 'Withdraw Rewards'),
                            ),
                            if (withdrawState is WithdrawFailure)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  withdrawState.error,
                                  style: const TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
