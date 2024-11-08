import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_app/component/wallet_manager.dart';
import 'package:test_app/state/user.dart';
import 'package:test_app/widget/custom_button.dart';
import 'package:test_app/widget/custom_snackbar.dart';
class CreatePoemScreen extends StatefulWidget {
  const CreatePoemScreen({Key? key}) : super(key: key);

  @override
  _CreatePoemScreenState createState() => _CreatePoemScreenState();
}

class _CreatePoemScreenState extends State<CreatePoemScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();
  final _tagFocusNode = FocusNode();
  bool _isSubmitting = false;

  // Theme colors
  static const backgroundColor = Color(0xFF000000);
  static const surfaceColor = Color(0xFF121212);
  static const cardColor = Color(0xFF1E1E1E);
  static const accentColor = Color(0xFF6C63FF);

  // Suggested tags
  final List<String> suggestedTags = [
    'Love', 'Nature', 'Life', 'Hope', 'Dreams',
    'Family', 'Friendship', 'Journey', 'Soul', 'Heart',
    'Memories', 'Time', 'Faith', 'Peace', 'Freedom',
  ];

  Set<String> selectedTags = {};

  late AnimationController _animationController;
  late Animation<double> _formAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _formAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
    );

    _animationController.forward();

    _tagFocusNode.addListener(() {
      setState(() {}); // Rebuild for tag suggestions visibility
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddPoemCubit, AddPoemState>(
      listener: (context, state) {
        if (state is AddPoemSuccess) {
          _showSuccessSnackBar('Poem published successfully!');
          Navigator.pop(context);
        } else if (state is AddPoemFailure) {
          _showErrorSnackBar(state.error);
          setState(() => _isSubmitting = false);
        } else if (state is AddPoemLoading) {
          setState(() => _isSubmitting = true);
        }
      },
      child: Theme(
        data: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: backgroundColor,
          appBarTheme: const AppBarTheme(
            backgroundColor: backgroundColor,
            elevation: 0,
          ),
        ),
        child: Scaffold(
          appBar: AppBar(
            title: const Text(
              'Create Poem',
              style: TextStyle(
                fontFamily: 'Lora',
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: _isSubmitting ? null : () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FadeTransition(
                opacity: _formAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(_formAnimation),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTitleField(),
                        const SizedBox(height: 24),
                        _buildContentField(),
                        const SizedBox(height: 24),
                        _buildTagsSection(),
                        const SizedBox(height: 32),
                        _buildPublishButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: TextFormField(
        controller: _titleController,
        enabled: !_isSubmitting,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontFamily: 'Lora',
        ),
        decoration: InputDecoration(
          labelText: 'Title',
          labelStyle: TextStyle(
            color: Colors.white.withOpacity(0.6),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
          prefixIcon: Icon(
            Icons.title,
            color: accentColor.withOpacity(0.7),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: accentColor.withOpacity(0.5),
            ),
          ),
        ),
        validator: (value) {
          if (value?.isEmpty ?? true) {
            return 'Please enter a title';
          }
          if (value!.length < 3 || value.length > 100) {
            return 'Title must be between 3 and 100 characters';
          }
          return null;
        },
        textInputAction: TextInputAction.next,
      ),
    );
  }

  Widget _buildContentField() {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: TextFormField(
        controller: _contentController,
        enabled: !_isSubmitting,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          height: 1.8,
          fontFamily: 'Lora',
        ),
        decoration: InputDecoration(
          labelText: 'Write your poem...',
          labelStyle: TextStyle(
            color: Colors.white.withOpacity(0.6),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
          alignLabelWithHint: true,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: accentColor.withOpacity(0.5),
            ),
          ),
        ),
        maxLines: 10,
        validator: (value) {
          if (value?.isEmpty ?? true) {
            return 'Please enter your poem';
          }
          if (value!.length < 3 || value.length > 5000) {
            return 'Poem must be between 3 and 5000 characters';
          }
          return null;
        },
        textInputAction: TextInputAction.newline,
      ),
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: TextFormField(
            controller: _tagsController,
            focusNode: _tagFocusNode,
            enabled: !_isSubmitting,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              labelText: 'Tags (separated by commas)',
              labelStyle: TextStyle(
                color: Colors.white.withOpacity(0.6),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
              prefixIcon: Icon(
                Icons.label,
                color: accentColor.withOpacity(0.7),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: accentColor.withOpacity(0.5),
                ),
              ),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter at least one tag';
              }
              final tags = value!.split(',').map((tag) => tag.trim()).toList();
              if (tags.length < 3 || tags.length > 15) {
                return 'You must have between 3 and 15 tags';
              }
              return null;
            },
            textInputAction: TextInputAction.done,
          ),
        ),
        if (_tagFocusNode.hasFocus) ...[
          const SizedBox(height: 16),
          Text(
            'Suggested Tags',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestedTags.map((tag) {
              final isSelected = selectedTags.contains(tag);
              return TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 200),
                tween: Tween(begin: 0.8, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _handleTagSelection(tag),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? accentColor.withOpacity(0.2)
                                : cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? accentColor
                                  : Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                tag,
                                style: TextStyle(
                                  color: isSelected
                                      ? accentColor
                                      : Colors.white.withOpacity(0.9),
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.check,
                                  size: 16,
                                  color: accentColor,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildPublishButton() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.8, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentColor,
                  accentColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isSubmitting ? null : _handlePublish,
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Publish Poem',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleTagSelection(String tag) {
    setState(() {
      if (selectedTags.contains(tag)) {
        selectedTags.remove(tag);
      } else {
        selectedTags.add(tag);
      }
      
      _tagsController.text = selectedTags.join(', ');
    });
    
    HapticFeedback.lightImpact();
  }


 Future<void> _handlePublish() async {
  if (_formKey.currentState?.validate() ?? false) {
    try {
      // Check for private key first
      final hasPrivateKey = await WalletManager.hasPrivateKey();
      
      if (!hasPrivateKey) {
        // Show private key dialog
        final result = await showPrivateKeyDialog(context);
        if (result == null) {
          _showErrorSnackBar('Private key is required to publish poems');
          return;
        }
      }
      final privateKey = await WalletManager.getPrivateKey();

      final tags = _tagsController.text.split(',').map((tag) => tag.trim()).toList();
      await context.read<AddPoemCubit>().addPoem(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        tags: tags,
        privateKey: privateKey!
      );
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }
}

// Add this beautiful private key dialog
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

// Add this method to show a loading overlay during blockchain transactions
void _showLoadingOverlay(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(accentColor),
            ),
            const SizedBox(height: 16),
            Text(
              'Publishing Poem...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait while we process your transaction',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// Update the success snackbar to show transaction details
void _showSuccessSnackBar(String message, {String? txHash}) {
  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (txHash != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Transaction Hash: ',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      txHash,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.copy_rounded,
                      size: 16,
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: txHash));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Transaction hash copied'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: cardColor,
      duration: const Duration(seconds: 5),
    ),
  );
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
    _tagsController.dispose();
    super.dispose();
  }
}