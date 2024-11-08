import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_app/services/mnemonic.dart';
import 'package:web3dart/web3dart.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class AuthService with ChangeNotifier {
  final SupabaseClient _supabase;
  late SharedPreferences prefs ;
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  final baseUrl = "https://poetsloom-mnemonic.onrender.com";
  String? _token;
  User? _currentUser;
  
  bool get isAuthenticated => _token != null;
  User? get currentUser => _currentUser;

  AuthService(this._supabase) {

    _loadStoredAuth();
  }

  Future<void> _loadStoredAuth() async {
     prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    final userData = prefs.getString(_userKey);
    if (userData != null) {
      _currentUser = User.fromJson(json.decode(userData));
    }
    notifyListeners();
  }

  Future<void> _saveAuthData(String token, User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, json.encode(user.toJson()));
    _token = token;
    _currentUser = user;
    notifyListeners();
  }

  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    _token = null;
    _currentUser = null;
    notifyListeners();
  }

  // Encrypt password using user's public key
 String encryptPassword(String password) {


  try {
    
    // Create encryption key (must be 32 bytes for AES-256)
    final key = encrypt.Key.fromSecureRandom( 32);
    
    // Create initialization vector
  
    print(key.length.toString());
    print(key.base64);

    prefs.setString("key", key.base64);

    // Create encrypter instance
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.ecb));
    
    // Encrypt the password
    final encryptedPassword = encrypter.encrypt(password);
    
    // Combine IV and encrypted data in the result
    return encryptedPassword.base64;
    
  } catch (e) {
    throw Exception('Encryption failed: ${e.toString()}');
  }
}


  // Decrypt password using user's private key
  bool verifyPassword(String encryptedPassword, String password, String privateAddress) {
    try {
      
      final key = encrypt.Key.fromBase64(privateAddress);
      print("the key is ${key.base64})} , and the privatekey is ${privateAddress}");
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.ecb));
      print("encrypting...");
      final decryptedPassword = encrypter.decrypt64(encryptedPassword);
      print("decryptedPassword ${decryptedPassword}");
      return decryptedPassword == password;
    } catch (e) {
      return false;
    }
  }

  Future<void> login({
    required String email, 
    required String password, 
    required String mnemonic
  }) async {
    try {
      // Fetch user by email
      final response = await _supabase
        .from('users')
        .select()
        .eq('username', email.toLowerCase())
        .single();
      print("response ${response.toString()}");

      if (response.isEmpty) {
        throw AuthException('User not found');
      }

      // Verify encrypted password
      final storedEncryptedPassword = response['password'];
      final privateAddress = await MnemonicService(baseUrl: baseUrl). mnemonicToKey(mnemonic);
      print("privateAddress ${privateAddress["key"].toString()}");
      if (!verifyPassword(storedEncryptedPassword, password, privateAddress["key"])) {
        throw AuthException('Invalid credentials');
      }
     

      // Create user object
      final user = User(
        id: response['id'].toString(),
        username: response['username'],
        author_name: response['author_name'],
        profile: response['profile'],

      );

      await _saveAuthData('mock_token', user);
    } catch (error) {
      throw AuthException('Login failed: ${error.toString()}');
    }
  }

  


Future<String> signup({
  required String username,
  required String password,
  required String author_name,
  required Uint8List profileImage,
  required String filePath,
}) async {
  try {
    final supabaseClient = SupabaseClient('https://tfxbcnluzthdrwhtrntb.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRmeGJjbmx1enRoZHJ3aHRybnRiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzA0NjI2NjksImV4cCI6MjA0NjAzODY2OX0.at0R_6S9vUk666sS1xJA_2jIoRLez_YN2PBLo_822vM');

    // Encrypt password with user's public address
    final encryptedPassword = encryptPassword(password);

    print("uploading profile image...");

    // Create a unique file name using timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = path.extension(filePath);
    final fileName = 'profile_$timestamp$extension';

    // Upload image to Supabase Storage
    final storageResponse = await supabaseClient
        .storage
        .from('user_profile') // Your bucket name
        .uploadBinary(
          fileName,
          profileImage,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

    if (storageResponse.isEmpty) {
      throw Exception('Failed to upload image: ${storageResponse.toString()}');
    }

    // Get the public URL of the uploaded image
    final imageUrl = await supabaseClient
        .storage
        .from('user_profile')
        .createSignedUrl(fileName , 10000000000);

    print("Profile image uploaded successfully: $imageUrl");

    // Insert user into Supabase
    final response = await supabaseClient
        .from('users')
        .insert({
          'username': username.toLowerCase(),
          'password': encryptedPassword,
          'author_name': author_name,
          'profile': imageUrl,
        })
        .select()
        .single();


    // Create user object
    final user = User(
      id: response['id'].toString(),
      username: username,
      author_name: author_name,
      profile: imageUrl,

    );

    await _saveAuthData('mock_token', user);
    return imageUrl;
    
  } catch (error) {
    print("Error during signup: $error");
    throw AuthException('Signup failed: ${error.toString()}');
  }
}
  Future<void> logout() async {
    await _clearAuthData();
  
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class User {
  final String id;
  final String username;
  final String author_name;
  final String profile;



  User({
    required this.id,
    required this.username,
    required this.author_name,
    required this.profile,


  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      author_name: json['author_name'],
      profile: json['profile'],
     

    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'author_name': author_name,
      'profile': profile,


    };
  }
}