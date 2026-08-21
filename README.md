# AutoPlayer

AutoPlayer es un reproductor de música local para Android, diseñado para ser sencillo, rápido y sin publicidad.

## Funciones

- Reproducción de música almacenada en la carpeta `Music` / `Música`.
- Búsqueda por nombre de canción.
- Reproducir con Enter y limpiar automáticamente la búsqueda.
- Reproducción en orden y aleatoria.
- Pausa, continuar, siguiente, anterior y detener.
- Actualización de la biblioteca al abrir, regresar a la app o deslizar para actualizar.
- Menú de tres puntos por canción.
- Eliminación de canciones con confirmación: **Eliminar canción · Cancelar · Eliminar**.
- Sin publicidad y sin cuenta de usuario.
- No solicita acceso a fotos o videos.

## Android

- Package ID: `com.mrjulioc.autoplayer`
- Min SDK: 23
- Target SDK: 35

## APK

Las APK públicas se publican en la sección **Releases** del repositorio.

Para generar una APK release localmente:

```bash
flutter pub get
flutter build apk --release
```

El archivo se genera en:

```text
build/app/outputs/flutter-apk/app-release.apk
```

> La firma de release usa `android/key.properties`, archivo privado que no debe subirse al repositorio.

## Privacidad

AutoPlayer trabaja con la biblioteca de audio del dispositivo y está enfocado en la carpeta de música. No requiere una cuenta ni envía la biblioteca musical a servidores externos.

## Desarrollador

**MrJulioC**
