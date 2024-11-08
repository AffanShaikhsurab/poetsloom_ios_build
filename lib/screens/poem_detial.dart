import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_app/model.dart';
import 'package:test_app/services/contract.dart';
import 'package:test_app/state/poem_details.dart';
import 'package:test_app/state/poems.dart';
import 'package:timeago/timeago.dart' as timeago;

class PoemDetailScreen extends StatefulWidget {
  final Poem poem;
  const PoemDetailScreen({Key? key, required this.poem}) : super(key: key);

  @override
  _PoemDetailScreenState createState() => _PoemDetailScreenState();
}

class _PoemDetailScreenState extends State<PoemDetailScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  
  // Theme colors
  static const backgroundColor = Color(0xFF000000);
  static const surfaceColor = Color(0xFF121212);
  static const cardColor = Color(0xFF1E1E1E);
  static const accentColor = Color(0xFF6C63FF);

  late AnimationController _animationController;
  late Animation<double> _headerScaleAnimation;
  late Animation<double> _contentFadeAnimation;
  late Animation<double> _statsSlideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _headerScaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    _contentFadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );

    _statsSlideAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }
void _focusOnComments() {
    // Add haptic feedback
    HapticFeedback.mediumImpact();
    
    // Request focus on the comment input
    _commentFocusNode.requestFocus();
    
    // Optionally scroll to the comments section
    // You'll need a ScrollController and GlobalKey for this
    final scrollController = ScrollController();
    final commentsKey = GlobalKey();
    
    // Delayed execution to ensure the layout is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox commentsBox = commentsKey.currentContext?.findRenderObject() as RenderBox;
      final double offset = commentsBox.localToGlobal(Offset.zero).dy;
      
      scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    });
  }
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CommentsCubit(
        poetsLoomService: PoetsLoomService(
               rpcUrl: 'https://eth-sepolia.g.alchemy.com/v2/bTJkxdz694BiZKrP7qINHw7NQUrpnd75',
        contractAddress: '0xF0F5234959166Cc8D2Ee9F4C4e029cdbdac93266',
        privateKey: "dc50e7d15fc7a35ed046e5d2c5151da2bb9a9fd427b2b00ba7db891dd11d0070"

      ),
      )..loadComments(int.parse(widget.poem.id)),
      child: Builder(
        builder: (context) {
          return Theme(
            data: ThemeData.dark().copyWith(
              scaffoldBackgroundColor: backgroundColor,
              appBarTheme: const AppBarTheme(
                backgroundColor: backgroundColor,
                elevation: 0,
              ),
            ),
            child: Scaffold(
              body: Stack(
                children: [
                  // Main content
                  CustomScrollView(
                    slivers: [
                      _buildAppBar(),
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            _buildAuthorSection(),
                            _buildPoemContent(),
                            _buildTags(),
                            _buildStats(context),
                            _buildComments(context),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Comment input overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildCommentInput(context),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      stretch: true,
      backgroundColor: backgroundColor,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.poem.title,
          style: const TextStyle(
            fontFamily: 'Lora',
            fontWeight: FontWeight.bold,
          ),
        ),
        background: ScaleTransition(
          scale: _headerScaleAnimation,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  accentColor.withOpacity(0.2),
                  backgroundColor,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthorSection() {
    return FadeTransition(
      opacity: _contentFadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Hero(
              tag: 'avatar-${widget.poem.authorId}',
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accentColor.withOpacity(0.3),
                    width: 2,
                  ),
                  image: DecorationImage(
                    image: NetworkImage(widget.poem.authorAvatar),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.poem.authorName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '@${widget.poem.authorUsername}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                // Add follow functionality
              },
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Follow'),
              style: TextButton.styleFrom(
                foregroundColor: accentColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: accentColor.withOpacity(0.3)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildPoemContent() {
    return FadeTransition(
      opacity: _contentFadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(_contentFadeAnimation),
        child: Stack(
          children: [
            // Background gradient decoration
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accentColor.withOpacity(0.1),
                    backgroundColor,
                  ],
                ),
              ),
            ),
            
            // Main content
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quote icon at the top
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: cardColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accentColor.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.format_quote_rounded,
                        color: accentColor.withOpacity(0.7),
                        size: 32,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Poem container
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // // Title section
                        // Container(
                        //   padding: const EdgeInsets.all(16),
                        //   decoration: BoxDecoration(
                        //     color: Colors.white.withOpacity(0.03),
                        //     borderRadius: BorderRadius.circular(16),
                        //     border: Border.all(
                        //       color: Colors.white.withOpacity(0.05),
                        //     ),
                        //   ),
                        //   child: Row(
                        //     children: [
                        //       Container(
                        //         width: 3,
                        //         height: 20,
                        //         decoration: BoxDecoration(
                        //           color: accentColor,
                        //           borderRadius: BorderRadius.circular(2),
                        //         ),
                        //       ),
                        //       const SizedBox(width: 12),
                        //       Expanded(
                        //         child: Text(
                        //           widget.poem.title,
                        //           style: const TextStyle(
                        //             fontSize: 24,
                        //             fontWeight: FontWeight.bold,
                        //             fontFamily: 'Lora',
                        //             color: Colors.white,
                        //           ),
                        //         ),
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        
                        // const SizedBox(height: 24),
                        
                        // Poem content
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _buildPoemLines(),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Bottom info section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.05),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildInfoItem(
                                icon: Icons.calendar_today_rounded,
                                label: 'Created',
                                value: _formatDate(widget.poem.createdAt),
                              ),
                              Container(
                                width: 1,
                                height: 30,
                                color: Colors.white.withOpacity(0.1),
                              ),
                            
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPoemLines() {
    final lines = widget.poem.content.split('\n');
    final List<Widget> widgets = [];
    bool isFirstParagraph = true;

    for (var line in lines) {
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 20));
        isFirstParagraph = false;
        continue;
      }

      if (isFirstParagraph && widgets.isEmpty) {
        // First line of the first paragraph
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              line,
              style: const TextStyle(
                height: 1.8,
                fontSize: 18,
                fontFamily: 'Lora',
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ),
        );
        isFirstParagraph = false;
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              line,
              style: TextStyle(
                height: 1.8,
                fontSize: 16,
                fontFamily: 'Lora',
                color: Colors.white.withOpacity(0.9),
                letterSpacing: 0.3,
              ),
            ),
          ),
        );
      }
    }

    return widgets;
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: accentColor,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    }
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  Widget _buildTags() {
    if (widget.poem.tags.isEmpty) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _contentFadeAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.poem.tags.map((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: accentColor.withOpacity(0.3),
                ),
              ),
              child: Text(
                '#$tag',
                style: TextStyle(
                  color: accentColor.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showRewardDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Reward Poem',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.stars_rounded,
              size: 48,
              color: accentColor,
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose amount to reward',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildRewardOption(context, '0.1'),
                _buildRewardOption(context, '0.5'),
                _buildRewardOption(context, '1.0'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

    Widget _buildRewardOption(BuildContext context, String amount) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          Navigator.pop(context);
          // Implement reward functionality
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Rewarded $amount ETH'),
              backgroundColor: accentColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: accentColor.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                amount,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'ETH',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStats(BuildContext context) {
    final stats = [
      {
        'icon': Icons.favorite_rounded,
        'count': widget.poem.likes,
        'label': 'Likes',
        'isActive': widget.poem.isLiked,
        'onTap': () {
          HapticFeedback.mediumImpact();
          context.read<PoetryCubit>().likePoem(widget.poem);
        },
      },
      {
        'icon': Icons.star_rounded,
        'count': widget.poem.rewards,
        'label': 'Rewards',
        'onTap': () {
          HapticFeedback.mediumImpact();
          _showRewardDialog(context);
        },
      },
      {
        'icon': Icons.chat_bubble_outline_rounded,
        'count': context.watch<CommentsCubit>().state.comments.length,
        'label': 'Comments',
        'onTap': () {
          HapticFeedback.mediumImpact();
          _focusOnComments();
        },
      },
      {
        'icon': Icons.share_rounded,
        'count': 0,
        'label': 'Share',
        'onTap': () {
          HapticFeedback.mediumImpact();
          // Implement share functionality
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Sharing coming soon...'),
              backgroundColor: accentColor,
            ),
          );
        },
      },
    ];

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.2),
        end: Offset.zero,
      ).animate(_statsSlideAnimation),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: stats.map((stat) {
            return TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
              tween: Tween(begin: 0.8, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: _buildStatItem(
                    icon: stat['icon'] as IconData,
                    count: stat['count'] as int,
                    label: stat['label'] as String,
                    isActive: (stat['isActive'] as bool?) ?? false,
                    onTap: stat['onTap'] as VoidCallback,
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }
  Widget _buildStatItem({
    required IconData icon,
    required int count,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Icon(
              icon,
              color: isActive ? accentColor : Colors.white.withOpacity(0.6),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isActive ? accentColor : Colors.white,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComments(BuildContext context) {
    return BlocConsumer<CommentsCubit, CommentsState>(
      listener: (context, state) {
        if (state.status == CommentsStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error ?? 'An error occurred'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        return FadeTransition(
          opacity: _contentFadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Comments',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                _buildCommentsList(state),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCommentsList(CommentsState state) {
    switch (state.status) {
      case CommentsStatus.loading:
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(accentColor),
          ),
        );
      
      case CommentsStatus.success:
        if (state.comments.isEmpty) {
          return Center(
            child: Column(
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 48,
                  color: Colors.white.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No comments yet. Be the first!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.comments.length,
          itemBuilder: (context, index) {
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 200 + (index * 100)),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: ModernCommentCard(comment: state.comments[index]),
            );
          },
        );
      
case CommentsStatus.failure:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.red.withOpacity(0.7),
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load comments',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  context.read<CommentsCubit>().loadComments(
                    int.parse(widget.poem.id),
                  );
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: TextButton.styleFrom(
                  foregroundColor: accentColor,
                ),
              ),
            ],
          ),
        );
      
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCommentInput(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 8,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              child: TextField(
                controller: _commentController,
                focusNode: _commentFocusNode,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                  ),
                  border: InputBorder.none,
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ),
          const SizedBox(width: 8),
          BlocBuilder<CommentsCubit, CommentsState>(
            builder: (context, state) {
              final isLoading = state.status == CommentsStatus.loading;
              return Material(
                color: accentColor,
                borderRadius: BorderRadius.circular(25),
                child: InkWell(
                  onTap: isLoading ? null : () => _submitComment(context),
                  borderRadius: BorderRadius.circular(25),
                  child: Container(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _submitComment(BuildContext context) {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;
    
    HapticFeedback.mediumImpact();
    context.read<CommentsCubit>().addComment(
      content,
      int.parse(widget.poem.id),
    );
    _commentController.clear();
    FocusScope.of(context).unfocus();
  }
}

class ModernCommentCard extends StatelessWidget {
  final Comment comment;
  static const cardColor = Color(0xFF1E1E1E);
  static const accentColor = Color(0xFF6C63FF);
  const ModernCommentCard({
    Key? key,
    required this.comment,
  }) : super(key: key);
 
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                backgroundImage: NetworkImage(
                  'https://api.dicebear.com/7.x/avataaars/svg?seed=${comment.author}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.author,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      timeago.format(comment.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert_rounded),
                color: Colors.white.withOpacity(0.5),
                onPressed: () {
                  // Add comment options menu
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            comment.content,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildCommentAction(
                icon: Icons.favorite_border_rounded,
                label: '0',
                onTap: () {
                  // Add like functionality
                },
              ),
              const SizedBox(width: 16),
              _buildCommentAction(
                icon: Icons.reply_rounded,
                label: 'Reply',
                onTap: () {
                  // Add reply functionality
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: Colors.white.withOpacity(0.5),
              ),
              if (label.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}