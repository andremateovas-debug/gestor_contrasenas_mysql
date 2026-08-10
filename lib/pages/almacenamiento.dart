import 'package:flutter/material.dart';
import '../services/json_service.dart';

class PantallaAlmacenamiento extends StatefulWidget {
  const PantallaAlmacenamiento({super.key});

  @override
  State<PantallaAlmacenamiento> createState() => _PantallaAlmacenamientoState();
}

class _PantallaAlmacenamientoState extends State<PantallaAlmacenamiento> {
  static const int _limiteMaximo = 200;

  final JsonService _jsonService = JsonService();
  int _cantidadActual = 0;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarConteo();
  }

  Future<void> refrescar() async {
    await _cargarConteo();
  }

  Future<void> _cargarConteo() async {
    if (mounted) {
      setState(() => _cargando = true);
    }

    final contras = await _jsonService.leerContrasenas();

    if (mounted) {
      setState(() {
        _cantidadActual = contras.length;
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const SafeArea(
        child: Center(child: CircularProgressIndicator(color: Colors.white70)),
      );
    }

    final bool estaLleno = _cantidadActual >= _limiteMaximo;
    final double porcentaje = _cantidadActual / _limiteMaximo;
    final double progreso = porcentaje.clamp(0.0, 1.0);
    final Color colorEstado = estaLleno
        ? Colors.redAccent
        : porcentaje >= 0.8
        ? Colors.orangeAccent
        : Colors.white;
    final String textoEstado = estaLleno
        ? "Límite alcanzado"
        : "Quedan ${_limiteMaximo - _cantidadActual} espacios disponibles";

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: estaLleno
                      ? Colors.red.withOpacity(0.14)
                      : Colors.white.withOpacity(0.08),
                  border: Border.all(
                    color: estaLleno
                        ? Colors.redAccent.withOpacity(0.45)
                        : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Icon(
                  Icons.storage_rounded,
                  size: 68,
                  color: colorEstado,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Almacenamiento",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "$_cantidadActual / $_limiteMaximo",
                style: TextStyle(
                  color: colorEstado,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: progreso,
                  minHeight: 11,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(colorEstado),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                textoEstado,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: estaLleno
                      ? Colors.redAccent
                      : Colors.white.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
