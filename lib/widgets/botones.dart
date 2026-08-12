import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gestor_contrasenas_mysql/pages/ingresar_pin.dart';
import '../services/encriptacion_service.dart';
import '../services/mysql_service.dart';
import '../services/sesion_service.dart';

class BarraNavegacion extends StatefulWidget {
  final int indexActual;
  final Function(int) onSeleccionar;

  const BarraNavegacion({
    super.key,
    required this.indexActual,
    required this.onSeleccionar,
  });

  @override
  State<BarraNavegacion> createState() => _BarraNavegacionState();
}

class _BarraNavegacionState extends State<BarraNavegacion> {
  bool _expandida = false;
  Timer? _timerColapso;

  final List<IconData> _iconos = [
    Icons.home_rounded,
    Icons.storage_rounded,
    Icons.settings_rounded,
  ];

  @override
  void dispose() {
    _timerColapso?.cancel();
    super.dispose();
  }

  void _alternarExpansion() {
    setState(() => _expandida = !_expandida);
    if (_expandida) {
      _reiniciarTimer();
    } else {
      _timerColapso?.cancel();
    }
  }

  void _reiniciarTimer() {
    _timerColapso?.cancel();
    _timerColapso = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _expandida = false);
    });
  }

  void _seleccionar(int indice) {
    widget.onSeleccionar(indice);
    // cada vez que elige algo, reinicia los 3 segundos antes de colapsar
    _reiniciarTimer();
  }

  @override
  Widget build(BuildContext context) {
    final colorTexto = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 34), // un poco más arriba
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey.shade900.withOpacity(0.55),
                    Theme.of(context).scaffoldBackgroundColor.withOpacity(0.65),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: colorTexto.withOpacity(0.12),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).scaffoldBackgroundColor.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                child: _expandida ? _vistaExpandida() : _vistaColapsada(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Solo el botón activo + flecha
  Widget _vistaColapsada() {
    return Row(
      key: const ValueKey('colapsada'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _botonCirculo(
          icono: _iconos[widget.indexActual],
          esActivo: true,
          onTap: _alternarExpansion,
        ),
        const SizedBox(width: 8),
        _botonCirculo(
          icono: Icons.keyboard_arrow_up_rounded,
          esActivo: false,
          onTap: _alternarExpansion,
        ),
      ],
    );
  }

  // Todos los botones
  Widget _vistaExpandida() {
    return Row(
      key: const ValueKey('expandida'),
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < _iconos.length; i++) ...[
          _botonCirculo(
            icono: _iconos[i],
            esActivo: widget.indexActual == i,
            onTap: () => _seleccionar(i),
          ),
          const SizedBox(width: 6),
        ],
        _botonCirculo(
          icono: Icons.keyboard_arrow_down_rounded,
          esActivo: false,
          onTap: _alternarExpansion,
        ),
        const SizedBox(width: 6),
        _botonSalir(context),
      ],
    );
  }

  Widget _botonCirculo({
    required IconData icono,
    required bool esActivo,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: esActivo ? Colors.white.withOpacity(0.14) : Colors.transparent,
          border: Border.all(
            color: esActivo
                ? Theme.of(context).colorScheme.onSurface.withOpacity(0.35)
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Icon(
          icono,
          color: esActivo
              ? Theme.of(context).colorScheme.onSurface
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          size: 24,
        ),
      ),
    );
  }

  Widget _botonSalir(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        try {
          await MysqlService().cerrarSesion();
        } catch (_) {
          // El cierre local no depende de que el servidor esté disponible.
        }
        EncriptacionService.limpiarClaveMaestra();
        SesionService.cerrar();
        if (!context.mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => IngresarPin()),
        );
      },
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red.withOpacity(0.18),
          border: Border.all(color: Colors.red.withOpacity(0.4), width: 1),
        ),
        child: const Icon(
          Icons.lock_rounded,
          color: Colors.redAccent,
          size: 22,
        ),
      ),
    );
  }
}
