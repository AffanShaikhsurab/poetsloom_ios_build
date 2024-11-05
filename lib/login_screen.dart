import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_app/screens/mnemonic_scrren.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';

import 'package:test_app/state/auth_state.dart';
import 'package:test_app/home.dart';

class PrivateKeyInputScreen extends StatefulWidget {
  const PrivateKeyInputScreen({Key? key}) : super(key: key);

  @override
  _PrivateKeyInputScreenState createState() => _PrivateKeyInputScreenState();
}

class _PrivateKeyInputScreenState extends State<PrivateKeyInputScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authorNameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
    final _mnemonicController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final _secureStorage = const FlutterSecureStorage();

  bool _obscurePrivateKey = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSignup = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSignup ? 'Sign Up' : 'Connect Wallet'),
        centerTitle: true,
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) async {
          // Handle different authentication states
          if (state is AuthAuthenticated) {
            if(_isSignup){
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
            }else{
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
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  Text(
                    _isSignup ? 'Create Your Wallet' : 'Connect Your Wallet',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  
                  // Username Input
                  _buildUsernameField(),
                  const SizedBox(height: 20),
                   if (_isSignup)  _buildAuthorField(),
                  const SizedBox(height: 20,),
                  // Password Input
                  _buildPasswordField(),
                  const SizedBox(height: 20),

                    if (!_isSignup) _buildmnemonicField(),
                  const SizedBox(height: 20),
                  // Confirm Password (for Signup)
                  if (_isSignup) _buildConfirmPasswordField(),
                  if (_isSignup) const SizedBox(height: 20),
                  
                  // Private Key Input
                  // _buildPrivateKeyField(),
                  // const SizedBox(height: 20),

                  // Submit Button
                  _buildSubmitButton(state),
                  const SizedBox(height: 10),

                  // Toggle between Login and Signup
                  _buildToggleAuthModeButton(),
                ],
              ),
            ),
          );
        },
      ),
    );
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
  TextFormField _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword 
            ? Icons.visibility 
            : Icons.visibility_off),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        border: const OutlineInputBorder(),
      ),
      obscureText: _obscurePassword,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a password';
        }
        if (value.length < 8) {
          return 'Password must be at least 8 characters';
        }
        return null;
      },
    );
  }

  TextFormField _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      decoration: InputDecoration(
        labelText: 'Confirm Password',
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(_obscureConfirmPassword 
            ? Icons.visibility 
            : Icons.visibility_off),
          onPressed: () {
            setState(() {
              _obscureConfirmPassword = !_obscureConfirmPassword;
            });
          },
        ),
        border: const OutlineInputBorder(),
      ),
      obscureText: _obscureConfirmPassword,
      validator: (value) {
        if (_isSignup) {
          if (value == null || value.isEmpty) {
            return 'Please confirm your password';
          }
          if (value != _passwordController.text) {
            return 'Passwords do not match';
          }
        }
        return null;
      },
    );
  }






  Widget _buildSubmitButton(AuthState state) {
    return ElevatedButton(
      onPressed: state is! AuthLoading ? _submitForm : null,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        backgroundColor: state is AuthLoading 
          ? Colors.grey 
          : Theme.of(context).primaryColor,
      ),
      child: state is AuthLoading 
        ? const CircularProgressIndicator(color: Colors.white)
        : Text(_isSignup ? 'Sign Up' : 'Connect'),
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

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final authCubit = context.read<AuthCubit>();
      
      try {
        // Import existing wallet

        // Encrypt password using private key
  

        if (_isSignup) {
          // Signup logic
          await authCubit.signup(
            username: _usernameController.text,
            password: _passwordController.text,
            author_name : _authorNameController.text,
          );
        } else {
          // Login logic
          await authCubit.login(
            email: _usernameController.text,
            password: _passwordController.text,
            mnemonic: _mnemonicController.text
          );
        }

        // Save private key securely
        await _savePrivateKey( _usernameController.text , _passwordController.text , _authorNameController.text);
      } catch (e) {
        // The error will be handled by the BlocConsumer listener
      }
    }
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

  Future<void> _savePrivateKey(String username , String password , String author_name) async {
      final prefs = await SharedPreferences.getInstance();
            await prefs.setString('username', username);
            await prefs.setString('password', password);
            await prefs.setString('author_name', author_name);
   
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}