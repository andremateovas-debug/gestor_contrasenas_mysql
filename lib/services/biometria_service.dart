import 'package:flutter/services.dart';

class BiometriaService {
  BiometriaService._();

  static const MethodChannel _canal = MethodChannel(
    'gestor_contrasenas/biometric_keystore',
  );

  static Future<String?> envolverClaveMaestra(String claveMaestra) {
    return _canal.invokeMethod<String>('envolverClaveMaestra', {
      'clave': claveMaestra,
    });
  }

  static Future<String?> desenvolverClaveMaestra(String blob) {
    return _canal.invokeMethod<String>('desenvolverClaveMaestra', {
      'blob': blob,
    });
  }
}
