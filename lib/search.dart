
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:test_app/create_poem.dart';
import 'package:test_app/model.dart';



import 'package:test_app/model.dart';
import 'package:test_app/widget/poem_card.dart';
class PoemSearchDelegate extends SearchDelegate<Poem?> {
  final List<Poem> poems;
  static const backgroundColor = Color(0xFF000000);
  static const cardColor = Color(0xFF1E1E1E);
  static const accentColor = Color(0xFF6C63FF);

  PoemSearchDelegate(this.poems) {
    // Override the default theme
  
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      AnimatedOpacity(
        opacity: query.isNotEmpty ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final filteredPoems = poems.where((poem) {
      final lowercaseQuery = query.toLowerCase();
      return poem.title.toLowerCase().contains(lowercaseQuery) ||
          poem.content.toLowerCase().contains(lowercaseQuery) ||
          poem.authorName.toLowerCase().contains(lowercaseQuery) ||
          poem.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();

    if (query.isEmpty) {
      return _buildRecentSearches();
    }

    if (filteredPoems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: Colors.white.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No results found for "$query"',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredPoems.length,
      itemBuilder: (context, index) {
        final poem = filteredPoems[index];
        return _buildSearchResultCard(context, poem);
      },
    );
  }

  Widget _buildSearchResultCard(BuildContext context, Poem poem) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => close(context, poem),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: NetworkImage(poem.authorAvatar),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            poem.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'by ${poem.authorName}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (poem.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 4,
                    children: poem.tags.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            color: accentColor.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSearches() {
    // You can implement recent searches functionality here
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_rounded,
            size: 64,
            color: Colors.white.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Search for poems, tags, or poets',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
class CustomSnackBar extends StatelessWidget {
  final String message;
  final IconData? icon;

  const CustomSnackBar({
    Key? key,
    required this.message,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon),
              SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}






// reward_confirmation_dialog.dart
class RewardConfirmationDialog extends StatefulWidget {
  // Using string constants for default values with proper documentation
  static const String _DEFAULT_MIN_REWARD = '100000000000000'; // 0.0001 ETH
  static const String _DEFAULT_MAX_REWARD = '5000000000000000000'; // 5 ETH
  static const String _DEFAULT_REWARD = '700000000000000000'; // 0.7 ETH

  final BigInt? customMinReward;
  final BigInt? customMaxReward;
  final BigInt? customDefaultReward;
  final String title;

  const RewardConfirmationDialog({
    super.key,
    this.customMinReward,
    this.customMaxReward,
    this.customDefaultReward,
    this.title = 'Reward Poem',
  });

  BigInt get minReward => customMinReward ?? BigInt.parse(_DEFAULT_MIN_REWARD);
  BigInt get maxReward => customMaxReward ?? BigInt.parse(_DEFAULT_MAX_REWARD);
  BigInt get defaultReward => customDefaultReward ?? BigInt.parse(_DEFAULT_REWARD);

  @override
  State<RewardConfirmationDialog> createState() => _RewardConfirmationDialogState();
}

class _RewardConfirmationDialogState extends State<RewardConfirmationDialog> {
  late double _currentValue;
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    _currentValue = _bigIntToDouble(widget.defaultReward);
  }

  double _bigIntToDouble(BigInt value) {
    final range = widget.maxReward - widget.minReward;
    if (range <= BigInt.zero) return 0.0;
    return (value - widget.minReward).toDouble() / range.toDouble();
  }

  BigInt _doubleToBigInt(double value) {
  if (value <= 0.0) return widget.minReward;
  if (value >= 1.0) return widget.maxReward;
  
  final range = widget.maxReward - widget.minReward;
  final scaledValue = BigInt.from((value * 1000).round());
  return widget.minReward + (range * scaledValue) ~/ BigInt.from(1000);
}

  String _formatEth(BigInt wei) {
    final decimal = BigInt.from(10).pow(18);
    final wholePart = wei ~/ decimal;
    final fractionalPart = wei % decimal;
    
    final fractionalStr = fractionalPart.toString().padLeft(18, '0');
    return '$wholePart.${fractionalStr.substring(0, 3)}';
  }

  Future<void> _handleConfirm() async {
    if (_isConfirming) return;
    
    setState(() => _isConfirming = true);
    
    try {
      final rewardAmount = _doubleToBigInt(_currentValue);
      Navigator.of(context).pop(rewardAmount);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to process reward amount')),
      );
      setState(() => _isConfirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rewardAmount = _doubleToBigInt(_currentValue);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.star, color: Colors.amber),
          const SizedBox(width: 8),
          Text(widget.title),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choose reward amount:', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            '${_formatEth(rewardAmount)} ETH',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: Colors.amber,
              thumbColor: Colors.amber,
              overlayColor: Colors.amber.withOpacity(0.2),
              valueIndicatorColor: Colors.amber,
              valueIndicatorTextStyle: const TextStyle(color: Colors.white),
            ),
            child: Slider(
              value: _currentValue,
              onChanged: (value) {
                setState(() => _currentValue = value);
                HapticFeedback.selectionClick();
              },
              divisions: 100,
              label: _formatEth(_doubleToBigInt(_currentValue)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatEth(widget.minReward), style: theme.textTheme.bodySmall),
              Text(_formatEth(widget.maxReward), style: theme.textTheme.bodySmall),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isConfirming ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isConfirming ? null : _handleConfirm,
          child: _isConfirming
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.onPrimary,
                    ),
                  ),
                )
              : const Text('Reward'),
        ),
      ],
    );
  }
}
