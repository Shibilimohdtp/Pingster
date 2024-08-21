import 'package:encrypt/encrypt.dart';

class EncryptionService {
  static final key = Key.fromLength(32);
  static final iv = IV.fromLength(16);
  static final encrypter = Encrypter(AES(key));

  Future<String> encrypt(String plainText) async {
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return encrypted.base64;
  }

  Future<String> decrypt(String encryptedText) async {
    final encrypted = Encrypted.fromBase64(encryptedText);
    return encrypter.decrypt(encrypted, iv: iv);
  }
}
