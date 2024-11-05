import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_app/services/mnemonic.dart';
import 'package:web3dart/web3dart.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

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
 
      );

      await _saveAuthData('mock_token', user);
    } catch (error) {
      throw AuthException('Login failed: ${error.toString()}');
    }
  }

  Future<void> signup({
    required String username,
    required String password,
    required String author_name
  }) async {
    try {
      // Encrypt password with user's public address
      final encryptedPassword = encryptPassword(password);

      // Insert user into Supabase
      final response = await _supabase
        .from('users')
        .insert({
          'username': username.toLowerCase(),
       'password': encryptedPassword,
       'author_name' : author_name,
        })
        .select()
        .single();

      // Create user object
      final user = User(
        id: response['id'].toString(),
        username: username,
      );

      await _saveAuthData('mock_token', user);
    } catch (error) {
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


  User({
    required this.id,
    required this.username,

  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],

    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,

    };
  }
}