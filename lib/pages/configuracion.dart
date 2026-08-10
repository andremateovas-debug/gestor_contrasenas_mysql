import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'contacto.dart';
import '../services/tema_service.dart';

class PantallaConfiguracion extends StatefulWidget {
  const PantallaConfiguracion({super.key});

  @override
  State<PantallaConfiguracion> createState() => _PantallaConfiguracionState();
}

class _PantallaConfiguracionState extends State<PantallaConfiguracion> {
  File? _fotoPerfil;

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
                  onTap: () => _mostrarToast("Próximamente", Colors.white70),
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
                  onTap: () => _mostrarToast("Próximamente", Colors.redAccent),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
