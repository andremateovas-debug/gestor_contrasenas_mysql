import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'sesion_service.dart';

class LimiteAlcanzadoException implements Exception {
  final String mensaje;

  const LimiteAlcanzadoException([
    this.mensaje = 'Se alcanzó el límite de contraseñas permitido.',
  ]);

  @override
  String toString() => mensaje;
}

class SesionNoIniciadaException implements Exception {
  final String mensaje;

  const SesionNoIniciadaException([
    this.mensaje = 'No hay una sesión iniciada.',
  ]);

  @override
  String toString() => mensaje;
}

class ErrorServidorException implements Exception {
  final String mensaje;

  const ErrorServidorException([
    this.mensaje = 'La API devolvió un error no esperado.',
  ]);

  @override
  String toString() => mensaje;
}

class MysqlService {
  static final MysqlService _instancia = MysqlService._interno();

  factory MysqlService() => _instancia;

  MysqlService._interno();

  String? _token;
  String? _usuarioId;
  String? _deviceSecretHash;

  String get _apiUrl {
    final url = dotenv.env['API_URL']?.trim();
    if (url == null || url.isEmpty) {
      throw Exception(
        'API_URL no está configurada. Verifica que el archivo .env se haya cargado.',
      );
    }
    return url;
  }

  Future<Map<String, dynamic>> _post(
    Map<String, dynamic> body, {
    bool reintentarSesion = true,
  }) async {
    final action = body['action'];
    final requiereSesion = action != 'registrar' && action != 'iniciar_sesion';
    if (requiereSesion && _token == null) {
      throw const SesionNoIniciadaException();
    }

    try {
      final datos = Map<String, dynamic>.from(body);
      if (requiereSesion) datos['token'] = _token;

      final response = await _enviar(datos);

      if (response.statusCode != 200) {
        if (response.statusCode == 401) {
          throw const _SesionExpiradaException();
        }
        throw const ErrorServidorException();
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || !decoded.containsKey('success')) {
        throw const ErrorServidorException();
      }

      if (decoded['error'] == 'Sesión inválida o expirada') {
        throw const _SesionExpiradaException();
      }

      return decoded;
    } on _SesionExpiradaException {
      if (!reintentarSesion ||
          action == 'iniciar_sesion' ||
          action == 'registrar' ||
          _usuarioId == null ||
          _deviceSecretHash == null) {
        if (action != 'iniciar_sesion' && action != 'registrar') {
          SesionService.invalidarPorSesionRemotaExpirada();
        }
        throw const ErrorServidorException('Sesión inválida o expirada.');
      }
      _token = null;
      bool sesionRestaurada;
      try {
        sesionRestaurada = await iniciarSesion(
          id: _usuarioId!,
          deviceSecretHash: _deviceSecretHash!,
        );
      } on SocketException {
        rethrow;
      } on TimeoutException {
        rethrow;
      } on ErrorServidorException {
        SesionService.invalidarPorSesionRemotaExpirada();
        rethrow;
      }
      if (!sesionRestaurada) {
        SesionService.invalidarPorSesionRemotaExpirada();
        throw const ErrorServidorException('No se pudo renovar la sesión.');
      }
      return _post(body, reintentarSesion: false);
    } on SocketException {
      rethrow;
    } on TimeoutException {
      rethrow;
    } on FormatException {
      throw const ErrorServidorException();
    }
  }

  Future<http.Response> _enviar(Map<String, dynamic> body) {
    return http
        .post(
          Uri.parse(_apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));
  }

  Future<bool> registrarUsuario({
    required String id,
    required String nombre,
    required List<String> palabrasHasheadas,
    required String deviceSecretHash,
  }) async {
    if (palabrasHasheadas.length != 5) {
      throw ArgumentError('Se requieren exactamente 5 palabras hasheadas.');
    }

    final respuesta = await _post({
      'action': 'registrar',
      'id': id,
      'nombre': nombre,
      'device_secret_hash': deviceSecretHash,
      'palabra1': palabrasHasheadas[0],
      'palabra2': palabrasHasheadas[1],
      'palabra3': palabrasHasheadas[2],
      'palabra4': palabrasHasheadas[3],
      'palabra5': palabrasHasheadas[4],
    });
    return respuesta['success'] == true;
  }

  Future<bool> iniciarSesion({
    required String id,
    required String deviceSecretHash,
  }) async {
    final respuesta = await _post({
      'action': 'iniciar_sesion',
      'id': id,
      'device_secret_hash': deviceSecretHash,
    });
    final token = respuesta['token'];
    if (respuesta['success'] == true && token is String && token.isNotEmpty) {
      _token = token;
      _usuarioId = id;
      _deviceSecretHash = deviceSecretHash;
      return true;
    }
    return false;
  }

  Future<bool> subirContrasena({
    required String propietario,
    required String datosCifrados,
  }) async {
    final respuesta = await _post({
      'action': 'subir_contrasena',
      'datos_cifrados': datosCifrados,
    });
    if (respuesta['success'] == true) return true;

    final error =
        respuesta['error']?.toString() ?? 'No se pudo subir la contraseña.';
    if (error.toLowerCase().contains('límite') ||
        error.toLowerCase().contains('limite')) {
      throw LimiteAlcanzadoException(error);
    }
    return false;
  }

  Future<List<Map<String, dynamic>>> sincronizar({
    required String propietario,
  }) async {
    final respuesta = await _post({'action': 'sincronizar'});
    if (respuesta['success'] != true) {
      throw Exception(
        respuesta['error']?.toString() ?? 'No se pudo sincronizar la bóveda.',
      );
    }

    final data = respuesta['data'];
    if (data is! List) {
      throw const FormatException('La API no devolvió una lista de datos.');
    }

    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<bool> eliminarContrasena({
    required String propietario,
    required int id,
  }) async {
    final respuesta = await _post({'action': 'eliminar_contrasena', 'id': id});
    return respuesta['success'] == true;
  }

  Future<bool> actualizarContrasena({
    required String propietario,
    required int id,
    required String nuevoDatosCifrados,
  }) async {
    final respuesta = await _post({
      'action': 'actualizar_contrasena',
      'id': id,
      'nuevo_datos_cifrados': nuevoDatosCifrados,
    });
    return respuesta['success'] == true;
  }

  Future<bool> borrarCuenta({required String propietario}) async {
    final respuesta = await _post({'action': 'borrar_cuenta'});
    return respuesta['success'] == true;
  }

  Future<void> cerrarSesion() async {
    if (_token == null) return;
    try {
      await _post({'action': 'cerrar_sesion'});
    } finally {
      _token = null;
      _usuarioId = null;
      _deviceSecretHash = null;
    }
  }

  Future<bool> ping() async {
    try {
      final respuesta = await _post({'action': 'ping'});
      return respuesta['success'] == true;
    } on Exception {
      return false;
    }
  }
}

class _SesionExpiradaException implements Exception {
  const _SesionExpiradaException();
}
