import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/key_derivators/api.dart';
import 'package:pointycastle/key_derivators/pbkdf2.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:uuid/uuid.dart';

import 'encriptacion_service.dart';
import 'biometria_service.dart';

class IdentidadService {
  static const String _claveRegistroCompleto = 'registroCompleto';
  static const String _clavePalabrasSecretas = 'palabrasSecretas';
  static const String _claveDeviceSecret = 'deviceSecret';
  static const String _claveMaestraBiometrica = 'claveMaestraBiometrica';

  final FlutterSecureStorage _almacenamientoSeguro =
      const FlutterSecureStorage();

  Future<Directory> _obtenerDirectorioVault() async {
    final directorioDocumentos = await getApplicationDocumentsDirectory();
    final directorioVault = Directory(
      '${directorioDocumentos.path}/AM_MA_Vault',
    );

    if (!await directorioVault.exists()) {
      await directorioVault.create(recursive: true);
    }

    return directorioVault;
  }

  Future<File> _obtenerArchivoUsuario() async {
    final directorioVault = await _obtenerDirectorioVault();
    return File('${directorioVault.path}/usuario.json');
  }

  encrypt.Key _derivarClave(String pin, Uint8List salt) {
    final derivador = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, 100000, 32));
    final clave = Uint8List(32);
    derivador.deriveKey(Uint8List.fromList(utf8.encode(pin)), 0, clave, 0);
    return encrypt.Key(clave);
  }

  encrypt.Key _derivarClaveAntigua(String pin) {
    final hash = sha256.convert(utf8.encode(pin));
    return encrypt.Key.fromBase64(base64Encode(hash.bytes));
  }

  String _cifrarClaveMaestra(String claveMaestra, encrypt.Key clave) {
    final nonce = encrypt.IV.fromSecureRandom(12);
    final encriptador = encrypt.Encrypter(
      encrypt.AES(clave, mode: encrypt.AESMode.gcm),
    );
    final cifrado = encriptador.encrypt(claveMaestra, iv: nonce).base64;
    return '${nonce.base64}:$cifrado';
  }

  String _descifrarClaveMaestra(String textoCifrado, encrypt.Key clave) {
    final partes = textoCifrado.split(':');
    if (partes.length != 2) return '';

    final encriptador = encrypt.Encrypter(
      encrypt.AES(clave, mode: encrypt.AESMode.gcm),
    );
    return encriptador.decrypt64(
      partes[1],
      iv: encrypt.IV.fromBase64(partes[0]),
    );
  }

  String _descifrarClaveMaestraAntigua(
    String textoCifrado,
    String ivBase64,
    encrypt.Key clave,
  ) {
    final encriptador = encrypt.Encrypter(encrypt.AES(clave));
    return encriptador.decrypt64(
      textoCifrado,
      iv: encrypt.IV.fromBase64(ivBase64),
    );
  }

  Future<Map<String, dynamic>?> _leerUsuario() async {
    final archivoUsuario = await _obtenerArchivoUsuario();
    if (!await archivoUsuario.exists()) return null;

    final contenido = await archivoUsuario.readAsString();
    if (contenido.isEmpty) return null;

    return jsonDecode(contenido) as Map<String, dynamic>;
  }

  Future<bool> existeUsuario() async {
    try {
      final usuario = await _leerUsuario();
      return usuario != null && usuario['id'] != null;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, String>> registrarUsuario({
    required String nombre,
    required String pin,
  }) async {
    final claveMaestra = encrypt.Key.fromSecureRandom(32);
    final deviceSecret = encrypt.Key.fromSecureRandom(32).base64;
    final deviceSecretHash = sha256
        .convert(utf8.encode(deviceSecret))
        .toString();
    final saltPin = encrypt.IV.fromSecureRandom(16);
    final claveDerivada = _derivarClave(pin, saltPin.bytes);
    final claveMaestraCifrada = _cifrarClaveMaestra(
      claveMaestra.base64,
      claveDerivada,
    );
    final id = const Uuid().v4();
    final archivoUsuario = await _obtenerArchivoUsuario();

    await archivoUsuario.writeAsString(
      jsonEncode({
        'id': id,
        'nombre': nombre,
        'claveMaestraCifrada': claveMaestraCifrada,
        'saltPin': saltPin.base64,
      }),
    );
    await _almacenamientoSeguro.write(
      key: _claveDeviceSecret,
      value: deviceSecret,
    );

    EncriptacionService.configurarClaveMaestra(claveMaestra.base64);

    return {
      'id': id,
      'claveMaestraPlano': claveMaestra.base64,
      'deviceSecretHash': deviceSecretHash,
    };
  }

  Future<String?> obtenerDeviceSecret() {
    return _almacenamientoSeguro.read(key: _claveDeviceSecret);
  }

  Future<String?> obtenerDeviceSecretHash() async {
    final deviceSecret = await obtenerDeviceSecret();
    if (deviceSecret == null || deviceSecret.isEmpty) return null;
    return sha256.convert(utf8.encode(deviceSecret)).toString();
  }

  Future<bool> validarPin(String pin) async {
    try {
      final claveMaestraPlano = await _obtenerClaveMaestra(pin);
      EncriptacionService.configurarClaveMaestra(claveMaestraPlano);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> prepararClaveMaestraBiometrica() async {
    try {
      final blobExistente = await _almacenamientoSeguro.read(
        key: _claveMaestraBiometrica,
      );
      if (blobExistente != null && blobExistente.isNotEmpty) return;

      final claveMaestra = EncriptacionService.obtenerClaveMaestraBase64();
      if (claveMaestra == null) return;

      final blob = await BiometriaService.envolverClaveMaestra(claveMaestra);
      if (blob == null || blob.isEmpty) return;
      await _almacenamientoSeguro.write(
        key: _claveMaestraBiometrica,
        value: blob,
      );
    } catch (_) {
      // La biometría es opcional; el PIN sigue siendo el fallback.
    }
  }

  Future<String?> obtenerClaveMaestraBiometrica() async {
    final blob = await _almacenamientoSeguro.read(key: _claveMaestraBiometrica);
    if (blob == null || blob.isEmpty) return null;
    return BiometriaService.desenvolverClaveMaestra(blob);
  }

  Future<String> _obtenerClaveMaestra(String pin) async {
    final usuario = await _leerUsuario();
    if (usuario == null) throw const FormatException('Usuario no encontrado');

    final claveMaestraCifrada = usuario['claveMaestraCifrada'] as String;
    final tieneFormatoNuevo = claveMaestraCifrada.contains(':');
    final saltCodificado = usuario['saltPin'] as String?;

    if (tieneFormatoNuevo && saltCodificado == null) {
      throw const FormatException('Salt del PIN ausente');
    }

    final claveDerivada = tieneFormatoNuevo
        ? _derivarClave(pin, encrypt.IV.fromBase64(saltCodificado!).bytes)
        : _derivarClaveAntigua(pin);
    final claveMaestraPlano = tieneFormatoNuevo
        ? _descifrarClaveMaestra(claveMaestraCifrada, claveDerivada)
        : _descifrarClaveMaestraAntigua(
            claveMaestraCifrada,
            usuario['ivUsuario'] as String,
            claveDerivada,
          );

    if (!tieneFormatoNuevo) {
      final nuevoSalt = encrypt.IV.fromSecureRandom(16);
      final nuevaClave = _derivarClave(pin, nuevoSalt.bytes);
      usuario
        ..remove('ivUsuario')
        ..['saltPin'] = nuevoSalt.base64
        ..['claveMaestraCifrada'] = _cifrarClaveMaestra(
          claveMaestraPlano,
          nuevaClave,
        );
      await (await _obtenerArchivoUsuario()).writeAsString(jsonEncode(usuario));
    }

    return claveMaestraPlano;
  }

  Future<bool> cambiarPin({
    required String pinActual,
    required String nuevoPin,
  }) async {
    try {
      final claveMaestraPlano = await _obtenerClaveMaestra(pinActual);
      final nuevoSalt = encrypt.IV.fromSecureRandom(16);
      final nuevaClave = _derivarClave(nuevoPin, nuevoSalt.bytes);
      final usuario = await _leerUsuario();
      if (usuario == null) return false;

      usuario
        ..remove('ivUsuario')
        ..['saltPin'] = nuevoSalt.base64
        ..['claveMaestraCifrada'] = _cifrarClaveMaestra(
          claveMaestraPlano,
          nuevaClave,
        );
      await (await _obtenerArchivoUsuario()).writeAsString(jsonEncode(usuario));
      EncriptacionService.configurarClaveMaestra(claveMaestraPlano);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<String>> guardarPalabrasSecretas(List<String> palabras) async {
    final hashes = palabras.map((palabra) {
      final salt = encrypt.IV.fromSecureRandom(16);
      final hash = sha256.convert([
        ...salt.bytes,
        ...utf8.encode(palabra.trim().toLowerCase()),
      ]);
      return {'hash': hash.toString(), 'salt': salt.base64};
    }).toList();

    await _almacenamientoSeguro.write(
      key: _clavePalabrasSecretas,
      value: jsonEncode(hashes),
    );
    await _almacenamientoSeguro.write(
      key: _claveRegistroCompleto,
      value: 'true',
    );

    // TODO: enviar id, nombre y hashes de palabras secretas a la API
    return hashes.map((item) => '${item['hash']}:${item['salt']}').toList();
  }

  Future<void> borrarTodo() async {
    final directorioVault = await _obtenerDirectorioVault();
    final archivoUsuario = File('${directorioVault.path}/usuario.json');
    final archivoContrasenas = File('${directorioVault.path}/contras.json');

    if (await archivoUsuario.exists()) await archivoUsuario.delete();
    if (await archivoContrasenas.exists()) await archivoContrasenas.delete();

    await _almacenamientoSeguro.delete(key: _claveRegistroCompleto);
    await _almacenamientoSeguro.delete(key: _clavePalabrasSecretas);
    await _almacenamientoSeguro.delete(key: _claveDeviceSecret);
    await _almacenamientoSeguro.delete(key: _claveMaestraBiometrica);
    EncriptacionService.limpiarClaveMaestra();
  }

  Future<String?> obtenerId() async {
    try {
      final usuario = await _leerUsuario();
      return usuario?['id'] as String?;
    } catch (_) {
      return null;
    }
  }
}
