// rewards_state.dart
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_app/component/wallet_manager.dart';
import 'package:test_app/state/rewards.dart';
import 'package:test_app/utils/app_colors.dart';
import 'package:web3dart/web3dart.dart';
// rewards_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_app/services/contract.dart';
// rewards_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web3dart/web3dart.dart';


class RewardsScreen extends StatefulWidget {
  @override
  _RewardsScreenState createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
    static const backgroundColor = Color(0xFF000000);
  static const surfaceColor = Color(0xFF121212);
  static const cardColor = Color(0xFF1E1E1E);
  static const accentColor = Color(0xFF6C63FF);
  Future<void> _showPrivateKeyPrompt() {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Theme(
        data: ThemeData.dark().copyWith(
          dialogBackgroundColor: AppColors.cardColor,
        ),
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.key_rounded,
                  color: Colors.amber,
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Private Key Required',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'To view and manage your rewards, you need to provide your private key.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      final result = await showPrivateKeyDialog(context);
                      if (result != null && mounted) {
                        context.read<RewardsCubit>().loadAllRewardsData();
                      }
                    },
                    style: AppColors.getAccentButtonStyle(),
                    child: const Text('Add Private Key'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
Future<String?> showPrivateKeyDialog(BuildContext context) {
  final controller = TextEditingController();
  bool obscureText = true;

  return showDialog<String>(
    context: context,
    builder: (context) => Theme(
      data: ThemeData.dark().copyWith(
        dialogBackgroundColor: cardColor,
      ),
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.key_rounded,
                      color: accentColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Private Key Required',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'A private key is required to publish poems. This will be stored securely on your device.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: accentColor.withOpacity(0.3),
                  ),
                ),
                child: TextField(
                  controller: controller,
                  obscureText: obscureText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Lora',
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter your private key',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureText
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      onPressed: () {
                        setState(() => obscureText = !obscureText);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accentColor,
                          accentColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          final key = controller.text.trim();
                          if (key.isNotEmpty) {
                            await WalletManager.savePrivateKey(key);
                            Navigator.pop(context, key);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          child: const Text(
                            'Continue',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildUnclaimedBalanceCard(RewardsData state) {
    return Container(
      decoration: AppColors.getAccentCardDecoration(),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppColors.accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Available Balance',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '${(state.unclaimedBalance)} ETH',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: AppColors.accentColor,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: state.isWithdrawing
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(AppColors.accentColor),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: state.unclaimedBalance > BigInt.zero
                        ? () async {
                            final hasKey = await WalletManager.hasPrivateKey();
                            if (!hasKey) {
                              if (!mounted) return;
                              await _showPrivateKeyPrompt();
                              return;
                            }
                            if (!mounted) return;
                            context.read<RewardsCubit>().withdrawBalance();
                          }
                        : null,
                    style: AppColors.getAccentButtonStyle(),
                    icon: const Icon(Icons.download_rounded),
                    label: const Text(
                      'Withdraw Balance',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionHistoryCard(RewardsData state) {
    return Container(
      decoration: AppColors.getCardDecoration(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.history_rounded,
                  color: AppColors.accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Transaction History',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Total Earnings: ${state.totalTransactions.toStringAsFixed(6)} ETH',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.accentColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (state.transactionHistory.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: state.transactionHistory.length,
                separatorBuilder: (context, index) => Divider(
                  color: AppColors.borderColor,
                ),
                itemBuilder: (context, index) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.accentColor.withOpacity(0.1),
                      child: Icon(
                        Icons.add_circle_outline,
                        color: AppColors.accentColor,
                      ),
                    ),
                    title: Text(
                      'Reward Payment',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Transaction ${state.transactionHistory.length - index}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: Text(
                      '${state.transactionHistory[index].toStringAsFixed(6)} ETH',
                      style: TextStyle(
                        color: AppColors.accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHowRewardsWork() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'How Rewards Work',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                child: const Icon(Icons.edit_outlined),
              ),
              title: const Text('Create Poems'),
              subtitle: const Text('Earn rewards for your creative contributions'),
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                child: const Icon(Icons.currency_exchange),
              ),
              title: const Text('Earn Rewards'),
              subtitle: const Text('Get paid for quality content and engagement'),
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                child: const Icon(Icons.account_balance_wallet),
              ),
              title: const Text('Withdraw Balance'),
              subtitle: const Text('Transfer your earnings to your wallet anytime'),
            ),
          ],
        ),
      ),
    );
  }

Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    // Add any additional logout logic here, such as clearing tokens or session data
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Rewards'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<RewardsCubit>().loadAllRewardsData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: BlocBuilder<RewardsCubit, RewardsState>(
            builder: (context, state) {
              if (state is RewardsLoading) {
                return SizedBox(
                  height: MediaQuery.of(context).size.height - 100,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              if (state is RewardsError) {
                return SizedBox(
                  height: MediaQuery.of(context).size.height - 100,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.message,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              if (state is RewardsData) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildUnclaimedBalanceCard(state),
                    const SizedBox(height: 16),
                    if (state.transactionHistory.isNotEmpty)
                      _buildTransactionHistoryCard(state)
                    else
                      _buildHowRewardsWork(),
                  ],
                );
              }
              
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}