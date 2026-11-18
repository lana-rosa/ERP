# Pasar el repositorio `lana-rosa/ERP` de público a privado (preparado 18-nov-2026; NO aplicado)

Encargo del Orquestador general (🔴: se aplica solo con el sí final de Jennifer, y después de que larova esté estable: vie 4-dic; si no, después del 13-dic). Cambiar la visibilidad es reversible (un clic).

## Por qué
El repositorio público tiene cifras reales del negocio (ver `docs/resumen-contador.md`, `docs/temas/impuestos-preguntas-contador.md`, resumen del orquestador, facturación DIAN, etc.). Además **GitHub Pages publica todo el repositorio**, así que esas páginas también se pueden abrir como `lana-rosa.github.io/ERP/docs/...`.

## Revisión hecha (solo lectura)
- **Llaves en el historial** (456 cambios, 17-jun → hoy, historia completa): **cero llaves secretas.** Solo está la llave pública (`anon`) de Supabase, que por diseño va en la app; "service_role" aparece únicamente como nombre de variable en el código de las funciones. Sin tokens de GitHub/Telegram/Google/Cloudflare, sin llaves privadas ni cadenas de conexión. ⇒ **No hay razón, por el repositorio, para adelantar la rotación de la llave `service_role`** (se hace por prudencia propia, no por una fuga encontrada).
- **Lo ya publicado no se borra:** el historial pudo ser copiado. Hacerlo privado frena nuevas lecturas; no deshace las anteriores.
- **Base de datos ERP:** sin iniciar sesión solo se lee `web_textos` (textos públicos de la tienda). **Base del CRM:** sin iniciar sesión no se lee ninguna tabla.
- **Flujos de GitHub Actions:** este repositorio **no tiene ninguno** (no hay `.github/workflows`). Los avisos de caída y similares están en otros repositorios; los repos privados gratis tienen 2.000 min/mes de Actions, los públicos son ilimitados (revisar en el repo que los tenga si pasa a privado).

## Qué se rompe y cómo evitarlo
1. **`lana-rosa.github.io/ERP/` deja de abrir** (GitHub Pages no sirve repositorios privados en el plan gratuito). Evitarlo con un **repositorio público mínimo de redirección**, sin datos: `docs/privatizar-erp/redireccion-repo-publico/` (repositorio `lana-rosa/lana-rosa.github.io`, carpeta `ERP/` con una página que lleva a `https://larova.lanarosacrochet.com/erp/` conservando lo que venga después, un `sw.js` que desinstala la app vieja y borra sus copias, y un `404.html` que redirige cualquier ruta vieja `/ERP/...`). Probado en local: redirige con `?x=1#abc` conservado; el service worker se desinstala y deja 0 registros y 0 copias. Crear ese repositorio no cambia nada hoy; solo funciona cuando el ERP pasa a privado.
2. **`larova.lanarosacrochet.com/erp/` NO depende de GitHub Pages:** se arma en Cloudflare Pages desde el repositorio (comando `bash scripts/build-larova.sh`, salida `dist`) y solo publica la app (no `docs/`, `supabase/` ni `scripts/`). Cloudflare lee el repositorio con su app de GitHub, que ya tiene permiso sobre `ERP` y **funciona igual con repositorios privados**. Verificar tras el cambio que el siguiente despliegue salga bien.
3. **`/gestion/` y `/CRM/` de larova SÍ dependen de GitHub Pages de `lana-rosa/SO` y `lana-rosa/CRM`** (el reenvío lee `lana-rosa.github.io/SO/` y `/CRM/`). Mientras esos dos repos sigan públicos, nada cambia.
4. **Quien tenga el ERP instalado en la dirección vieja:** al abrirlo, la redirección lo lleva a la dirección nueva; debe instalarlo de nuevo desde `larova.lanarosacrochet.com/erp/`. Avisar a Sara, Jennifer y Manuela.
5. **El Worker de ventas** sigue aceptando `lana-rosa.github.io` (no estorba). El CRM chat 5 debe cambiar su enlace `avisarPedidoEnERP` a la dirección nueva antes.
6. **Chats/orquestadores que leen el repositorio sin permisos** dejarán de poder: hay que agregarlo con permisos (`add_repo`). Esta sesión ya lo tiene adjunto.

## CRM y Gestión (SO): ¿mismo problema?
- **SO** (12 archivos, solo código y SQL de seguridad): sin cifras ni datos de personas; solo la llave pública. Riesgo de datos: **bajo**. Se ve el diseño del sistema.
- **CRM** (30 archivos): código del CRM con la llave pública y 3 correos en el código; sin cifras. Riesgo de datos: **bajo** (revisé solo la última versión, no el historial de esos dos repos).
- Protegerlos costaría: crear un proyecto de Cloudflare Pages por cada uno (gratis), apuntar el reenvío de larova a esas direcciones y quitar sus direcciones de GitHub Pages. No es urgente. **La WEB sigue pública** (es el sitio).

## Orden propuesto
1. Vie 4-dic: larova estable y anunciada; app reinstalada; CRM chat 5 con su enlace nuevo.
2. Crear `lana-rosa/lana-rosa.github.io` (público) con los archivos de `docs/privatizar-erp/redireccion-repo-publico/` y activar Pages (Settings → Pages → `main` / root).
3. Hacer privado el ERP: GitHub → `lana-rosa/ERP` → Settings → General → Danger Zone → Change repository visibility → Make private (GitHub avisa que se despublica su página; es lo esperado).
4. Verificar: `lana-rosa.github.io/ERP/` lleva a larova; un cambio pequeño en `main` despliega en Cloudflare; larova/erp, /gestion y /CRM abren.
5. Avisar al orquestador para dar acceso a los chats.
Si algo sale mal: volver a público (un clic) o revertir el despliegue en Cloudflare.
