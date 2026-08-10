import 'package:flutter/material.dart';
import 'services/encriptacion_service.dart';
import 'pages/pantalla_de_carga.dart';

void main() {
  // PRUEBA DE CIFRADO: llamada añadida antes de iniciar la aplicación.
  EncriptacionService.prueba();
  EncriptacionService.mostrarDatosCifrado();
  runApp(const GestorContrasenasApp());
}

class GestorContrasenasApp extends StatelessWidget {
  const GestorContrasenasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gestor de Contraseñas',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.white,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const PantallaDeCarga(),
    );
  }
}
