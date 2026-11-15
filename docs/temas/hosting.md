# Hosting: mudanza de GitHub Pages a Cloudflare Pages (13-nov)
Decisión de Sara: publicar el ERP en Cloudflare Pages (proyecto `lana-rosa-erp`, rama `main`, sin compilación, salida = raíz) para luego hacer **privado** el repositorio. Hoy: https://lana-rosa.github.io/ERP/. Cloudflare dio errores 503 al crear el proyecto (13-nov); Sara reintenta.

## Revisión (hecha 13-nov)
- **Rutas: OK.** `manifest.json` (`start_url ./index.html`, `scope ./`, íconos `./...`), `sw.js` (`./`) y la app usan rutas relativas; no hay `/ERP/` fijo. Funciona en la raíz de un dominio nuevo. Los mensajes de bienvenida usan la dirección donde se abre la app (`urlPlataformaErp`), así que cambian solos.
- **Funciones de Supabase: OK.** `enviar-correo` e `indicadores-crm` responden CORS con `*`; no hay que cambiar nada.
- **Supabase Auth: nada que agregar.** Solo se usa correo + contraseña (`signInWithPassword`, `updateUser`); no hay enlaces mágicos, OAuth ni recuperación por correo. Por prudencia Sara puede poner la dirección nueva en Authentication → URL Configuration (Redirect URLs), pero hoy no se usa.
- **Enlaces fijos:** el CRM (repo `lana-rosa/CRM`, `index.html`, función `avisarPedidoEnERP`) tiene `https://lana-rosa.github.io/ERP/`. Lo cambia el Orquestador del CRM con la dirección definitiva. En este repo no hay enlaces fijos (solo menciones en docs).
- ✅ **RESUELTO 13-nov (ver abajo).** Antes: el Worker de ventas solo aceptaba el origen `https://lana-rosa.github.io`.** Prueba (OPTIONS y GET con `Origin: https://lana-rosa-erp.pages.dev`): responde `access-control-allow-origin: https://lana-rosa.github.io`, es decir, el navegador **bloqueará** desde `pages.dev` todo lo que pasa por el Worker (ventas, pedidos, compras, clientes, directorio...). Inicio de sesión y lecturas directas a Supabase sí funcionarían.

## Salidas al bloqueo (decide Sara)
1. **Editar el Worker** (en el panel de Cloudflare, no se puede desde aquí): permitir también `https://lana-rosa-erp.pages.dev` (y el dominio propio si lo hay) en su lista de orígenes. Es lo más simple; una línea.
2. **Sin tocar el Worker:** agregar a este repo una función de Cloudflare Pages (`functions/api/[[path]].js`) que reenvíe `/api/*` al Worker, y que `WORKER_URL` use la misma dirección de la app cuando no esté en github.io. No hace falta compilar. Se puede dejar lista aquí.
- Mientras tanto GitHub Pages sigue funcionando; **no hacer privado el repo hasta que la dirección nueva venda de prueba bien.**

## Otra cosa a decidir antes de hacer público en Pages
Con "salida = raíz", Cloudflare publicaría **todo el repo**: `docs/`, `supabase/functions/` y `CLAUDE.md` quedarían legibles en la dirección nueva (hoy ya lo están en GitHub Pages). Recomendación: usar comando de compilación `mkdir dist && cp index.html sw.js manifest.json logo-animado.html *.png dist/` y salida = `dist`.

## Falta (cuando Sara tenga la dirección nueva)
Probar inicio de sesión, venta de prueba (sin confirmar si no hay turno), pedidos y app instalable. Reinstalar la app instalada (cambia de dirección).

## Worker de ventas: CORS corregido (13-nov, autorizado por Sara)
- Se publicó en Cloudflare (Worker `lana-rosa-os-pos`, versión anterior = 187, de 30-sep, panel) una capa final que acepta los orígenes `https://lana-rosa.github.io` y `https://lana-rosa-erp.pages.dev`: ajusta solo `Access-Control-Allow-Origin` (+ `Vary: Origin`) según el `Origin` de la petición; con otro origen responde como antes (github.io). No toca rutas, claves, IA ni las 2 tareas programadas (`0 * * * *` y `55 4 * * *`).
- Hecho con la API de Cloudflare y un token temporal de Sara (Workers Scripts Edit + Account Settings Read, vence 20-nov-2026; Sara debe borrarlo). Se subió con `keep_bindings` (secretos y variables intactos) y se verificó después: bindings AI, SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, CRM_SUPABASE_URL, CRM_SUPABASE_SERVICE_ROLE_KEY siguen.
- Verificado con curl: OPTIONS y GET desde pages.dev y github.io → permitido; origen ajeno → solo github.io; sin token → 401.
- Revertir: panel de Cloudflare → Workers → lana-rosa-os-pos → Deployments → volver a la versión 187.
- **Si la dirección definitiva es otra** (otro nombre de proyecto o dominio propio) hay que agregarla a `ORIGENES_PERMITIDOS` en el Worker. El código del Worker no está en este repo (se edita en el panel).
- Sin probar aún con la app real en la dirección nueva (falta que Sara cree el proyecto en Cloudflare Pages): inicio de sesión, venta de prueba, pedidos, app instalable.
