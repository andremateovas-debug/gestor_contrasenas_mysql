import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:convert';

class EncriptacionService {
  static final key = encrypt.Key.fromUtf8(
    'my32lengthsupersecretnooneknows1',
  );

  static final iv = encrypt.IV.fromBase64(
    'AAAAAAAAAAAAAAAAAAAAAA==',
  );

  static final encrypter = encrypt.Encrypter(
    encrypt.AES(key),
  );

  /// Encriptar un string
  static String encriptar(String texto) {
    return encrypter.encrypt(texto, iv: iv).base64;
  }

  /// Desencriptar un string
  static String desencriptar(String textoCifrado) {
    return encrypter.decrypt64(textoCifrado, iv: iv);
  }

  /// Prueba de cifrado
  static void prueba() {
    const texto = 'Hola123';

    final cifrado = encriptar(texto);
    print('PRUEBA CIFRADO: $cifrado');

    final descifrado = desencriptar(cifrado);
    print('PRUEBA DESCIFRADO: $descifrado');
  }

  static void mostrarDatosCifrado() {
    print("KEY: ${key.base64}");
    print("IV: ${iv.base64}");
  }

  /// Encriptar una lista de contraseñas (JSON)
  static String encriptarJson(List contras) {
    final json = jsonEncode(contras);
    return encriptar(json);
  }

  /// Desencriptar una lista de contraseñas
  static List desencriptarJson(String jsonCifrado) {
    final json = desencriptar(jsonCifrado);
    return jsonDecode(json) as List;
  }
}