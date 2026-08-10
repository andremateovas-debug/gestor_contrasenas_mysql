import 'package:flutter/material.dart';
import 'package:gestor_contrasenas_mysql/pages/ingresar_pin.dart';

class BarraNavegacion extends StatelessWidget {
  final int indexActual;
  final Function(int) onSeleccionar;

  const BarraNavegacion({
    super.key,
    required this.indexActual,
    required this.onSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Botón Home
          _botonNav(
            icono: Icons.home,
            indice: 0,
            esActivo: indexActual == 0,
            onTap: () => onSeleccionar(0),
          ),

          // Botón Almacenamiento
          _botonNav(
            icono: Icons.storage,
            indice: 1,
            esActivo: indexActual == 1,
            onTap: () => onSeleccionar(1),
          ),

          // Botón Configuración
          _botonNav(
            icono: Icons.settings,
            indice: 2,
            esActivo: indexActual == 2,
            onTap: () => onSeleccionar(2),
          ),

          // Botón Salir (Bloquear)
          GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const IngresarPin()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.5)),
              ),
              child: const Icon(
                Icons.lock,
                color: Colors.red,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _botonNav({
    required IconData icono,
    required int indice,
    required bool esActivo,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: esActivo ? Colors.white.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: esActivo
                ? Colors.white.withOpacity(0.3)
                : Colors.transparent,
          ),
        ),
        child: Icon(
          icono,
          color: esActivo ? Colors.white : Colors.white.withOpacity(0.5),
          size: 24,
        ),
      ),
    );
  }
}