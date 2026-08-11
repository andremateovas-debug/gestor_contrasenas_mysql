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
    final pinActualCtrl = TextEditingController();
    final nuevoPinCtrl = TextEditingController();
    final confirmarPinCtrl = TextEditingController();
    final formulario = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cambiar PIN'),
          content: Form(
            key: formulario,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _campoPin(pinActualCtrl, 'PIN actual'),
                const SizedBox(height: 12),
                _campoPin(nuevoPinCtrl, 'Nuevo PIN'),
                const SizedBox(height: 12),
                _campoPin(confirmarPinCtrl, 'Confirmar nuevo PIN'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formulario.currentState!.validate() ||
                    nuevoPinCtrl.text != confirmarPinCtrl.text) {
                  _mostrarToast('Los PIN no coinciden.', Colors.redAccent);
                  return;
                }

                Navigator.pop(dialogContext);
                // Diferir el rebuild al siguiente frame, cuando el diálogo
                // ya terminó de desmontarse
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  if (!mounted) return;
                  setState(() => _operacionEnCurso = true);
                  final cambiado = await _identidadService.cambiarPin(
                    pinActual: pinActualCtrl.text,
                    nuevoPin: nuevoPinCtrl.text,
                  );
                  if (!mounted) return;
                  setState(() => _operacionEnCurso = false);
                  _mostrarToast(
                    cambiado ? 'PIN actualizado.' : 'El PIN actual no es válido.',
                    cambiado ? Colors.green : Colors.redAccent,
                  );
                });
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
    pinActualCtrl.dispose();
    nuevoPinCtrl.dispose();
    confirmarPinCtrl.dispose();
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

  Future<bool> _reautenticarParaBorrar() async {
    final pinController = TextEditingController();
    String? error;
    bool validando = false;

    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Confirma tu PIN'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: pinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: 'PIN actual',
                      counterText: '',
                      errorText: error,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: validando
                      ? null
                      : () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: validando
                      ? null
                      : () async {
                          if (!RegExp(
                            r'^\d{4,6}$',
                          ).hasMatch(pinController.text)) {
                            setDialogState(
                              () => error = 'Usa entre 4 y 6 dígitos',
                            );
                            return;
                          }

                          setDialogState(() {
                            validando = true;
                            error = null;
                          });
                          final valido = await _identidadService.validarPin(
                            pinController.text,
                          );
                          if (!dialogContext.mounted) return;
                          if (valido) {
                            Navigator.pop(dialogContext, true);
                          } else {
                            setDialogState(() {
                              validando = false;
                              error = 'El PIN actual no es válido.';
                            });
                          }
                        },
                  child: validando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Continuar'),
                ),
              ],
            );
          },
        );
      },
    );
    pinController.dispose();
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
