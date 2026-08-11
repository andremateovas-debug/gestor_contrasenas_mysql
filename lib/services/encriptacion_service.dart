import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:convert';

class CifradoCorruptoException implements Exception {
  const CifradoCorruptoException();

  @override
  String toString() => 'La bóveda está corrupta o fue manipulada';
}

class EncriptacionService {
  static encrypt.Key? _key;

  static bool get tieneClaveMaestra => _key != null;

  static final _ivAntiguo = encrypt.IV.fromBase64('AAAAAAAAAAAAAAAAAAAAAA==');

  static encrypt.Encrypter get encrypter {
    final key = _key;
    if (key == null) {
      throw Exception(
        'No hay clave maestra disponible, el usuario debe autenticarse primero',
      );
    }
    return encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
  }

  static void configurarClaveMaestra(String claveMaestraBase64) {
    _key = encrypt.Key.fromBase64(claveMaestraBase64);
  }

  static String? obtenerClaveMaestraBase64() => _key?.base64;

  static void limpiarClaveMaestra() {
    _key = null;
  }

  /// Encriptar un string
  static String encriptar(String texto) {
    final nonce = encrypt.IV.fromSecureRandom(12);
    final cifrado = encrypter.encrypt(texto, iv: nonce).base64;
    return '${nonce.base64}:$cifrado';
  }

  /// Desencriptar un string
  static String desencriptar(String textoCifrado) {
    final partes = textoCifrado.split(':');
    if (partes.length != 2 || partes[0].isEmpty || partes[1].isEmpty) {
      throw const CifradoCorruptoException();
    }

    try {
      return encrypter.decrypt64(
        partes[1],
        iv: encrypt.IV.fromBase64(partes[0]),
      );
    } catch (_) {
      throw const CifradoCorruptoException();
    }
  }

  /// Re-cifra una bóveda creada con el formato anterior (SIC + IV fijo).
  static String migrarFormatoAntiguo(String textoCifrado) {
    final key = _key;
    if (key == null) {
      throw Exception(
        'No hay clave maestra disponible, el usuario debe autenticarse primero',
      );
    }

    try {
      final encriptadorAntiguo = encrypt.Encrypter(encrypt.AES(key));
      final texto = encriptadorAntiguo.decrypt64(textoCifrado, iv: _ivAntiguo);
      return encriptar(texto);
    } catch (_) {
      throw const CifradoCorruptoException();
    }
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
