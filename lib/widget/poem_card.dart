import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:test_app/model.dart';

class AnimatedPoemCard extends StatefulWidget {
  final Poem poem;
  final Future<void> Function() onLike;
  final Future<void> Function(BigInt amount) onReward;
  final Future<void> Function() onFollow;

  const AnimatedPoemCard({
    Key? key,
    required this.poem,
    required this.onLike,
    required this.onReward,
    required this.onFollow,
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
  
  bool _isExpanded = false;
  bool _isLiking = false;
  bool _isRewarding = false;

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
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Hero(
              tag: 'avatar-${widget.poem.authorId}',
              child: CircleAvatar(
                backgroundImage: NetworkImage(widget.poem.authorAvatar),
              ),
            ),
            title: Text(
              widget.poem.authorName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Text(
              '@${widget.poem.authorUsername}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.person_add_outlined),
              onPressed: widget.onFollow,
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
                  ),
                ),
                const SizedBox(height: 8),
                SizeTransition(
                  sizeFactor: _expandAnimation,
                  child: Text(
                    widget.poem.content,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          ButtonBar(
            alignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  ScaleTransition(
                    scale: _likeScaleAnimation,
                    child: IconButton(
                      icon: _isLiking
                          ? SizedBox(
                              width: 24,
                              height: 24,
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
                            ),
                      onPressed: _isLiking ? null : _handleLike,
                    ),
                  ),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: widget.poem.isLiked ? Colors.red : null,
                      fontWeight: widget.poem.isLiked ? FontWeight.bold : null,
                    ),
                    child: Text('${widget.poem.likes}'),
                  ),
                ],
              ),
              Column(
                children: [
                  Transform.rotate(
                    angle: _rewardRotateAnimation.value * 3.14159,
                    child: ScaleTransition(
                      scale: _rewardScaleAnimation,
                      child: IconButton(
                        icon: _isRewarding
                            ? SizedBox(
                                width: 24,
                                height: 24,
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
                              ),
                        onPressed: _isRewarding ? null : _handleReward,
                      ),
                    ),
                  ),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: widget.poem.rewards > 0 ? Colors.amber : null,
                      fontWeight: widget.poem.rewards > 0 ? FontWeight.bold : null,
                    ),
                    child: Text('${widget.poem.rewards}'),
                  ),
                ],
              ),
              IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    key: ValueKey(_isExpanded),
                  ),
                ),
                onPressed: _toggleExpand,
              ),
            ],
          ),
        ],
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
  _RewardBottomSheetState createState() => _RewardBottomSheetState();
}

class _RewardBottomSheetState extends State<RewardBottomSheet> {
  double _value = 1.0;

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
              const Icon(Icons.star, color: Colors.amber, size: 32),
              const SizedBox(width: 8),
              Text(
                _value.toStringAsFixed(1),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
          Slider(
            value: _value,
            min: 0.1,
            max: 10.0,
            divisions: 99,
            label: _value.toStringAsFixed(1),
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
                    BigInt.from(_value * 1e18.toInt()),
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
