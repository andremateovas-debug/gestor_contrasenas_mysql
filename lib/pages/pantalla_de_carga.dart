import 'package:flutter/material.dart';
import 'ingresar_pin.dart';
import 'registrar.dart';
import '../services/identidad_service.dart';

class PantallaDeCarga extends StatefulWidget {
  const PantallaDeCarga({super.key});

  @override
  State<PantallaDeCarga> createState() => _PantallaDeCargaState();
}

class _PantallaDeCargaState extends State<PantallaDeCarga>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation1;
  late final Animation<double> _animation2;
  late final Animation<double> _animation3;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Cada punto salta con delay progresivo
    _animation1 = Tween<double>(begin: 0, end: -30).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );

    _animation2 = Tween<double>(begin: 0, end: -30).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.7, curve: Curves.easeInOut),
      ),
    );

    _animation3 = Tween<double>(begin: 0, end: -30).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.9, curve: Curves.easeInOut),
      ),
    );

    _verificarUsuario();
  }

  Future<void> _verificarUsuario() async {
    await Future<void>.delayed(const Duration(seconds: 4));
    if (!mounted) return;

    final existeUsuario = await IdentidadService().existeUsuario();
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            existeUsuario ? const IngresarPin() : const PantallaRegistro(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _animation1,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _animation1.value),
                  child: child,
                );
              },
              child: Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _animation2,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _animation2.value),
                  child: child,
                );
              },
              child: Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _animation3,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _animation3.value),
                  child: child,
                );
              },
              child: Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
