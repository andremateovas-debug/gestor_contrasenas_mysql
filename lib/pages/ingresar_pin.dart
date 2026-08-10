import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'principal_contrasenas.dart';

class IngresarPin extends StatefulWidget {
  const IngresarPin({super.key});

  @override
  State<IngresarPin> createState() => _IngresarPinState();
}

class _IngresarPinState extends State<IngresarPin>
    with SingleTickerProviderStateMixin {
  String _pinIngresado = "";

  final String _pinCorrecto = "091026";
  final int _longitudPin = 6;

  final LocalAuthentication _auth = LocalAuthentication();

  bool _tieneReconocimientoFacial = false;
  bool _cargandoBiometria = true;
  IconData _iconoBiometria = Icons.fingerprint;
  String _textoBiometria = "Desbloquear con biometría del teléfono";

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _shakeAnimation =
        Tween<double>(begin: 0, end: 24).animate(
          CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _shakeController.reset();

            if (mounted) {
              setState(() {
                _pinIngresado = "";
              });
            }
          }
        });

    _comprobarBiometria();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  // ============================================================
  // COMPROBAR SI EL TELEFONO TIENE RECONOCIMIENTO FACIAL
  // ============================================================

  Future<void> _comprobarBiometria() async {
    try {
      final bool soportaBiometria = await _auth.canCheckBiometrics;
      final bool dispositivoCompatible = await _auth.isDeviceSupported();

      if (!soportaBiometria || !dispositivoCompatible) {
        if (mounted) {
          setState(() {
            _tieneReconocimientoFacial = false;
            _cargandoBiometria = false;
          });
        }

        return;
      }

      final List<BiometricType> biometriaDisponible = await _auth
          .getAvailableBiometrics();

      debugPrint("Biometría disponible: $biometriaDisponible");

      final bool tieneBiometria = biometriaDisponible.isNotEmpty;

      IconData icono = Icons.fingerprint;
      String texto = "Desbloquear con biometría del teléfono";

      if (biometriaDisponible.contains(BiometricType.face) &&
          !biometriaDisponible.contains(BiometricType.fingerprint)) {
        icono = Icons.face;
        texto = "Desbloquear con rostro";
      } else if (biometriaDisponible.contains(BiometricType.fingerprint) &&
          !biometriaDisponible.contains(BiometricType.face)) {
        icono = Icons.fingerprint;
        texto = "Desbloquear con huella";
      }

      if (mounted) {
        setState(() {
          _tieneReconocimientoFacial = tieneBiometria;
          _iconoBiometria = icono;
          _textoBiometria = texto;
          _cargandoBiometria = false;
        });
      }
    } catch (e) {
      debugPrint("Error comprobando biometría: $e");

      if (mounted) {
        setState(() {
          _tieneReconocimientoFacial = false;
          _cargandoBiometria = false;
        });
      }
    }
  }

  // ============================================================
  // AUTENTICACION FACIAL
  // ============================================================

  Future<void> _autenticarConRostro() async {
    try {
      final bool autenticado = await _auth.authenticate(
        localizedReason:
            'Usa la biometría de tu teléfono para desbloquear tus contraseñas',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );

      if (autenticado && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PrincipalContrasenas()),
        );
      }
    } on LocalAuthException catch (e) {
      debugPrint("Error de autenticación facial: ${e.code}");
    } catch (e) {
      debugPrint("Error de autenticación facial: $e");
    }
  }

  // ============================================================
  // PIN
  // ============================================================

  void _agregarNumero(String numero) {
    if (_pinIngresado.length < _longitudPin) {
      setState(() {
        _pinIngresado += numero;
      });

      if (_pinIngresado.length == _longitudPin) {
        _verificarPin();
      }
    }
  }

  void _eliminarUltimo() {
    if (_pinIngresado.isNotEmpty) {
      setState(() {
        _pinIngresado = _pinIngresado.substring(0, _pinIngresado.length - 1);
      });
    }
  }

  void _verificarPin() {
    if (_pinIngresado == _pinCorrecto) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PrincipalContrasenas()),
      );
    } else {
      _shakeController.forward();
    }
  }

  // ============================================================
  // INTERFAZ
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Ingresa tu PIN",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 50),

            // ==================================================
            // INDICADOR DEL PIN
            // ==================================================
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                final offset = math.sin(_shakeAnimation.value * math.pi) * 8;

                return Transform.translate(
                  offset: Offset(offset, 0),
                  child: child,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_longitudPin, (index) {
                  final bool relleno = index < _pinIngresado.length;

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: relleno ? Colors.white : Colors.transparent,
                      border: Border.all(
                        color: relleno
                            ? Colors.transparent
                            : Colors.white.withOpacity(0.4),
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 60),

            // ==================================================
            // TECLADO NUMERICO
            // ==================================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                childAspectRatio: 1.2,
                children: [
                  _botonNumero("1"),
                  _botonNumero("2"),
                  _botonNumero("3"),

                  _botonNumero("4"),
                  _botonNumero("5"),
                  _botonNumero("6"),

                  _botonNumero("7"),
                  _botonNumero("8"),
                  _botonNumero("9"),

                  _botonIcono(Icons.check, _verificarPin),

                  _botonNumero("0"),

                  _botonIcono(Icons.backspace_outlined, _eliminarUltimo),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ==================================================
            // RECONOCIMIENTO FACIAL
            // ==================================================
            if (!_cargandoBiometria && _tieneReconocimientoFacial)
              Column(
                children: [
                  TextButton.icon(
                    onPressed: _autenticarConRostro,
                    icon: Icon(
                      _iconoBiometria,
                      color: Colors.white70,
                      size: 28,
                    ),
                    label: Text(
                      _textoBiometria,
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BOTON NUMERICO
  // ============================================================

  Widget _botonNumero(String numero) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(50),
        onTap: () => _agregarNumero(numero),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.05),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Center(
            child: Text(
              numero,
              style: const TextStyle(
                fontSize: 28,
                color: Colors.white,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BOTON CON ICONO
  // ============================================================

  Widget _botonIcono(IconData icono, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(50),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.05),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Center(child: Icon(icono, color: Colors.white70, size: 28)),
        ),
      ),
    );
  }
}
