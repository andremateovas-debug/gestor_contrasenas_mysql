import 'package:flutter/material.dart';
import 'services/encriptacion_service.dart';
import 'services/tema_service.dart';
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
    return AnimatedBuilder(
      animation: temaApp,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Gestor de Contraseñas',
          themeMode: temaApp.modo,
          themeAnimationDuration: Duration.zero,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.white,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.black,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
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
      },
    );
  }
}
