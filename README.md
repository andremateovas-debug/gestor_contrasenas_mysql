# Gestory

Gestor de contraseñas gratuito y de codigo abierto con sistema de cifrado y encriptacion desarrollada en Flutter para Android. 

## Funciones actuales

- Acceso mediante PIN.
- Clave IV como huella y clave de acceso unico que se genera aleatoriamente en el dispsitivo al crear usuario.
- Desbloqueo con biometría del dispositivo. (Solo ciertos dispositivos debido al sistema de seguridad clase II)
- Cifrado de contraseñas antes de guardarlas.
- Creación, edición y eliminación de contraseñas.
- Búsqueda por título o usuario.
- Indicador del espacio de almacenamiento disponible siendo usuario gratuito (A futuro se planea un sistema freemium para mantener los costes de o servidores).
- Perfil con foto en memoria. (Inecesario la verdad Jaja)
- Modos oscuro y normal. (Blanco y negro)
- Sección de soporte con información de contacto en caso de necesitar recuperar las contraseñas.
- Proxima opcion de migrar contraseñas viejas a un nuevo perfil/dispositivo.

## Disponible:


- APK publico en mi sitio web:

	amdevs.mx/gestory

(Proximamente)

- Aplicacion disponible a descargar en Google Play store.

	( Proximamente)

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

Verifica un dispositivo disponible y estado de Flutter:

```bash
flutter doctor
flutter devices
```

## Estructura principal

```text
lib/
├── main.dart
├── pages/
│   ├── pantalla_de_carga.dart
│   ├── registrar.dart
│   ├── ingresar_pin.dart
│   ├── principal_contrasenas.dart
│   ├── almacenamiento.dart
│   ├── configuracion.dart
│   └── contacto.dart
├── services/
│   ├── biometria_service.dart
│   ├── encriptacion_service.dart
│   ├── identidad_service.dart
│   ├── json_service.dart
│   ├── mysql_service.dart
│   ├── sesion_service.dart
│   └── tema_service.dart
└── widgets/
    └── botones.dart
```

## Almacenamiento

Las contraseñas se guardan localmente en un archivo JSON cifrado dentro del dispositivo La capacidad configurada actualmente
es de 50 contraseñas, ademas se relaciona con un usuario unico en una bd MySQL (Para produccion se utilizara PostgreSQL)

## Estado del proyecto

El proyecto se encuentra en desarrollo. Algunas opciones de configuración todavía muestran el mensaje "Próximamente" o directamente se encuentran errores en el flujo de la aplicacion.

## Errores y bugs criticos/no-criticos solucionados.

Bugs viejos:

	- Pantalla roja al ejecutar una creacion/edicion de una contraseña relacionado al flujo de MaterialAPP.

	- Error en la conexion entre aplicacion y api en el dominio para conectarse a la BD, permisos mal colocados en la aplicacion como "Conexion a internet".

	- Cuando se cambia el tema se borraba la desicion al cerrar la app, ya se mantiene si lo haz elegido.

	- No recuerdo