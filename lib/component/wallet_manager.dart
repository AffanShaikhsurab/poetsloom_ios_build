import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class WalletManager {
  static const _secureStorage = FlutterSecureStorage();
  
  // Check if private key exists
  static Future<bool> hasPrivateKey() async {
    final key = await _secureStorage.read(key: 'private_key');
    return key != null;
  }

  // Get private key securely
  static Future<String?> getPrivateKey() async {
    return await _secureStorage.read(key: 'private_key');
  }

  // Save private key securely
  static Future<void> savePrivateKey(String privateKey) async {
    await _secureStorage.write(key: 'private_key', value: privateKey);
  }

  // Remove private key
  static Future<void> removePrivateKey() async {
    await _secureStorage.delete(key: 'private_key');
  }
}