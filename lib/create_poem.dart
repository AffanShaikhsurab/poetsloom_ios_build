import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_app/search.dart';
import 'package:test_app/state/user.dart';
import 'package:test_app/widget/custom_button.dart';

class CreatePoemScreen extends StatefulWidget {
  const CreatePoemScreen({Key? key}) : super(key: key);

  @override
  _CreatePoemScreenState createState() => _CreatePoemScreenState();
}

class _CreatePoemScreenState extends State<CreatePoemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddPoemCubit, AddPoemState>(
      listener: (context, state) {
        if (state is AddPoemSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: CustomSnackBar(
                message: 'Poem published successfully!',
                icon: Icons.check_circle_outline,
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
          );
          Navigator.pop(context);
        } else if (state is AddPoemFailure) {
          _showErrorSnackBar(state.error);
          setState(() => _isSubmitting = false);
        } else if (state is AddPoemLoading) {
          setState(() => _isSubmitting = true);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create Poem'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTitleField(),
                const SizedBox(height: 16),
                _buildContentField(),
                const SizedBox(height: 24),
                _buildPublishButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      enabled: !_isSubmitting,
      decoration: InputDecoration(
        labelText: 'Title',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.title),
      ),
      validator: (value) {
        if (value?.isEmpty ?? true) {
          return 'Please enter a title';
        }
        if (value!.length > 100) {
          return 'Title must be less than 100 characters';
        }
        return null;
      },
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildContentField() {
    return TextFormField(
      controller: _contentController,
      enabled: !_isSubmitting,
      decoration: InputDecoration(
        labelText: 'Content',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        alignLabelWithHint: true,
        prefixIcon: const Icon(Icons.edit),
      ),
      maxLines: 10,
      validator: (value) {
        if (value?.isEmpty ?? true) {
          return 'Please enter your poem';
        }
        if (value!.length > 5000) {
          return 'Poem must be less than 5000 characters';
        }
        return null;
      },
      textInputAction: TextInputAction.newline,
    );
  }

  Widget _buildPublishButton() {
    return CustomButton(
      text: 'Publish Poem',
      isLoading: _isSubmitting,
      onPressed: _handlePublish,
    );
  }

  Future<void> _handlePublish() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        await context.read<AddPoemCubit>().addPoem(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
        );
      } catch (e) {
        // Error will be handled by BlocListener
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: CustomSnackBar(
          message: message,
          icon: Icons.error_outline,
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}

// Assuming you have a CustomSnackBar widget, if not, here's a simple implementation: