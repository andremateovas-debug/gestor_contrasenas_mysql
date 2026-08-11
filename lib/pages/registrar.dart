import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/identidad_service.dart';
import '../services/mysql_service.dart';
import 'principal_contrasenas.dart';

class PantallaRegistro extends StatefulWidget {
  const PantallaRegistro({super.key});

  @override
  State<PantallaRegistro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<PantallaRegistro> {
  final IdentidadService _identidadService = IdentidadService();
  final MysqlService _mysqlService = MysqlService();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmarPinController = TextEditingController();
  final List<TextEditingController> _palabrasControllers = List.generate(
    5,
    (_) => TextEditingController(),
  );

  int _paso = 0;
  String? _claveMaestraPlano;
  String? _idUsuario;
  String? _deviceSecretHash;
  bool _cargando = false;

  Color get _colorTexto => Theme.of(context).colorScheme.onSurface;

  @override
  void dispose() {
    _nombreController.dispose();
    _pinController.dispose();
    _confirmarPinController.dispose();
    for (final controller in _palabrasControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _registrarUsuario() async {
    final nombre = _nombreController.text.trim();
    final pin = _pinController.text.trim();
    final confirmarPin = _confirmarPinController.text.trim();

    if (nombre.isEmpty) {
      _mostrarError('Escribe tu nombre para continuar.');
      return;
    }
    if (pin.length < 4 || pin.length > 6) {
      _mostrarError('El PIN debe tener entre 4 y 6 dígitos.');
      return;
    }
    if (pin != confirmarPin) {
      _mostrarError('Los PIN no coinciden.');
      return;
    }

    setState(() => _cargando = true);
    try {
      final datos = await _identidadService.registrarUsuario(
        nombre: nombre,
        pin: pin,
      );

      if (!mounted) return;
      setState(() {
        _claveMaestraPlano = datos['claveMaestraPlano'];
        _idUsuario = datos['id'];
        _deviceSecretHash = datos['deviceSecretHash'];
        _paso = 1;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      _mostrarError('No se pudo crear la cuenta: $e');
    }
  }

  Future<void> _confirmarClaveGuardada() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirma tu clave'),
          content: const Text(
            '¿Seguro que guardaste tu clave? No se volverá a mostrar.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (confirmado == true && mounted) {
      setState(() => _paso = 2);
    }
  }

  Future<void> _finalizarRegistro() async {
    final palabras = _palabrasControllers
        .map((controller) => controller.text.trim())
        .toList();

    if (palabras.any((palabra) => palabra.isEmpty)) {
      _mostrarError('Completa las 5 palabras secretas.');
      return;
    }

    setState(() => _cargando = true);
    try {
      final palabrasHasheadas = await _identidadService.guardarPalabrasSecretas(
        palabras,
      );
      final registrado = await _mysqlService.registrarUsuario(
        id: _idUsuario!,
        nombre: _nombreController.text.trim(),
        palabrasHasheadas: palabrasHasheadas,
        deviceSecretHash: _deviceSecretHash!,
      );
      if (!registrado) {
        throw Exception('No se pudo registrar el usuario en el servidor.');
      }

      final sesionIniciada = await _mysqlService.iniciarSesion(
        id: _idUsuario!,
        deviceSecretHash: _deviceSecretHash!,
      );
      if (!sesionIniciada) {
        throw Exception('No se pudo iniciar la sesión en el servidor.');
      }

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const PrincipalContrasenas()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      _mostrarError('No se pudo finalizar el registro: $e');
    }
  }

  InputDecoration _decoracionCampo({
    required String etiqueta,
    required IconData icono,
  }) {
    return InputDecoration(
      labelText: etiqueta,
      labelStyle: TextStyle(color: _colorTexto.withOpacity(0.6)),
      prefixIcon: Icon(icono, color: _colorTexto.withOpacity(0.6)),
      filled: true,
      fillColor: _colorTexto.withOpacity(0.05),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _colorTexto.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _colorTexto.withOpacity(0.4)),
      ),
    );
  }

  Widget _botonPrincipal({
    required String texto,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: onPressed,
        child: _cargando
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(texto),
      ),
    );
  }

  Widget _construirPasoFormulario() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.person_add_alt_1, size: 64),
        const SizedBox(height: 20),
        const Text(
          'Crea tu cuenta',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Configura tu identidad para proteger tus contraseñas.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _colorTexto.withOpacity(0.6)),
        ),
        const SizedBox(height: 28),
        TextField(
          controller: _nombreController,
          style: TextStyle(color: _colorTexto),
          decoration: _decoracionCampo(
            etiqueta: 'Nombre',
            icono: Icons.person_outline,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          style: TextStyle(color: _colorTexto),
          decoration: _decoracionCampo(
            etiqueta: 'PIN de 4 a 6 dígitos',
            icono: Icons.lock_outline,
          ).copyWith(counterText: ''),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _confirmarPinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          style: TextStyle(color: _colorTexto),
          decoration: _decoracionCampo(
            etiqueta: 'Confirmar PIN',
            icono: Icons.lock_outline,
          ).copyWith(counterText: ''),
        ),
        const SizedBox(height: 24),
        _botonPrincipal(
          texto: 'Crear cuenta',
          onPressed: _cargando ? null : _registrarUsuario,
        ),
      ],
    );
  }

  Widget _construirPasoClave() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.warning_amber, color: Colors.amber, size: 64),
        const SizedBox(height: 18),
        const Text(
          'Guarda esta clave en un lugar seguro',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.withOpacity(0.6)),
          ),
          child: SelectableText(
            _claveMaestraPlano ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Esta clave es la única forma de recuperar tus contraseñas si pierdes tu PIN o cambias de dispositivo. Nadie más la tiene, ni siquiera nosotros. Si la pierdes, tus datos no se podrán recuperar.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _colorTexto.withOpacity(0.65), height: 1.5),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () async {
            await Clipboard.setData(
              ClipboardData(text: _claveMaestraPlano ?? ''),
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Clave copiada al portapapeles.')),
              );
            }
          },
          icon: const Icon(Icons.copy),
          label: const Text('Copiar clave'),
        ),
        const SizedBox(height: 12),
        _botonPrincipal(
          texto: 'Ya la guardé de manera segura',
          onPressed: _confirmarClaveGuardada,
        ),
      ],
    );
  }

  Widget _construirPasoPalabras() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.vpn_key_outlined, size: 56),
        const SizedBox(height: 18),
        const Text(
          'Palabras secretas',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          'Para verificación de identidad con soporte, escribe 5 palabras que puedas recordar fácilmente (no deben ser tu clave ni tu PIN).',
          textAlign: TextAlign.center,
          style: TextStyle(color: _colorTexto.withOpacity(0.65), height: 1.5),
        ),
        const SizedBox(height: 22),
        for (int i = 0; i < _palabrasControllers.length; i++) ...[
          TextField(
            controller: _palabrasControllers[i],
            style: TextStyle(color: _colorTexto),
            decoration: _decoracionCampo(
              etiqueta: 'Palabra ${i + 1}',
              icono: Icons.vpn_key_outlined,
            ),
          ),
          if (i < _palabrasControllers.length - 1) const SizedBox(height: 12),
        ],
        const SizedBox(height: 24),
        _botonPrincipal(
          texto: 'Finalizar registro',
          onPressed: _cargando ? null : _finalizarRegistro,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final contenido = switch (_paso) {
      0 => _construirPasoFormulario(),
      1 => _construirPasoClave(),
      _ => _construirPasoPalabras(),
    };

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: contenido,
            ),
          ),
        ),
      ),
    );
  }
}
