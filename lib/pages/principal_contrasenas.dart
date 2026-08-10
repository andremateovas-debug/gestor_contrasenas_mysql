import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/json_service.dart';
import '../widgets/botones.dart';
import 'almacenamiento.dart';
import 'configuracion.dart';

class PrincipalContrasenas extends StatefulWidget {
  const PrincipalContrasenas({super.key});

  @override
  State<PrincipalContrasenas> createState() => _PrincipalContrasenasState();
}

class _PrincipalContrasenasState extends State<PrincipalContrasenas> {
  int _paginaActual = 0;
  List<dynamic> _contrasenas = [];
  List<dynamic> _filtradas = [];
  bool _cargando = true;
  final TextEditingController _busquedaCtrl = TextEditingController();
  final JsonService _jsonService = JsonService();

  @override
  void initState() {
    super.initState();
    _cargarContrasenas();
    _busquedaCtrl.addListener(_filtrar);
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarContrasenas() async {
    setState(() => _cargando = true);
    final contras = await _jsonService.leerContrasenas();
    setState(() {
      _contrasenas = contras;
      _filtradas = List.from(contras);
      _cargando = false;
    });
  }

  void _filtrar() {
    final query = _busquedaCtrl.text.toLowerCase();
    if (query.isEmpty) {
      setState(() => _filtradas = List.from(_contrasenas));
    } else {
      setState(() {
        _filtradas = _contrasenas
            .where(
              (item) =>
                  (item["titulo"] ?? "").toString().toLowerCase().contains(
                    query,
                  ) ||
                  (item["usuario"] ?? "").toString().toLowerCase().contains(
                    query,
                  ),
            )
            .toList();
      });
    }
  }

  void _mostrarFormularioAgregar() {
    final tituloCtrl = TextEditingController();
    final usuarioCtrl = TextEditingController();
    final contrasenaCtrl = TextEditingController();
    final sitioWebCtrl = TextEditingController();
    bool verContrasena = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Nueva contraseña",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _campoTexto(
                      tituloCtrl,
                      "Título (ej. Facebook)",
                      Icons.title,
                    ),
                    const SizedBox(height: 12),
                    _campoTexto(
                      usuarioCtrl,
                      "Usuario o Email",
                      Icons.person_outline,
                    ),
                    const SizedBox(height: 12),
                    // Campo de contraseña con toggle
                    TextField(
                      controller: contrasenaCtrl,
                      obscureText: !verContrasena,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Contraseña",
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                        ),
                        prefixIcon: Icon(
                          Icons.key_outlined,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            verContrasena
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.white.withOpacity(0.5),
                          ),
                          onPressed: () => setModalState(
                            () => verContrasena = !verContrasena,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _campoTexto(
                      sitioWebCtrl,
                      "Sitio web (Opcional)",
                      Icons.public,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          if (tituloCtrl.text.isEmpty ||
                              contrasenaCtrl.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Título y contraseña son requeridos",
                                ),
                              ),
                            );
                            return;
                          }

                          bool exito = await _jsonService.agregarContrasena(
                            titulo: tituloCtrl.text,
                            usuario: usuarioCtrl.text,
                            contrasena: contrasenaCtrl.text,
                            sitioWeb: sitioWebCtrl.text,
                          );

