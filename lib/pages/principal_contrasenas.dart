import 'package:flutter/material.dart';
import '../widgets/botones.dart';

class PrincipalContrasenas extends StatefulWidget {
  const PrincipalContrasenas({super.key});

  @override
  State<PrincipalContrasenas> createState() => _PrincipalContrasenasState();
}

class _PrincipalContrasenasState extends State<PrincipalContrasenas> {
  int _paginaActual = 0;

  // Datos mockados
  final List<Map<String, String>> _contrasenas = [
    {
      "titulo": "Facebook",
      "usuario": "usuario@email.com",
      "contrasena": "pass123456",
    },
    {
      "titulo": "Gmail",
      "usuario": "micorreo@gmail.com",
      "contrasena": "securepass789",
    },
    {
      "titulo": "Twitter",
      "usuario": "@miusuario",
      "contrasena": "tweetpass123",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Encabezado
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Text(
                    "Mis Contraseñas",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Agregar contraseña")),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Contenido según página
            Expanded(
              child: _construirContenido(),
            ),

            // Barra de navegación inferior
            BarraNavegacion(
              indexActual: _paginaActual,
              onSeleccionar: (indice) {
                setState(() {
                  _paginaActual = indice;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirContenido() {
    switch (_paginaActual) {
      case 0:
        return _pantallaPrincipal();
      case 1:
        return _pantallaAlmacenamiento();
      case 2:
        return _pantallaConfiguracion();
      default:
        return _pantallaPrincipal();
    }
  }

  Widget _pantallaPrincipal() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _contrasenas.length,
      itemBuilder: (context, index) {
        final contra = _contrasenas[index];
        return _tarjetaContrasena(
          titulo: contra["titulo"]!,
          usuario: contra["usuario"]!,
          onTap: () {
            _mostrarDetalles(contra);
          },
        );
      },
    );
  }

  Widget _tarjetaContrasena({
    required String titulo,
    required String usuario,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
              child: const Icon(
                Icons.lock_outline,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    usuario,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDetalles(Map<String, String> contra) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                contra["titulo"]!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _detalleItem("Usuario", contra["usuario"]!),
              const SizedBox(height: 12),
              _detalleItem("Contraseña", contra["contrasena"]!),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Cerrar",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detalleItem(String label, String valor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pantallaAlmacenamiento() {
    return Center(
      child: Text(
        "Almacenamiento\n(Próximamente)",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withOpacity(0.5),
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _pantallaConfiguracion() {
    return Center(
      child: Text(
        "Configuración\n(Próximamente)",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withOpacity(0.5),
          fontSize: 16,
        ),
      ),
    );
  }
}