import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../services/encriptacion_service.dart';
import '../services/identidad_service.dart';
import '../services/mysql_service.dart';
import '../services/sesion_service.dart';
import 'principal_contrasenas.dart';

class IngresarPin extends StatefulWidget {
  final String? mensajeInicial;

  const IngresarPin({super.key, this.mensajeInicial});

  @override
  State<IngresarPin> createState() => _IngresarPinState();
}

class _IngresarPinState extends State<IngresarPin>
    with SingleTickerProviderStateMixin {
  String _pinIngresado = "";
  int _intentosFallidos = 0;
  int _nivelBloqueo = 0;
  int _segundosBloqueo = 0;
  DateTime? _bloqueadoHasta;
  Timer? _timerBloqueo;
  bool _verificandoPin = false;
  bool _estadoBloqueoCargado = false;
  bool _falloCargaBloqueo = false;

  static const String _claveIntentosFallidos = 'pinIntentosFallidos';
  static const String _claveNivelBloqueo = 'pinNivelBloqueo';
  static const String _claveBloqueadoHasta = 'pinBloqueadoHasta';

  final int _longitudPin = 6;

  final LocalAuthentication _auth = LocalAuthentication();
  final IdentidadService _identidadService = IdentidadService();
  final MysqlService _mysqlService = MysqlService();
  final FlutterSecureStorage _almacenamientoSeguro =
      const FlutterSecureStorage();

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

    _cargarEstadoBloqueo();
    _comprobarBiometria();
    if (widget.mensajeInicial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(widget.mensajeInicial!)));
      });
    }
  }

  @override
  void dispose() {
    _timerBloqueo?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  bool get _estaBloqueado =>
      _falloCargaBloqueo ||
      (_bloqueadoHasta != null && _bloqueadoHasta!.isAfter(DateTime.now()));

  Future<void> _cargarEstadoBloqueo() async {
    if (mounted) {
      setState(() {
        _estadoBloqueoCargado = false;
        _falloCargaBloqueo = false;
      });
    }

    try {
      final intentos = await _almacenamientoSeguro.read(
        key: _claveIntentosFallidos,
      );
      final nivel = await _almacenamientoSeguro.read(key: _claveNivelBloqueo);
      final bloqueadoHasta = await _almacenamientoSeguro.read(
        key: _claveBloqueadoHasta,
      );

      final nuevosIntentos = int.tryParse(intentos ?? '') ?? 0;
      final nuevoNivel = int.tryParse(nivel ?? '') ?? 0;
      final timestamp = int.tryParse(bloqueadoHasta ?? '');
      final nuevaFechaBloqueo = timestamp == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(timestamp);

      if (nuevaFechaBloqueo != null &&
          !nuevaFechaBloqueo.isAfter(DateTime.now())) {
        await _almacenamientoSeguro.delete(key: _claveBloqueadoHasta);
      }

      if (!mounted) return;
      setState(() {
        _intentosFallidos = nuevosIntentos;
        _nivelBloqueo = nuevoNivel;
        _bloqueadoHasta = nuevaFechaBloqueo?.isAfter(DateTime.now()) == true
            ? nuevaFechaBloqueo
            : null;
        _falloCargaBloqueo = false;
        _estadoBloqueoCargado = true;
      });

      if (_estaBloqueado) _iniciarCuentaRegresiva();
    } catch (error) {
      debugPrint(
        'No se pudo cargar el estado de bloqueo: ${error.runtimeType}',
      );
      if (!mounted) return;
      setState(() {
        _falloCargaBloqueo = true;
        _estadoBloqueoCargado = true;
        _segundosBloqueo = 0;
      });
    }
  }

  void _iniciarCuentaRegresiva() {
    _timerBloqueo?.cancel();

    void actualizar() {
      final hasta = _bloqueadoHasta;
      if (hasta == null) return;
      final segundos = (hasta.difference(DateTime.now()).inMilliseconds / 1000)
          .ceil();

      if (segundos <= 0) {
        _timerBloqueo?.cancel();
        _bloqueadoHasta = null;
        if (mounted) {
          setState(() => _segundosBloqueo = 0);
        }
        _almacenamientoSeguro.delete(key: _claveBloqueadoHasta);
        return;
      }

      if (mounted) {
        setState(() => _segundosBloqueo = segundos);
      }
    }

    actualizar();
    _timerBloqueo = Timer.periodic(
      const Duration(seconds: 1),
      (_) => actualizar(),
    );
  }

  Future<void> _registrarIntentoFallido() async {
    _intentosFallidos++;
    if (_intentosFallidos < 5) {
      await _almacenamientoSeguro.write(
        key: _claveIntentosFallidos,
        value: '$_intentosFallidos',
      );
      return;
    }

    final minutos = math.min(15, 1 << _nivelBloqueo);
    _nivelBloqueo++;
    _intentosFallidos = 0;
    _bloqueadoHasta = DateTime.now().add(Duration(minutes: minutos));
    await _almacenamientoSeguro.write(key: _claveIntentosFallidos, value: '0');
    await _almacenamientoSeguro.write(
      key: _claveNivelBloqueo,
      value: '$_nivelBloqueo',
    );
    await _almacenamientoSeguro.write(
      key: _claveBloqueadoHasta,
      value: '${_bloqueadoHasta!.millisecondsSinceEpoch}',
    );
    _iniciarCuentaRegresiva();
  }

  Future<void> _restablecerIntentos() async {
    _intentosFallidos = 0;
    _nivelBloqueo = 0;
    await _almacenamientoSeguro.delete(key: _claveIntentosFallidos);
    await _almacenamientoSeguro.delete(key: _claveNivelBloqueo);
    await _almacenamientoSeguro.delete(key: _claveBloqueadoHasta);
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
    } catch (_) {
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
    if (!_estadoBloqueoCargado) return;
    if (_estaBloqueado) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'La autenticación está bloqueada temporalmente. Intenta de nuevo más tarde.',
            ),
          ),
        );
      }
      return;
    }

    try {
      final claveMaestra = await _identidadService
          .obtenerClaveMaestraBiometrica();
      if (claveMaestra == null || claveMaestra.isEmpty || !mounted) return;

      EncriptacionService.configurarClaveMaestra(claveMaestra);
      SesionService.marcarAutenticada();
      final sesionIniciada = await _iniciarSesionRemota();
      if (sesionIniciada && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PrincipalContrasenas()),
        );
      } else {
        SesionService.cerrar();
        EncriptacionService.limpiarClaveMaestra();
      }
    } on LocalAuthException catch (_) {
    } catch (_) {}
  }

  Future<bool> _iniciarSesionRemota() async {
    final id = await _identidadService.obtenerId();
    final deviceSecretHash = await _identidadService.obtenerDeviceSecretHash();
    if (id == null || deviceSecretHash == null) return false;

    return _mysqlService.iniciarSesion(
      id: id,
      deviceSecretHash: deviceSecretHash,
    );
  }

  // ============================================================
  // PIN
  // ============================================================

  void _agregarNumero(String numero) {
    if (!_estadoBloqueoCargado || _estaBloqueado || _verificandoPin) return;
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
    if (!_estadoBloqueoCargado || _estaBloqueado || _verificandoPin) return;
    if (_pinIngresado.isNotEmpty) {
      setState(() {
        _pinIngresado = _pinIngresado.substring(0, _pinIngresado.length - 1);
      });
    }
  }

  Future<void> _verificarPin() async {
    if (!_estadoBloqueoCargado || _estaBloqueado || _verificandoPin) return;
    if (_pinIngresado.length < 4) {
      _shakeController.forward();
      return;
    }

    setState(() => _verificandoPin = true);
    final pinValido = await _identidadService.validarPin(_pinIngresado);

    if (!pinValido) {
      await _registrarIntentoFallido();
      if (!mounted) return;
      setState(() => _verificandoPin = false);
      _shakeController.forward();
      return;
    }

    if (_tieneReconocimientoFacial) {
      await _identidadService.prepararClaveMaestraBiometrica();
    }
    await _restablecerIntentos();
    SesionService.marcarAutenticada();
    final sesionIniciada = await _iniciarSesionRemota();
    if (sesionIniciada && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PrincipalContrasenas()),
      );
    } else {
      SesionService.cerrar();
      EncriptacionService.limpiarClaveMaestra();
      if (mounted) setState(() => _verificandoPin = false);
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

            if (_segundosBloqueo > 0) ...[
              const SizedBox(height: 18),
              Text(
                "Intenta de nuevo en $_segundosBloqueo segundos",
                style: const TextStyle(color: Colors.redAccent, fontSize: 15),
              ),
            ],

            if (!_estadoBloqueoCargado) ...[
              const SizedBox(height: 24),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(height: 12),
              const Text(
                'Comprobando el estado de seguridad...',
                style: TextStyle(color: Colors.white70),
              ),
            ] else if (_falloCargaBloqueo) ...[
              const SizedBox(height: 24),
              const Text(
                'No se pudo verificar el estado de seguridad. Intenta de nuevo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.redAccent),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _cargarEstadoBloqueo,
                child: const Text('Reintentar'),
              ),
            ],

            const SizedBox(height: 60),

            // ==================================================
            // TECLADO NUMERICO
            // ==================================================
            IgnorePointer(
              ignoring: !_estadoBloqueoCargado || _falloCargaBloqueo,
              child: Padding(
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
            ),

            const SizedBox(height: 30),

            // ==================================================
            // RECONOCIMIENTO FACIAL
            // ==================================================
            if (!_cargandoBiometria && _tieneReconocimientoFacial)
              Column(
                children: [
                  TextButton.icon(
                    onPressed:
                        !_estadoBloqueoCargado ||
                            _falloCargaBloqueo ||
                            _estaBloqueado
                        ? null
                        : _autenticarConRostro,
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
