# Seguridad: Firebase Storage (CV / Videocurrículum)

## Qué se cambió en la app

- **Storage Rules**: acceso a `candidates/{uid}/**` y `companies/{uid}/**` restringido al **propietario** (`request.auth.uid == {uid}`).
- **Firestore**: ya **no se persiste** `download_url` (URLs con token) para adjuntos de curriculum ni videocurrículum. Solo se guarda `storage_path` + metadatos.

## Por qué es importante

Las `downloadURL` de Firebase Storage suelen incluir un **token** en el query string. Si ese link se guarda en Firestore, cualquier actor que lea ese documento puede **reutilizar/compartir** el enlace para descargar el archivo aunque luego endurezcas reglas.

## Acción requerida (para completar la mitigación)

Aunque la app ya no genere ni re-escriba `download_url`, es posible que existan **valores antiguos** en Firestore y **tokens antiguos** en objetos ya subidos.

### 1) Eliminar `download_url` existentes en Firestore

Busca y elimina estos campos:

- `candidates/{uid}.video_curriculum.download_url`
- `candidates/{uid}/curriculum/main.attachment.download_url`

Puedes hacerlo con Admin SDK (script) o con una migración puntual desde backend.

### 2) Rotar/revocar tokens de descarga existentes en Storage

Si sospechas que ya se filtraron enlaces antiguos, rota el token del objeto (o re-sube el archivo).

Opciones típicas:

- **Re-subir** el archivo (cambia el token).
- **Rotar metadata** del objeto (`firebaseStorageDownloadTokens`) con Admin SDK o `gsutil` (si lo usas).

> Nota: sin rotación, enlaces antiguos que ya se emitieron pueden seguir funcionando.

