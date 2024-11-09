import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_app/screens/mnemonic_scrren.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:test_app/state/auth_state.dart';
import 'package:test_app/home.dart';

class PrivateKeyInputScreen extends StatefulWidget {
  const PrivateKeyInputScreen({Key? key}) : super(key: key);

  @override
  _PrivateKeyInputScreenState createState() => _PrivateKeyInputScreenState();
}

class _PrivateKeyInputScreenState extends State<PrivateKeyInputScreen>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authorNameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _mnemonicController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _secureStorage = const FlutterSecureStorage();

  // Theme colors
  static const backgroundColor = Color(0xFF000000);
  static const surfaceColor = Color(0xFF121212);
  static const cardColor = Color(0xFF1E1E1E);
  static const accentColor = Color(0xFF6C63FF);

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSignup = false;
  XFile? _selectedProfileImage;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
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
      curve: Curves.easeOutCubic,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
  return Theme(
    data: ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF000000), // Pure black background
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF000000),
        elevation: 0,
      ),
    ),
      child: Scaffold(
        body: BlocConsumer<AuthCubit, AuthState>(
             listener: (context, state) async {
          // Handle different authentication states
          if (state is AuthAuthenticated) {
            if (_isSignup) {
              final _prefs = await SharedPreferences.getInstance();
              final key = _prefs.getString('key');
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => MnemonicGenerationScreen(
                  encryptionKey: key!,
                  onComplete: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => HomeScreen()),
                    );
                  },
                )),
              );
            } else {
              // Navigate to home screen on successful authentication
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => HomeScreen()),
              );
            }
          } else if (state is AuthError) {
            // Show error in a snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    _buildHeader(),
                    const SizedBox(height: 40),
                    _buildForm(state),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

  Widget _buildHeader() {
  return FadeTransition(
    opacity: _fadeAnimation,
    child: Column(
      children: [
        // Logo
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.asset(
            'assets/icon.png',
            width: 80,
            height: 80,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // App Name
        Text(
          'PoetsLoom',
          style: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Tagline
        Text(
          _isSignup ? 'Create your account' : 'Welcome back',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    ),
  );
}

Widget _buildForm(AuthState state) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (_isSignup) ...[
        _buildProfileImagePicker(),
        const SizedBox(height: 32),
      ],
      
      _buildInputField(
        controller: _usernameController,
        label: 'Username',
        icon: Icons.person_outline,
      ),
      
      const SizedBox(height: 16),
      
      if (_isSignup) ...[
        _buildInputField(
          controller: _authorNameController,
          label: 'Author Name',
          icon: Icons.edit_outlined,
        ),
        const SizedBox(height: 16),
      ],
      
      _buildPasswordField(),
      
      if (!_isSignup) ...[
        const SizedBox(height: 16),
        _buildInputField(
          controller: _mnemonicController,
          label: 'Recovery Phrase',
          icon: Icons.key_outlined,
        ),
      ],
      
      if (_isSignup) ...[
        const SizedBox(height: 16),
        _buildConfirmPasswordField(),
      ],
      
      const SizedBox(height: 32),
      _buildSubmitButton(state),
      const SizedBox(height: 20),
      _buildToggleButton(),
    ],
  );
}

Widget _buildInputField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
}) {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFF1A1A1A), // Slightly lighter than background
      borderRadius: BorderRadius.circular(12),
    ),
    child: TextFormField(
      controller: controller,
      style: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          color: Colors.grey[400],
          fontSize: 14,
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.grey[400],
          size: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: (value) {
        if (value?.isEmpty ?? true) {
          return 'This field is required';
        }
        return null;
      },
    ),
  );
}


Widget _buildSubmitButton(AuthState state) {
  return SizedBox(
    height: 50,
    child: ElevatedButton(
      onPressed: state is! AuthLoading ? _submitForm : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: accentColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: state is AuthLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              _isSignup ? 'Create Account' : 'Sign In',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
    ),
  );
}