                          if (exito && mounted) {
                            // Recargar PRIMERO
                            await _cargarContrasenas();
                            // LUEGO cerrar modal
                            Navigator.pop(context);
                            // FINALMENTE mostrar toast
                            _mostrarToast(
                              "Contraseña guardada con encriptación ✅",
                              Colors.green,
                            );
                          }
                        },
                        child: const Text(
                          "Guardar",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _mostrarDetalles(Map<String, dynamic> contra) {
    bool obscurePassword = true;
    bool editando = false;

    final tituloCtrl = TextEditingController(text: contra["titulo"]);
    final usuarioCtrl = TextEditingController(text: contra["usuario"]);
    final contrasenaCtrl = TextEditingController(text: contra["contrasena"]);
    final sitioWebCtrl = TextEditingController(text: contra["sitio_web"] ?? "");

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            editando
                                ? tituloCtrl.text
                                : contra["titulo"] ?? "Sin título",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          onPressed: () async {
                            bool exito = await _jsonService.eliminarContrasena(
                              titulo: contra["titulo"],
                              usuario: contra["usuario"],
                            );

                            if (exito && mounted) {
                              Navigator.pop(context);
                              await _cargarContrasenas();
                              _mostrarToast("Eliminada 🗑️", Colors.red);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (editando) ...[
                      _campoTexto(tituloCtrl, "Título", Icons.title),
                      const SizedBox(height: 12),
                      _campoTexto(usuarioCtrl, "Usuario", Icons.person_outline),
                      const SizedBox(height: 12),
                      _campoTexto(
                        contrasenaCtrl,
                        "Contraseña",
                        Icons.key_outlined,
                        obscureText: true,
                      ),
                      const SizedBox(height: 12),
                      _campoTexto(sitioWebCtrl, "Sitio web", Icons.public),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.1),
                          ),
                          onPressed: () async {
                            bool exito = await _jsonService
                                .actualizarContrasena(
                                  tituloViejo: contra["titulo"],
                                  usuarioViejo: contra["usuario"],
                                  tituloNuevo: tituloCtrl.text,
                                  usuarioNuevo: usuarioCtrl.text,
                                  contrasena: contrasenaCtrl.text,
                                  sitioWeb: sitioWebCtrl.text,
                                );

                            if (exito && mounted) {
                              Navigator.pop(context);
                              await _cargarContrasenas();
                              _mostrarToast("Actualizada ✅", Colors.green);
                            }
                          },
                          child: const Text(
                            "Guardar cambios",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ] else ...[
                      _detalleItem(
                        "Usuario",
                        contra["usuario"] ?? "No definido",
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _detalleItem(
                              "Contraseña",
                              obscurePassword
                                  ? "••••••••••••"
                                  : contra["contrasena"],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.white.withOpacity(0.5),
                            ),
                            onPressed: () => setModalState(
                              () => obscurePassword = !obscurePassword,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, color: Colors.white70),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: contra["contrasena"]),
                              );
                              _mostrarToast(
                                "Copiada al portapapeles ✅",
                                Colors.green,
                              );
                            },
                          ),
                        ],
                      ),
                      if (contra["sitio_web"] != null &&
                          contra["sitio_web"].toString().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _detalleItem("Sitio web", contra["sitio_web"]),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.1),
                          ),
                          onPressed: () => setModalState(() => editando = true),
                          child: const Text(
                            "Editar",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _campoTexto(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    bool obscureText = false,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.5)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
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

  void _mostrarToast(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorTexto = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (_paginaActual != 1 && _paginaActual != 2) ...[
              // Encabezado
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Text(
                      "Mis Contraseñas",
                      style: TextStyle(
                        color: colorTexto,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.add, color: colorTexto, size: 28),
                      onPressed: _mostrarFormularioAgregar,
                    ),
                  ],
                ),
              ),

              // Buscador
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _busquedaCtrl,
                  style: TextStyle(color: colorTexto),
                  decoration: InputDecoration(
                    hintText: "Buscar por título o usuario...",
                    hintStyle: TextStyle(color: colorTexto.withOpacity(0.4)),
                    prefixIcon: Icon(
                      Icons.search,
                      color: colorTexto.withOpacity(0.5),
                    ),
                    filled: true,
                    fillColor: colorTexto.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Contenido
            Expanded(child: _construirContenido()),

            // Barra de navegación
            BarraNavegacion(
              indexActual: _paginaActual,
              onSeleccionar: (indice) {
                setState(() => _paginaActual = indice);
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
        return const PantallaAlmacenamiento();
      case 2:
        return const PantallaConfiguracion();
      default:
        return _pantallaPrincipal();
    }
  }

  Widget _pantallaPrincipal() {
    final colorTexto = Theme.of(context).colorScheme.onSurface;

    if (_cargando) {
      return Center(
        child: CircularProgressIndicator(color: colorTexto.withOpacity(0.7)),
      );
    }

    if (_filtradas.isEmpty) {
      return Center(
        child: Text(
          _contrasenas.isEmpty
              ? "No hay contraseñas guardadas\nToca + para crear una"
              : "Sin resultados",
          textAlign: TextAlign.center,
          style: TextStyle(color: colorTexto.withOpacity(0.5)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filtradas.length,
      itemBuilder: (context, index) {
        final contra = _filtradas[index];
        return _tarjetaContrasena(
          titulo: contra["titulo"] ?? "Sin título",
          usuario: contra["usuario"] ?? "Sin usuario",
          onTap: () => _mostrarDetalles(contra),
        );
      },
    );
  }

  Widget _tarjetaContrasena({
    required String titulo,
    required String usuario,
    required VoidCallback onTap,
  }) {
    final colorTexto = Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorTexto.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorTexto.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorTexto.withOpacity(0.1),
              ),
              child: Icon(Icons.lock_outline, color: colorTexto, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      color: colorTexto,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    usuario,
                    style: TextStyle(
                      color: colorTexto.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: colorTexto.withOpacity(0.54),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
