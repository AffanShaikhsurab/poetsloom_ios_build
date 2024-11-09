import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:test_app/authservice.dart';
import 'dart:io';

import 'package:test_app/state/edit_state.dart';
import 'package:test_app/utils/app_colors.dart';

class ProfileEditScreen extends StatefulWidget {
  final User currentUser;
  
  const ProfileEditScreen({
    Key? key,
    required this.currentUser,
  }) : super(key: key);

  @override
  _ProfileEditScreenState createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> 
    with SingleTickerProviderStateMixin {
  late TextEditingController _nameController;
  File? _selectedImage;
  bool _isLoading = false;
  bool _hasChanges = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentUser.author_name);
    _nameController.addListener(_checkChanges);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    _animationController.forward();
  }

  void _checkChanges() {
    final hasNameChanged = _nameController.text != widget.currentUser.author_name;
    final hasImageChanged = _selectedImage != null;
    
    setState(() {
      _hasChanges = hasNameChanged || hasImageChanged;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileEditCubit, ProfileEditState>(
      listener: (context, state) {
        if (state is ProfileEditSuccess) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile updated successfully')),
          );
        } else if (state is ProfileEditFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error)),
          );
        }
      },
      child: Theme(
        data: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: AppColors.backgroundColor,
        ),
        child: Scaffold(
          appBar: AppBar(
            title: Text('Edit Profile'),
            actions: [
              if (_hasChanges)
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: TextButton(
                    onPressed: _handleSave,
                    child: Text('Save'),
                  ),
                ),
            ],
          ),
          body: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildImageSection(),
                  SizedBox(height: 32),
                  _buildNameSection(),
                  SizedBox(height: 32),
                  _buildPreview(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(0, 0.2),
        end: Offset.zero,
      ).animate(_slideAnimation),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Stack(
            children: [
              Hero(
                tag: 'profile-${widget.currentUser.id}',
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.accentColor.withOpacity(0.3),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentColor.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _selectedImage != null
                        ? Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            widget.currentUser.profile ?? '',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 300),
                  tween: Tween(begin: 0.8, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.accentColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _pickImage,
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameSection() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(0, 0.3),
        end: Offset.zero,
      ).animate(_slideAnimation),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Display Name',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              child: TextField(
                controller: _nameController,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter your display name',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: AppColors.accentColor.withOpacity(0.7),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (!_hasChanges) return SizedBox.shrink();

    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(0, 0.4),
        end: Offset.zero,
      ).animate(_slideAnimation),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.accentColor.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Preview',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: _selectedImage != null
                          ? DecorationImage(
                              image: FileImage(_selectedImage!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _selectedImage == null
                        ? Icon(
                            Icons.person,
                            color: Colors.white.withOpacity(0.5),
                          )
                        : null,
                  ),
                  SizedBox(width: 16),
                  Text(
                    _nameController.text,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _checkChanges();
      });
    }
  }

  
  Future<void> _handleSave() async {
    if (!_hasChanges) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Save Changes',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to update your profile?',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white.withOpacity(0.7),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: Text(
              'Save',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        actionsPadding: EdgeInsets.all(16),
        contentPadding: EdgeInsets.fromLTRB(24, 16, 24, 8),
        titlePadding: EdgeInsets.fromLTRB(24, 24, 24, 8),
      ),
    );

    if (confirmed == true) {
      context.read<ProfileEditCubit>().updateProfile(
        authorName: _nameController.text,
        imageFile: _selectedImage,
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}