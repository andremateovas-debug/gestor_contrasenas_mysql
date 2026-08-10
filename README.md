# Gestory

Aplicación móvil desarrollada con Flutter para guardar y administrar
contraseñas de forma local y cifrada. (Pronto en bd MySQL)

## Funciones actuales

- Acceso mediante PIN.
- Desbloqueo con biometría del dispositivo.
- Cifrado de contraseñas antes de guardarlas.
- Creación, edición y eliminación de contraseñas.
- Búsqueda por título o usuario.
- Indicador del espacio de almacenamiento disponible.
- Perfil con foto en memoria.
- Modos oscuro y normal.
- Sección de soporte con información de contacto.

## Requisitos

- Flutter instalado.
- Dart compatible con la versión indicada en `pubspec.yaml`.
- Un dispositivo Android o un emulador configurado.

## Ejecución

```bash
flutter pub get
flutter run
```

Para comprobar el proyecto antes de ejecutarlo:

```bash
flutter analyze
```

## Lanzamiento

en poco tiempo dare a publico un apk donde podras instalarlo y ya sea funciona, ademas de estar disponible en Pay Store.

## Estructura principal

```text
lib/
├── main.dart
├── pages/
│   ├── ingresar_pin.dart
│   ├── principal_contrasenas.dart
│   ├── almacenamiento.dart
│   ├── configuracion.dart
│   └── contacto.dart
├── services/
│   ├── encriptacion_service.dart
│   ├── json_service.dart
│   └── tema_service.dart
└── widgets/
	└── botones.dart
```

## Almacenamiento

Las contraseñas se guardan localmente en un archivo JSON cifrado dentro del
directorio de documentos de la aplicación. La capacidad configurada actualmente
es de 50 contraseñas.

## Estado del proyecto

El proyecto se encuentra en desarrollo. Algunas opciones de configuración
todavía muestran el mensaje "Próximamente".