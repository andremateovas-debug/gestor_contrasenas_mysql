import 'package:flutter/material.dart';

class PantallaContacto extends StatelessWidget {
  const PantallaContacto({super.key});

  @override
  Widget build(BuildContext context) {
    final colorTexto = Theme.of(context).colorScheme.onSurface;
    final colorFondo = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: colorFondo,
      appBar: AppBar(
        backgroundColor: colorFondo,
        foregroundColor: colorTexto,
        title: Text("Soporte", style: TextStyle(color: colorTexto)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorTexto.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorTexto.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.support_agent_outlined,
                      color: colorTexto.withOpacity(0.85),
                      size: 64,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Información de contacto",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colorTexto,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _datoContacto(
                      icono: Icons.email_outlined,
                      texto: "soporte@amdevs.mx",
                      colorTexto: colorTexto,
                    ),
                    const SizedBox(height: 16),
                    _datoContacto(
                      icono: Icons.phone_outlined,
                      texto: "624 121 9430",
                      colorTexto: colorTexto,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorTexto.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorTexto.withOpacity(0.1)),
                ),
                child: Text(
                  "Si requieres la recuperación de tus contraseñas recuerda que debes tener a la mano tu clave hash y las 5 palabras especificadas por ti.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorTexto.withOpacity(0.65),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _datoContacto({
    required IconData icono,
    required String texto,
    required Color colorTexto,
  }) {
    return Row(
      children: [
        Icon(icono, color: colorTexto.withOpacity(0.65), size: 24),
        const SizedBox(width: 14),
        Expanded(
          child: Text(texto, style: TextStyle(color: colorTexto, fontSize: 16)),
        ),
      ],
    );
  }
}
