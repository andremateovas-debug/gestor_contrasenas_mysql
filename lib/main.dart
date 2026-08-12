import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/tema_service.dart';
import 'pages/pantalla_de_carga.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const GestorContrasenasApp());
}

class GestorContrasenasApp extends StatefulWidget {
  const GestorContrasenasApp({super.key});

  @override
  State<GestorContrasenasApp> createState() => _GestorContrasenasAppState();
}

class _GestorContrasenasAppState extends State<GestorContrasenasApp> {
  @override
  void initState() {
    super.initState();
    temaApp.addListener(_onTemaCambiado);
  }

  @override
  void dispose() {
    temaApp.removeListener(_onTemaCambiado);
    super.dispose();
  }

  void _onTemaCambiado() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
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
  }
}