Widget _buildToggleButton() {
  return TextButton(
    onPressed: () {
      setState(() {
        _isSignup = !_isSignup;
        _usernameController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
        _selectedProfileImage = null;
      });
    },
    style: TextButton.styleFrom(
      foregroundColor: Colors.grey[400],
    ),
    child: Text(
      _isSignup
          ? 'Already have an account? Sign in'
          : "Don't have an account? Create one",
      style: GoogleFonts.inter(fontSize: 14),
    ),
  );
}
  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: 'Password',
          labelStyle: TextStyle(
            color: Colors.white.withOpacity(0.6),
          ),
          prefixIcon: Icon(
            Icons.lock_outline_rounded,
            color: accentColor.withOpacity(0.7),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: Colors.white.withOpacity(0.5),
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Password is required';
          }
          if (value.length < 8) {
            return 'Password must be at least 8 characters';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: TextFormField(
        controller: _confirmPasswordController,
        obscureText: _obscureConfirmPassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: 'Confirm Password',
          labelStyle: TextStyle(
            color: Colors.white.withOpacity(0.6),
          ),
          prefixIcon: Icon(
            Icons.lock_outline_rounded,
            color: accentColor.withOpacity(0.7),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: Colors.white.withOpacity(0.5),
            ),
            onPressed: () => setState(() => 
                _obscureConfirmPassword = !_obscureConfirmPassword),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
        validator: (value) {
          if (value != _passwordController.text) {
            return 'Passwords do not match';
          }
          return null;
        },
      ),
    );
  }


  Widget _buildProfileImageSelector() {
    return GestureDetector(
      onTap: _selectProfileImage,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[300],
          image: _selectedProfileImage != null
              ? DecorationImage(
                  image: kIsWeb
                      ? Image.network(_selectedProfileImage!.path).image
                      : FileImage(File(_selectedProfileImage!.path)),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: _selectedProfileImage == null
            ? const Icon(Icons.camera_alt, size: 40, color: Colors.grey)
            : null,
      ),
    );
  }
