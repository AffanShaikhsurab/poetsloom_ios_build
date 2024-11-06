import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web3dart/web3dart.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class AuthService with ChangeNotifier {
  final SupabaseClient _supabase;
  
  static const String _tokenKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRmeGJjbmx1enRoZHJ3aHRybnRiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzA0NjI2NjksImV4cCI6MjA0NjAzODY2OX0.at0R_6S9vUk666sS1xJA_2jIoRLez_YN2PBLo_822vM';
  static const String _userKey = 'user_data';
  
  String? _token;
  User? _currentUser;
  
  bool get isAuthenticated => _token != null;
  User? get currentUser => _currentUser;

  AuthService(this._supabase) {
    _loadStoredAuth();
  }

  Future<void> _loadStoredAuth() async {
    final prefs = await SharedPreferences.getInstance();
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
  String encryptPassword(String password, String publicAddress) {
    final privateKey = EthPrivateKey.fromHex(publicAddress);
    final publicKey = privateKey.address;
    
    final key = encrypt.Key.fromLength(32);
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    
    final encryptedPassword = encrypter.encrypt(password, iv: iv);
    return encryptedPassword.base64;
  }

  // Decrypt password using user's private key
  bool verifyPassword(String encryptedPassword, String password, String publicAddress) {
    try {
      final privateKey = EthPrivateKey.fromHex(publicAddress);
      
      final key = encrypt.Key.fromLength(32);
      final iv = encrypt.IV.fromLength(16);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      
      final decryptedPassword = encrypter.decrypt64(encryptedPassword, iv: iv);
      return decryptedPassword == password;
    } catch (e) {
      return false;
    }
  }

  Future<void> login({
    required String email, 
    required String password, 
    required String publicAddress
  }) async {
    try {
      // Fetch user by email
      final response = await _supabase
        .from('users')
        .select()
        .eq('email', email)
        .single();

      if (response == null) {
        throw AuthException('User not found');
      }

      // Verify encrypted password
      final storedEncryptedPassword = response['password'];
      if (!verifyPassword(storedEncryptedPassword, password, publicAddress)) {
        throw AuthException('Invalid credentials');
      }

      // Create user object
      final user = User(
        id: response['id'].toString(),
        username: response['username'],
        email: email,
        publicAddress: publicAddress
      );

      await _saveAuthData('mock_token', user);
    } catch (error) {
      throw AuthException('Login failed: ${error.toString()}');
    }
  }

  Future<void> signup({
    required String username,
    required String email, 
    required String password,
    required String publicAddress
  }) async {
    try {
      // Encrypt password with user's public address
      final encryptedPassword = encryptPassword(password, publicAddress);

      // Insert user into Supabase
      final response = await _supabase
        .from('users')
        .insert({
          'username': username,
          'email': email,
          'password': encryptedPassword,
          'public_address': publicAddress
        })
        .select()
        .single();

      // Create user object
      final user = User(
        id: response['id'].toString(),
        username: username,
        email: email,
        publicAddress: publicAddress
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
  final String email;
  final String? publicAddress;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.publicAddress
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      publicAddress: json['public_address']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'public_address': publicAddress
    };
  }
}