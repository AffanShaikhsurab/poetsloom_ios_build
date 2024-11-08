import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:test_app/model.dart';
import 'package:test_app/screens/poem_detial.dart';

class AnimatedPoemCard extends StatefulWidget {
  final Poem poem;
  final bool isFavorite;
  final Future<void> Function() onLike;
  final Future<void> Function(BigInt amount) onReward;
  final Future<void> Function() onFollow;
  final Future<void> Function(Poem poem ) addToFavorites;

  const AnimatedPoemCard({
    Key? key,
    required this.poem,
    required this.onLike,
    required this.isFavorite,
    required this.onReward,
    required this.onFollow,
    required this.addToFavorites
  }) : super(key: key);

  @override
  _AnimatedPoemCardState createState() => _AnimatedPoemCardState();
}

class _AnimatedPoemCardState extends State<AnimatedPoemCard> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _likeScaleAnimation;
  late Animation<double> _rewardScaleAnimation;
  late Animation<double> _rewardRotateAnimation;
    late Animation<double> _favoriteScaleAnimation;

  bool _isExpanded = false;
  bool _isLiking = false;
  bool _isRewarding = false;
 bool _isAddingToFavorites = false;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _likeScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.4)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.4, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticIn)),
        weight: 50,
      ),
    ]).animate(_controller);

    _rewardScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1.0)
            .chain(CurveTween(curve: Curves.bounceOut)),
        weight: 70,
      ),
    ]).animate(_controller);
_favoriteScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1.0)
            .chain(CurveTween(curve: Curves.bounceOut)),
        weight: 70,
      ),
    ]).animate(_controller);

    _rewardRotateAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 0.5)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.5, end: 0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50,
      ),
    ]).animate(_controller);
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _handleLike() async {
    if (_isLiking) return;

    setState(() => _isLiking = true);
    try {
      await widget.onLike();
      _controller.forward(from: 0).then((_) {
        if (widget.poem.isLiked) {
          HapticFeedback.mediumImpact();
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to like the poem'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLiking = false);
      }
    }
  }

  

  Future<void> _handleFavorite() async {
    if (_isAddingToFavorites) return;

    setState(() => _isAddingToFavorites = true);
    
    try {
      await widget.addToFavorites(widget.poem );
      _controller.forward(from: 0).then((_) {
        HapticFeedback.mediumImpact();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.favorite,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.isFavorite == false ? 'Removed from favorites' :
                    'Added to favorites'
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.primary,
            action: SnackBarAction(
              label: 'UNDO',
              textColor: Theme.of(context).colorScheme.onPrimary,
              onPressed: () async {
                await _handleFavorite();
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.onError,
                ),
                const SizedBox(width: 8),
                const Text('Failed to update favorites'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Theme.of(context).colorScheme.onError,
              onPressed: _handleFavorite,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAddingToFavorites = false);
      }
    }
  }

  Future<void> _handleReward() async {
    if (_isRewarding) return;

    setState(() => _isRewarding = true);
    
    try {
      final rewardAmount = await showModalBottomSheet<BigInt>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => RewardBottomSheet(poem: widget.poem),
      );
      
      if (rewardAmount != null && mounted) {
        await widget.onReward(rewardAmount);
        _controller.forward(from: 0);
        HapticFeedback.mediumImpact();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.star, color: Theme.of(context).colorScheme.onPrimary),
                  const SizedBox(width: 8),
                  const Text('Reward sent successfully!'),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to send reward'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRewarding = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PoemDetailScreen(poem: widget.poem),
          ),
        );
      },
      onLongPress: _isAddingToFavorites ? null : _handleFavorite,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDarkMode 
              ? const Color(0xFF1E1E1E) 
              : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDarkMode 
                ? Colors.white.withOpacity(0.1) 
                : Colors.black.withOpacity(0.05),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Hero(
                    tag: 'avatar-${widget.poem.authorId}',
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.2),
                          width: 2,
                        ),
                        image: DecorationImage(
                          image: NetworkImage(widget.poem.authorAvatar),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.poem.authorName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          '@${widget.poem.authorUsername}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDarkMode 
                                ? Colors.white.withOpacity(0.6) 
                                : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: widget.onFollow,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: colorScheme.primary,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Follow',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.poem.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizeTransition(
                    sizeFactor: _expandAnimation,
                    child: Text(
                      widget.poem.content,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDarkMode 
                            ? Colors.white.withOpacity(0.8) 
                            : Colors.black54,
                        height: 1.5,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDarkMode 
                        ? Colors.white.withOpacity(0.1) 
                        : Colors.black.withOpacity(0.05),
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInteractionButton(
                      icon: _isLiking
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  colorScheme.primary,
                                ),
                              ),
                            )
                          : Icon(
                              widget.poem.isLiked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: widget.poem.isLiked ? Colors.red : null,
                              size: 20,
                            ),
                      label: '${widget.poem.likes}',
                      isActive: widget.poem.isLiked,
                      activeColor: Colors.red,
                      onTap: _isLiking ? null : _handleLike,
                    ),
                    _buildInteractionButton(
                      icon: _isRewarding
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  colorScheme.secondary,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.star,
                              color: widget.poem.rewards > 0
                                  ? Colors.amber
                                  : null,
                              size: 20,
                            ),
                      label: '${widget.poem.rewards}',
                      isActive: widget.poem.rewards > 0,
                      activeColor: Colors.amber,
                      onTap: _isRewarding ? null : _handleReward,
                    ),
                    IconButton(
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          _isExpanded ? Icons.expand_less : Icons.expand_more,
                          key: ValueKey(_isExpanded),
                          size: 20,
                        ),
                      ),
                      onPressed: _toggleExpand,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionButton({
    required Widget icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              icon,
              const SizedBox(width: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: isActive ? activeColor : null,
                  fontWeight: isActive ? FontWeight.bold : null,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class RewardBottomSheet extends StatefulWidget {
  final Poem poem;

  const RewardBottomSheet({
    Key? key,
    required this.poem,
  }) : super(key: key);

  @override
  RewardBottomSheetState createState() => RewardBottomSheetState();
}
class RewardBottomSheetState extends State<RewardBottomSheet> {
  // Starting with 0.0005 ETH as minimum
  double _value = 0.0005;

  String _formatEthValue(double value) {
    // Format with appropriate decimal places based on value size
    if (value < 0.001) {
      return value.toStringAsFixed(4);
    } else if (value < 0.01) {
      return value.toStringAsFixed(3);
    } else {
      return value.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'Reward "${widget.poem.title}"',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.attach_money, color: Colors.amber, size: 32),
              const SizedBox(width: 8),
              Text(
                '${_formatEthValue(_value)} ETH',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
          Slider(
            value: _value,
            min: 0.0005, // Minimum 0.0005 ETH
            max: 1.0,    // Maximum 1 ETH
            // Using more divisions for finer control
            divisions: 1999, // This gives steps of 0.0005 ETH
            label: '${_formatEthValue(_value)} ETH',
            onChanged: (value) => setState(() => _value = value),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(
                    context,
                    // Convert ETH to Wei (1 ETH = 10^18 Wei)
                    BigInt.from(_value *1e18)
                  ),
                  child: const Text('Send Reward'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}