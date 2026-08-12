import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'contacto.dart';
import 'registrar.dart';
import '../services/identidad_service.dart';
import '../services/mysql_service.dart';
import '../services/tema_service.dart';

class PantallaConfiguracion extends StatefulWidget {
  const PantallaConfiguracion({super.key});

  @override
  State<PantallaConfiguracion> createState() => _PantallaConfiguracionState();
}

class _PantallaConfiguracionState extends State<PantallaConfiguracion> {
  File? _fotoPerfil;
  final IdentidadService _identidadService = IdentidadService();
  bool _operacionEnCurso = false;

  Future<void> _seleccionarFotoPerfil() async {
    final imagen = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (imagen != null && mounted) {
      setState(() {
        _fotoPerfil = File(imagen.path);
      });
    }
  }

  void _mostrarToast(String mensaje, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje), backgroundColor: color));
  }

  void _mostrarSelectorTema() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.dark_mode_outlined),
                title: const Text("Modo oscuro"),
                trailing: temaApp.esOscuro ? const Icon(Icons.check) : null,
                onTap: () {
                  temaApp.cambiarModo(true);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.light_mode_outlined),
                title: const Text("Modo normal"),
                trailing: !temaApp.esOscuro ? const Icon(Icons.check) : null,
                onTap: () {
                  temaApp.cambiarModo(false);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _mostrarCambiarPin() async {
    final resultado = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => const _DialogoCambiarPin(),
    );

    if (resultado == null || !mounted) return;
    setState(() => _operacionEnCurso = true);
    final cambiado = await _identidadService.cambiarPin(
      pinActual: resultado['pinActual']!,
      nuevoPin: resultado['nuevoPin']!,
    );
    if (!mounted) return;
    setState(() => _operacionEnCurso = false);
    _mostrarToast(
      cambiado ? 'PIN actualizado.' : 'El PIN actual no es válido.',
      cambiado ? Colors.green : Colors.redAccent,
    );
  }

  Future<bool> _reautenticarParaBorrar() async {
    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) =>
          _DialogoConfirmarPin(identidadService: _identidadService),
    );
    return resultado == true;
  }

  Future<bool> _confirmarBorradoLocalPorFalloRemoto() async {
    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'No se pudo confirmar el borrado en el servidor (sin conexión)',
        ),
        content: const Text(
          '¿Quieres borrar solo los datos locales? La cuenta y los datos remotos podrían permanecer en el servidor.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    return resultado == true;
  }

  Future<void> _mostrarBorrarDatos() async {
    if (!await _reautenticarParaBorrar() || !mounted) return;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Borrar todos los datos'),
        content: const Text(
          'Se eliminarán tus contraseñas, tu cuenta local y las palabras secretas. Tendrás que registrarte de nuevo. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Borrar datos'),
          ),
        ],
      ),
    );

    if (confirmado != true || !mounted) return;
    // Esperar al siguiente frame para que el diálogo de confirmación
    // termine de desmontarse antes de reconstruir esta pantalla
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    setState(() => _operacionEnCurso = true);

    bool borradoRemoto = false;
    bool continuarSoloLocal = false;
    try {
      final id = await _identidadService.obtenerId();
      if (id == null) {
        throw const ErrorServidorException('Sesión local no disponible.');
      }
      borradoRemoto = await MysqlService().borrarCuenta(propietario: id);
      if (!borradoRemoto) {
        throw const ErrorServidorException('El servidor rechazó el borrado.');
      }
    } on SocketException catch (error) {
      debugPrint('Borrado remoto fallido: ${error.runtimeType}');
      continuarSoloLocal = await _confirmarBorradoLocalPorFalloRemoto();
    } on TimeoutException catch (error) {
      debugPrint('Borrado remoto fallido: ${error.runtimeType}');
      continuarSoloLocal = await _confirmarBorradoLocalPorFalloRemoto();
    } on ErrorServidorException catch (error) {
      debugPrint('Borrado remoto fallido: ${error.runtimeType}');
      await _mostrarErrorBorradoRemoto(error.runtimeType.toString());
    } on Exception catch (error) {
      debugPrint('Borrado remoto fallido: ${error.runtimeType}');
      await _mostrarErrorBorradoRemoto(error.runtimeType.toString());
    }

    if (!borradoRemoto && !continuarSoloLocal) {
      if (mounted) setState(() => _operacionEnCurso = false);
      return;
    }

    try {
      await MysqlService().cerrarSesion();
    } catch (_) {}
    await _identidadService.borrarTodo();
    if (!mounted) return;
    // Navegar en el siguiente frame, cuando cualquier diálogo previo
    // ya terminó de desmontarse por completo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PantallaRegistro()),
        (_) => false,
      );
    });
  }

  Future<void> _mostrarErrorBorradoRemoto(String tipoError) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('No se pudo eliminar la cuenta'),
        content: Text(
          'No se pudo eliminar tu cuenta del servidor (error: $tipoError). Por seguridad, no se borrarán tus datos locales todavía. Intenta de nuevo más tarde o contacta soporte.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaConfiguracion({
    required IconData icono,
    required String texto,
    required VoidCallback onTap,
    bool esDestructiva = false,
  }) {
    final colorTexto = Theme.of(context).colorScheme.onSurface;
    final colorPrincipal = esDestructiva ? Colors.redAccent : colorTexto;
    final colorBorde = esDestructiva
        ? Colors.red.withOpacity(0.45)
        : colorTexto.withOpacity(0.1);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: esDestructiva
              ? Colors.red.withOpacity(0.05)
              : colorTexto.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorBorde),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: esDestructiva
                    ? Colors.red.withOpacity(0.12)
                    : colorTexto.withOpacity(0.1),
              ),
              child: Icon(icono, color: colorPrincipal, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                texto,
                style: TextStyle(
                  color: colorPrincipal,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (esDestructiva && _operacionEnCurso)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                Icons.arrow_forward_ios,
                color: esDestructiva
                    ? Colors.redAccent
                    : colorTexto.withOpacity(0.5),
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorTexto = Theme.of(context).colorScheme.onSurface;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        child: Column(
          children: [
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _seleccionarFotoPerfil,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: colorTexto.withOpacity(0.1),
                    backgroundImage: _fotoPerfil == null
                        ? null
                        : FileImage(_fotoPerfil!),
                    child: _fotoPerfil == null
                        ? Icon(Icons.person, color: colorTexto, size: 48)
                        : null,
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).scaffoldBackgroundColor,
                        border: Border.all(color: colorTexto.withOpacity(0.2)),
                      ),
                      child: Icon(
                        Icons.camera_alt_outlined,
                        color: colorTexto.withOpacity(0.7),
                        size: 17,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Column(
              children: [
                _tarjetaConfiguracion(
                  icono: Icons.pin_outlined,
                  texto: "Cambiar pin de acceso",
                  onTap: _operacionEnCurso ? () {} : _mostrarCambiarPin,
                ),
                _tarjetaConfiguracion(
                  icono: Icons.person_outline,
                  texto: "Cambiar nombre de usuario",
                  onTap: () => _mostrarToast("Próximamente", Colors.white70),
                ),
                _tarjetaConfiguracion(
                  icono: Icons.palette_outlined,
                  texto: "Cambiar estilo de la app",
                  onTap: _mostrarSelectorTema,
                ),
                _tarjetaConfiguracion(
                  icono: Icons.description_outlined,
                  texto: "Términos y condiciones",
                  onTap: () => _mostrarToast("Próximamente", Colors.white70),
                ),
                _tarjetaConfiguracion(
                  icono: Icons.privacy_tip_outlined,
                  texto: "Privacidad de usuario",
                  onTap: () => _mostrarToast("Próximamente", Colors.white70),
                ),
                _tarjetaConfiguracion(
                  icono: Icons.support_agent_outlined,
                  texto: "Soporte",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PantallaContacto(),
                      ),
                    );
                  },
                ),
                _tarjetaConfiguracion(
                  icono: Icons.delete_forever_outlined,
                  texto: "Borrar datos",
                  esDestructiva: true,
                  onTap: _operacionEnCurso ? () {} : _mostrarBorrarDatos,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Widget _campoPin(TextEditingController controller, String etiqueta) {
  return TextFormField(
    controller: controller,
    obscureText: true,
    keyboardType: TextInputType.number,
    maxLength: 6,
    decoration: InputDecoration(labelText: etiqueta, counterText: ''),
    validator: (valor) {
      if (valor == null || !RegExp(r'^\d{4,6}$').hasMatch(valor)) {
        return 'Usa entre 4 y 6 dígitos';
      }
      return null;
    },
  );
}

/// Diálogo para cambiar el PIN. Los controllers pertenecen a este [State],
/// por lo que Flutter los destruye solo cuando el diálogo realmente se
/// desmonta, evitando disponerlos mientras el AlertDialog aún está en su
/// transición de salida.
class _DialogoCambiarPin extends StatefulWidget {
  const _DialogoCambiarPin();

  @override
  State<_DialogoCambiarPin> createState() => _DialogoCambiarPinState();
}

class _DialogoCambiarPinState extends State<_DialogoCambiarPin> {
  late final TextEditingController _pinActualCtrl;
  late final TextEditingController _nuevoPinCtrl;
  late final TextEditingController _confirmarPinCtrl;
  final _formulario = GlobalKey<FormState>();
  String? _error;

  @override
  void initState() {
    super.initState();
    _pinActualCtrl = TextEditingController();
    _nuevoPinCtrl = TextEditingController();
    _confirmarPinCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _pinActualCtrl.dispose();
    _nuevoPinCtrl.dispose();
    _confirmarPinCtrl.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formulario.currentState!.validate() ||
        _nuevoPinCtrl.text != _confirmarPinCtrl.text) {
      setState(() => _error = 'Los PIN no coinciden.');
      return;
    }

    Navigator.pop(context, {
      'pinActual': _pinActualCtrl.text,
      'nuevoPin': _nuevoPinCtrl.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cambiar PIN'),
      content: Form(
        key: _formulario,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _campoPin(_pinActualCtrl, 'PIN actual'),
            const SizedBox(height: 12),
            _campoPin(_nuevoPinCtrl, 'Nuevo PIN'),
            const SizedBox(height: 12),
            _campoPin(_confirmarPinCtrl, 'Confirmar nuevo PIN'),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _guardar, child: const Text('Guardar')),
      ],
    );
  }
}

/// Diálogo de confirmación de PIN antes de borrar datos. El controller y el
/// estado de validación pertenecen a este [State] para el mismo propósito
/// que en [_DialogoCambiarPin].
class _DialogoConfirmarPin extends StatefulWidget {
  final IdentidadService identidadService;

  const _DialogoConfirmarPin({required this.identidadService});

  @override
  State<_DialogoConfirmarPin> createState() => _DialogoConfirmarPinState();
}

class _DialogoConfirmarPinState extends State<_DialogoConfirmarPin> {
  late final TextEditingController _pinCtrl;
  String? _error;
  bool _validando = false;

  @override
  void initState() {
    super.initState();
    _pinCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _continuar() async {
    if (!RegExp(r'^\d{4,6}$').hasMatch(_pinCtrl.text)) {
      setState(() => _error = 'Usa entre 4 y 6 dígitos');
      return;
    }

    setState(() {
      _validando = true;
      _error = null;
    });
    final valido = await widget.identidadService.validarPin(_pinCtrl.text);
    if (!mounted) return;
    if (valido) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _validando = false;
        _error = 'El PIN actual no es válido.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirma tu PIN'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _pinCtrl,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(
              labelText: 'PIN actual',
              counterText: '',
              errorText: _error,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _validando ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _validando ? null : _continuar,
          child: _validando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Continuar'),
        ),
      ],
    );
  }
}
