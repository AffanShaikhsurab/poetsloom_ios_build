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
        scaffoldBackgroundColor: backgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: backgroundColor,
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
            return Stack(
              children: [
                // Background gradient
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          accentColor.withOpacity(0.1),
                          backgroundColor,
                        ],
                      ),
                    ),
                  ),
                ),

                // Main content
                SafeArea(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 40),
                          _buildHeader(),
                          const SizedBox(height: 40),
                          _buildForm(state),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isSignup ? 'Create Account' : 'Welcome Back',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _isSignup 
                ? 'Start your poetic journey today'
                : 'Sign in to continue your journey',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(AuthState state) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.2),
        end: Offset.zero,
      ).animate(_slideAnimation),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            if (_isSignup) _buildProfileImagePicker(),
            if (_isSignup) const SizedBox(height: 24),
            _buildInputField(
              controller: _usernameController,
              label: 'Username',
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 16),
            if (_isSignup) _buildInputField(
              controller: _authorNameController,
              label: 'Author Name',
              icon: Icons.edit_outlined,
            ),
            if (_isSignup) const SizedBox(height: 16),
            _buildPasswordField(),
            const SizedBox(height: 16),
            if (!_isSignup) _buildInputField(
              controller: _mnemonicController,
              label: 'Mnemonic Phrases',
              icon: Icons.vpn_key_outlined,
            ),
            if (!_isSignup) const SizedBox(height: 16),
            if (_isSignup) _buildConfirmPasswordField(),
            if (_isSignup) const SizedBox(height: 16),
            const SizedBox(height: 24),
            _buildSubmitButton(state),
            const SizedBox(height: 24),
            _buildToggleButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImagePicker() {
    return GestureDetector(
      onTap: _selectProfileImage,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cardColor,
          border: Border.all(
            color: accentColor.withOpacity(0.3),
            width: 2,
          ),
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
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_rounded,
                    size: 32,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add Photo',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.white.withOpacity(0.6),
          ),
          prefixIcon: Icon(
            icon,
            color: accentColor.withOpacity(0.7),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'This field is required';
          }
          return null;
        },
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

  Widget _buildSubmitButton(AuthState state) {
    return Container(
      width: double.infinity,
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
          onTap: state is! AuthLoading ? _submitForm : null,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: state is AuthLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    _isSignup ? 'Create Account' : 'Sign In',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton() {
    return Center(
      child: TextButton(
        onPressed: () {
          setState(() {
            _isSignup = !_isSignup;
            _usernameController.clear();
            _passwordController.clear();
            _confirmPasswordController.clear();
            _selectedProfileImage = null;
            
            // Replay animations
            _animationController.reset();
            _animationController.forward();
          });
        },
        child: Text(
          _isSignup
              ? 'Already have an account? Sign In'
              : 'Don\'t have an account? Sign Up',
          style: const TextStyle(
            color: accentColor,
            fontWeight: FontWeight.w500,
          ),
        ),
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
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _selectedProfileImage = pickedImage ;
      });
    }
  }

  void _submitForm() async {
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