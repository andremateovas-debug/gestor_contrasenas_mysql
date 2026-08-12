import 'package:flutter/services.dart';

/// Estados posibles de un intento de autenticación biométrica.
///
/// El MethodChannel nativo distingue estos casos (ver MainActivity.kt) para
/// que la UI pueda mostrar un mensaje adecuado en vez de tratar todo fallo
/// como un simple "false".
enum EstadoBiometria {
  exito,
  cancelado,
  noEnrolado,
  noDisponible,
  bloqueado,
  noConfigurado,
  error,
}

class ResultadoBiometrico {
  final EstadoBiometria estado;
  final String? claveMaestra;

  const ResultadoBiometrico._(this.estado, this.claveMaestra);

  const ResultadoBiometrico.exito(String clave)
    : this._(EstadoBiometria.exito, clave);

  const ResultadoBiometrico.fallo(EstadoBiometria estado)
    : this._(estado, null);

  bool get esExito => estado == EstadoBiometria.exito;
}

class BiometriaService {
  BiometriaService._();

  static const MethodChannel _canal = MethodChannel(
    'gestor_contrasenas/biometric_keystore',
  );

  static EstadoBiometria _mapearCodigoError(String codigo) {
    switch (codigo) {
      case 'BIOMETRIA_CANCELADA':
        return EstadoBiometria.cancelado;
      case 'BIOMETRIA_NO_ENROLADA':
        return EstadoBiometria.noEnrolado;
      case 'BIOMETRIA_NO_DISPONIBLE':
        return EstadoBiometria.noDisponible;
      case 'BIOMETRIA_BLOQUEADA':
        return EstadoBiometria.bloqueado;
      default:
        return EstadoBiometria.error;
    }
  }

  static Future<String?> envolverClaveMaestra(String claveMaestra) async {
    try {
      return await _canal.invokeMethod<String>('envolverClaveMaestra', {
        'clave': claveMaestra,
      });
    } on PlatformException {
      return null;
    }
  }

  static Future<ResultadoBiometrico> desenvolverClaveMaestra(
    String blob,
  ) async {
    try {
      final clave = await _canal.invokeMethod<String>(
        'desenvolverClaveMaestra',
        {'blob': blob},
      );
      if (clave == null || clave.isEmpty) {
        return const ResultadoBiometrico.fallo(EstadoBiometria.error);
      }
      return ResultadoBiometrico.exito(clave);
    } on PlatformException catch (error) {
      return ResultadoBiometrico.fallo(
        _mapearCodigoError(error.code),
      );
    }
  }
}
