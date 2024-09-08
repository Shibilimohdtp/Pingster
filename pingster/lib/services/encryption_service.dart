import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<String> encrypt(String plainText, String chatId) async {
    final key = await _getOrCreateKey(chatId);
    final iv = IV.fromLength(16);
    final encrypter = Encrypter(AES(key));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return '${encrypted.base64}|${iv.base64}';
  }

  Future<String> decrypt(String encryptedText, String chatId) async {
    try {
      final key = await _getOrCreateKey(chatId);
      final parts = encryptedText.split('|');
      if (parts.length != 2)
        throw const FormatException('Invalid encrypted text format');

      final encrypted = Encrypted.fromBase64(parts[0]);
      final iv = IV.fromBase64(parts[1]);
      final encrypter = Encrypter(AES(key));
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      print('Error decrypting message: $e');
      return 'Error decrypting message';
    }
  }

  Future<Key> _getOrCreateKey(String chatId) async {
    final keyString = await _secureStorage.read(key: 'chat_key_$chatId');
    if (keyString != null) {
      return Key.fromBase64(keyString);
    } else {
      final key = Key.fromSecureRandom(32);
      await _secureStorage.write(key: 'chat_key_$chatId', value: key.base64);
      return key;
    }
  }
}