Future<void> _selectProfileImage() async {
  try {
    // Request the necessary permissions
    PermissionStatus cameraStatus = await Permission.camera.request();
    PermissionStatus storageStatus = await Permission.storage.request();

    if (cameraStatus.isGranted && storageStatus.isGranted) {
      // Permission granted, proceed with image selection
      final pickedImage = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Compress image
        maxWidth: 600,    // Limit image size
      );

      if (pickedImage != null) {
        setState(() {
          _selectedProfileImage = pickedImage;
        });
      }
    } else {
      // Permission denied, show a dialog to the user
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Permission Required',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Please enable camera and storage access in your device settings to select a profile picture.',
            style: TextStyle(color: Colors.grey[400]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Open app settings
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
    }
  } catch (e) {
    // Handle any other exceptions
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          'Error',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'An error occurred while selecting the profile picture: $e',
          style: TextStyle(color: Colors.grey[400]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
// Add options to choose between camera and gallery
Future<void> _showImageSourceDialog() async {
  await showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1A1A1A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: Colors.white),
            title: const Text(
              'Choose from Library',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () async {
              Navigator.pop(context);
              final pickedImage = await ImagePicker().pickImage(
                source: ImageSource.gallery,
                imageQuality: 70,
                maxWidth: 600,
              );
              if (pickedImage != null) {
                setState(() {
                  _selectedProfileImage = pickedImage;
                });
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined, color: Colors.white),
            title: const Text(
              'Take a Photo',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () async {
              Navigator.pop(context);
              final pickedImage = await ImagePicker().pickImage(
                source: ImageSource.camera,
                imageQuality: 70,
                maxWidth: 600,
              );
              if (pickedImage != null) {
                setState(() {
                  _selectedProfileImage = pickedImage;
                });
              }
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
}

// Update the profile image picker UI to use the new selection dialog
Widget _buildProfileImagePicker() {
  return Column(
    children: [
      GestureDetector(
        onTap: _showImageSourceDialog, // Use new selection dialog
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            shape: BoxShape.circle,
            border: Border.all(
              color: _selectedProfileImage != null
                  ? accentColor
                  : Colors.grey[800]!,
              width: 2,
            ),
            image: _selectedProfileImage != null
                ? DecorationImage(
                    image: FileImage(File(_selectedProfileImage!.path)),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: _selectedProfileImage == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      color: Colors.grey[400],
                      size: 32,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add photo',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                )
              : null,
        ),
      ),
      if (_selectedProfileImage == null) ...[
        const SizedBox(height: 8),
        Text(
          'Choose a profile photo',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
      ],
    ],
  );
}


  void _submitForm() async {
     if (_isSignup && _selectedProfileImage == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            const Text('Please select a profile photo'),
          ],
        ),
        backgroundColor: Colors.red.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
    return;
  }

    if (_formKey.currentState!.validate()) {
      final authCubit = context.read<AuthCubit>();
Uint8List profileImage = await File(_selectedProfileImage!.path).readAsBytes(); // For mobile or other platforms  

      try {
        if (_isSignup) {
          // Signup logic
          await authCubit.signup(
            username: _usernameController.text,
            password: _passwordController.text,
            author_name: _authorNameController.text,
            filePath: _selectedProfileImage!.path,
            profileImage: profileImage,
        );
        } else {
          // Login logic
          await authCubit.login(
            email: _usernameController.text,
            password: _passwordController.text,
            mnemonic: _mnemonicController.text,
          );
        }

        // Save private key securely
        await _savePrivateKeyInSharedPreferences(
          _usernameController.text,
          _passwordController.text,
          _authorNameController.text,
        );
      } catch (e) {
        // Handle errors
        handleSubmitError(e, context);
      }
    }
  }
 void handleSubmitError(Object error, BuildContext context) {
    // Check if the error is a web-specific error
    if (kIsWeb && error is ArgumentError) {
      // Handle web-specific error cases
      String errorMessage = 'An error occurred during the submission process.';
      if (error.message.contains('localStorage')) {
        errorMessage = 'Local storage is not available on the web.';
      } else if (error.message.contains('FileReader')) {
        errorMessage = 'There was an issue reading the selected file.';
      }
      // Add more web-specific error handling logic here

      // Show the error message in a snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      // Handle other types of errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
  Future<void> _savePrivateKeyInSharedPreferences(
      String username, String password, String author_name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    await prefs.setString('password', password);
    await prefs.setString('author_name', author_name);
  }
  TextFormField _buildUsernameField() {
    return TextFormField(
      controller: _usernameController,
      decoration: const InputDecoration(
        labelText: 'Username',
        prefixIcon: Icon(Icons.person),
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a username';
        }
        return null;
      },
    );
  }

  TextFormField _buildAuthorField() {
    return TextFormField(
      controller: _authorNameController,
      decoration: const InputDecoration(
        labelText: 'Author Name',
        prefixIcon: Icon(Icons.person),
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your name';
        }
        return null;
      },
    );
  }

  TextFormField _buildmnemonicField() {
    return TextFormField(
      controller: _mnemonicController,
      decoration: const InputDecoration(
        labelText: 'Enter mnemonic phrases',
        prefixIcon: Icon(Icons.person),
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your mnemonic phrases';
        }
        return null;
      },
    );
  }

  

  Widget _buildToggleAuthModeButton() {
    return TextButton(
      onPressed: () {
        setState(() {
          _isSignup = !_isSignup;
          // Reset controllers when switching modes
          _usernameController.clear();
          _passwordController.clear();
          _confirmPasswordController.clear();
        });
      },
      child: Text(_isSignup 
        ? 'Already have an account? Login' 
        : 'Don\'t have an account? Sign Up'),
    );
  }

  String _encryptPassword(String password, String publicAddress) {
    // Generate a key from the hash of the public address
    final keyBytes = sha256.convert(utf8.encode(publicAddress)).bytes;
    final key = encrypt.Key(Uint8List.fromList(keyBytes).sublist(0, 32)); // AES-256 requires a 32-byte key

    // Generate a 16-byte IV
    final iv = encrypt.IV.fromLength(16);

    // Create the encrypter with AES algorithm
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    // Encrypt the password
    final encrypted = encrypter.encrypt(password, iv: iv);

    // Return the encrypted password as a base64 string
    return encrypted.base64;
  }

  Future<void> _savePrivateKey(String username, String password, String author_name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    await prefs.setString('password', password);
    await prefs.setString('author_name', author_name);
  }


}