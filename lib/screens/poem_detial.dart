import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_app/model.dart';
import 'package:test_app/services/contract.dart';
import 'package:test_app/state/poem_details.dart';
import 'package:test_app/state/poems.dart';

class PoemDetailScreen extends StatefulWidget {
  final Poem poem;

  const PoemDetailScreen({Key? key, required this.poem}) : super(key: key);

  @override
  _PoemDetailScreenState createState() => _PoemDetailScreenState();
}

class _PoemDetailScreenState extends State<PoemDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CommentsCubit(
        poetsLoomService: PoetsLoomService(
        rpcUrl: 'https://eth-sepolia.g.alchemy.com/v2/bTJkxdz694BiZKrP7qINHw7NQUrpnd75',
        contractAddress: '0xF0F5234959166Cc8D2Ee9F4C4e029cdbdac93266',
        privateKey: "dc50e7d15fc7a35ed046e5d2c5151da2bb9a9fd427b2b00ba7db891dd11d0070"

      )
      )..loadComments(int.parse(widget.poem.id)),
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                widget.poem.title,
                style: const TextStyle(
                  fontFamily: 'Lora',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            body: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Author Info Section
                      ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(widget.poem.authorAvatar),
                        ),
                        title: Text(widget.poem.authorName),
                        subtitle: Text('@${widget.poem.authorUsername}'),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Poem Content Section
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.poem.content,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  height: 1.6,
                                  fontFamily: 'Lora',
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Created on ${_formatDate(widget.poem.createdAt)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Interaction Stats
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStat(
                            icon: Icons.favorite,
                            count: widget.poem.likes,
                            label: 'Likes',
                            isActive: widget.poem.isLiked,
                            onTap: () => context.read<PoetryCubit>().likePoem(widget.poem),
                          ),
                          _buildStat(
                            icon: Icons.card_giftcard,
                            count: widget.poem.rewards,
                            label: 'Rewards',
                            onTap: () => _showRewardDialog(context),
                          ),
                          BlocBuilder<CommentsCubit, CommentsState>(
                            builder: (context, state) {
                              return _buildStat(
                                icon: Icons.chat_bubble_outline,
                                count: state.comments.length,
                                label: 'Comments',
                                onTap: () => _focusOnComments(),
                              );
                            },
                          ),
                          _buildStat(
                            icon: Icons.share,
                            count: 0,
                            label: 'Share',
                            onTap: () {/* Implement share functionality */},
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      const Divider(),
                      
                      // Comments Section
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Comments',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),

                      // Comments List
                      BlocConsumer<CommentsCubit, CommentsState>(
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
                          switch (state.status) {
                            case CommentsStatus.loading:
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            
                            case CommentsStatus.success:
                              if (state.comments.isEmpty) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.chat_bubble_outline, 
                                          size: 48, 
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No comments yet. Be the first!',
                                          style: TextStyle(color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              
                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: state.comments.length,
                                itemBuilder: (context, index) {
                                  final comment = state.comments[index];
                                  return CommentCard(comment: comment);
                                },
                              );
                            
                            case CommentsStatus.failure:
                              return Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 48,
                                      color: Colors.red[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Failed to load comments',
                                      style: TextStyle(color: Colors.red[400]),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        context.read<CommentsCubit>().loadComments(int.parse(widget.poem.id));
                                      },
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              );
                            
                            default:
                              return const SizedBox.shrink();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                
                // Comment Input Section
                Container(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                    left: 16,
                    right: 16,
                    top: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          focusNode: _commentFocusNode,
                          decoration: const InputDecoration(
                            hintText: 'Add a comment...',
                            border: InputBorder.none,
                          ),
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ),
                      BlocBuilder<CommentsCubit, CommentsState>(
                        builder: (context, state) {
                          final isLoading = state.status == CommentsStatus.loading;
                          return IconButton(
                            icon: isLoading 
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.send),
                            onPressed: isLoading ? null : () => _submitComment(context),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required int count,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Icon(
              icon,
              color: isActive ? Theme.of(context).primaryColor : null,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showRewardDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reward Poem'),
        content: const Text('Reward functionality coming soon...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _focusOnComments() {
    _commentFocusNode.requestFocus();
  }

  void _submitComment(BuildContext context) {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;
    
    context.read<CommentsCubit>().addComment(content , int.parse(widget.poem.id));
    _commentController.clear();
    FocusScope.of(context).unfocus();
  }
}

class CommentCard extends StatelessWidget {
  final Comment comment;

  const CommentCard({Key? key, required this.comment}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  comment.author,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatTimestamp(comment.timestamp),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              comment.content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }
}