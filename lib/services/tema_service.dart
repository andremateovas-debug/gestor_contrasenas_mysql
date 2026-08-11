import 'package:flutter/material.dart';

class TemaApp extends ChangeNotifier {
  bool _esOscuro = true;
  bool _notificacionPendiente = false;

  bool get esOscuro => _esOscuro;

  ThemeMode get modo => _esOscuro ? ThemeMode.dark : ThemeMode.light;

  void cambiarModo(bool esOscuro) {
    if (_esOscuro == esOscuro) return;
    _esOscuro = esOscuro;
    if (_notificacionPendiente) return;
    _notificacionPendiente = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificacionPendiente = false;
      if (!hasListeners) return;
      notifyListeners();
    });
  }
}

final temaApp = TemaApp();
