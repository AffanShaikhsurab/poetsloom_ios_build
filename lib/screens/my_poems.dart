import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_app/model.dart';
import 'package:test_app/screens/edit_screen.dart';
import 'package:test_app/state/author_poems.dart';
import 'package:test_app/widget/custom_button.dart';

import 'package:timeago/timeago.dart' as timeago;

class AuthorPoemsScreen extends StatefulWidget {
  const AuthorPoemsScreen({super.key});

  @override
  State<AuthorPoemsScreen> createState() => _AuthorPoemsScreenState();
}

class _AuthorPoemsScreenState extends State<AuthorPoemsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AuthorPoemsCubit>().loadAuthorPoems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Poems',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: BlocBuilder<AuthorPoemsCubit, AuthorPoemsState>(
        builder: (context, state) {
          switch (state.status) {
            case AuthorPoemsStatus.loading:
              return const Center(
                child: CircularProgressIndicator(),
              );

            case AuthorPoemsStatus.failure:
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.error ?? 'Something went wrong',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<AuthorPoemsCubit>().loadAuthorPoems();
                      },
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              );

            case AuthorPoemsStatus.success:
              if (state.poems.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.note_outlined,
                        size: 60,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No poems yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Start writing your first poem!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await context.read<AuthorPoemsCubit>().loadAuthorPoems();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.poems.length,
                  itemBuilder: (context, index) {
                    final poem = state.poems[index];
                    return PoemCard(
                      poem: poem,
                      onEdit: () {
                        _navigateToEditPoem(poem);
                      },
                    );
                  },
                ),
              );

            default:
              return const SizedBox.shrink();
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _navigateToEditPoem(null);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToEditPoem(Poem? poem) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPoemScreen(poem: poem),
      ),
    ).then((_) {
      context.read<AuthorPoemsCubit>().loadAuthorPoems();
    });
  }
}



class PoemCard extends StatelessWidget {
  final Poem poem;
  final VoidCallback onEdit;

  const PoemCard({
    super.key,
    required this.poem,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(poem.authorAvatar),
                  radius: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        poem.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        timeago.format(poem.createdAt),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: onEdit,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              poem.content,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.favorite,
                      color: poem.isLiked ? Colors.red : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      poem.likes.toString(),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.diamond_outlined,
                      color: Colors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      poem.rewards.toString(),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}