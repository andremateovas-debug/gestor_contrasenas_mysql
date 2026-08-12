import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'encriptacion_service.dart';

class JsonService {
  /// Serializa las operaciones de lectura-modificación-escritura sobre
  /// contras.json para evitar que dos operaciones concurrentes (agregar,
  /// eliminar, actualizar) lean el mismo estado y se sobrescriban entre sí.
  static Future<void> _colaOperaciones = Future.value();

  Future<T> _encolar<T>(Future<T> Function() accion) {
    final resultado = _colaOperaciones.then((_) => accion());
    _colaOperaciones = resultado.then((_) {}, onError: (_) {});
    return resultado;
  }

  Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();

    final vaultDir = Directory('${directory.path}/AM_MA_Vault');

    if (!await vaultDir.exists()) {
      await vaultDir.create(recursive: true);
    }

    return File('${vaultDir.path}/contras.json');
  }

  Future<void> guardarContrasenas(List contrasenas) async {
    final file = await _localFile;

    final jsonEncriptado = EncriptacionService.encriptarJson(contrasenas);

    await file.writeAsString(jsonEncriptado);
  }

  Future<List> leerContrasenas() async {
    try {
      final file = await _localFile;

      if (!await file.exists()) {
        return [];
      }

      var contenidoEncriptado = await file.readAsString();

      if (contenidoEncriptado.isEmpty) {
        return [];
      }

      if (!contenidoEncriptado.contains(':')) {
        contenidoEncriptado = EncriptacionService.migrarFormatoAntiguo(
          contenidoEncriptado,
        );
        await file.writeAsString(contenidoEncriptado);
      }

      final contrasenas = EncriptacionService.desencriptarJson(
        contenidoEncriptado,
      );

      return contrasenas;
    } on CifradoCorruptoException {
      rethrow;
    } catch (_) {
      return [];
    }
  }

  /// Agregar una nueva contraseña
  Future<bool> agregarContrasena({
    required String titulo,
    required String usuario,
    required String contrasena,
    required String sitioWeb,
  }) {
    return _encolar(() async {
      try {
        final contrasenas = await leerContrasenas();

        final nueva = {
          "titulo": titulo,
          "usuario": usuario,
          "contrasena": contrasena,
          "sitio_web": sitioWeb,
          "fecha_creacion": DateTime.now().toIso8601String(),
        };

        contrasenas.add(nueva);

        await guardarContrasenas(contrasenas);

        return true;
      } catch (_) {
        return false;
      }
    });
  }

  /// Eliminar una contraseña
  Future<bool> eliminarContrasena({
    required String titulo,
    required String usuario,
  }) {
    return _encolar(() async {
      try {
        final contrasenas = await leerContrasenas();

        contrasenas.removeWhere(
          (item) => item["titulo"] == titulo && item["usuario"] == usuario,
        );

        await guardarContrasenas(contrasenas);

        return true;
      } catch (_) {
        return false;
      }
    });
  }

  /// Actualizar una contraseña
  Future<bool> actualizarContrasena({
    required String tituloViejo,
    required String usuarioViejo,
    required String tituloNuevo,
    required String usuarioNuevo,
    required String contrasena,
    required String sitioWeb,
  }) {
    return _encolar(() async {
      try {
        final contrasenas = await leerContrasenas();

        final index = contrasenas.indexWhere(
          (item) =>
              item["titulo"] == tituloViejo &&
              item["usuario"] == usuarioViejo,
        );

        if (index != -1) {
          contrasenas[index] = {
            "titulo": tituloNuevo,
            "usuario": usuarioNuevo,
            "contrasena": contrasena,
            "sitio_web": sitioWeb,
            "fecha_creacion":
                contrasenas[index]["fecha_creacion"] ??
                DateTime.now().toIso8601String(),
            "fecha_actualizacion": DateTime.now().toIso8601String(),
          };

          await guardarContrasenas(contrasenas);

          return true;
        }

        return false;
      } catch (_) {
        return false;
      }
    });
  }
}
