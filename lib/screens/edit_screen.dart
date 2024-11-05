import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_app/model.dart';
import 'package:test_app/state/author_poems.dart';
import 'package:test_app/state/poems.dart';

class EditPoemScreen extends StatefulWidget {
  final Poem? poem;

  const EditPoemScreen({super.key, this.poem});

  @override
  State<EditPoemScreen> createState() => _EditPoemScreenState();
}

class _EditPoemScreenState extends State<EditPoemScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.poem != null) {
      _titleController.text = widget.poem!.title;
      _contentController.text = widget.poem!.content;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.poem == null ? 'New Poem' : 'Edit Poem'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Content',
                border: OutlineInputBorder(),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                final title = _titleController.text.trim();
                final content = _contentController.text.trim();

                if (title.isNotEmpty && content.isNotEmpty) {
                  if (widget.poem == null) {
                    // context.read<UserPoemsCubit>().createPoem(title, content);
                  } else {
                    context
                        .read<AuthorPoemsCubit>()
                        .updatePoem( title: title, content : content ,hash: widget.poem!.poemHash);
                  }
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in the title and content.'),
                    ),
                  );
                }
              },
              child: Text(widget.poem == null ? 'Create' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}