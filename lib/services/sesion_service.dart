import 'encriptacion_service.dart';

class SesionService {
  SesionService._();

  static bool autenticada = false;
  static bool sesionExpiradaPorServidor = false;

  static void marcarAutenticada() {
    autenticada = EncriptacionService.tieneClaveMaestra;
    sesionExpiradaPorServidor = false;
  }

  static void cerrar() {
    autenticada = false;
    sesionExpiradaPorServidor = false;
  }

  static void invalidarPorSesionRemotaExpirada() {
    autenticada = false;
    sesionExpiradaPorServidor = true;
    EncriptacionService.limpiarClaveMaestra();
  }

  static bool consumirAvisoSesionExpirada() {
    final aviso = sesionExpiradaPorServidor;
    sesionExpiradaPorServidor = false;
    return aviso;
  }
}
