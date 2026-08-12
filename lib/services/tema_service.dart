import 'package:flutter/material.dart';

class TemaApp extends ChangeNotifier {
  bool _esOscuro = true;

  bool get esOscuro => _esOscuro;

  ThemeMode get modo => _esOscuro ? ThemeMode.dark : ThemeMode.light;

  void cambiarModo(bool esOscuro) {
    if (_esOscuro == esOscuro) return;
    _esOscuro = esOscuro;
    notifyListeners();
  }
}

final temaApp = TemaApp();
