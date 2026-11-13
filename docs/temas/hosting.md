# Hosting: mudanza de GitHub Pages a Cloudflare Pages (13-nov)
Decisión de Sara: publicar el ERP en Cloudflare Pages (proyecto `lana-rosa-erp`, rama `main`, sin compilación, salida = raíz) para luego hacer **privado** el repositorio. Hoy: https://lana-rosa.github.io/ERP/. Cloudflare dio errores 503 al crear el proyecto (13-nov); Sara reintenta.

## Revisión (hecha 13-nov)
- **Rutas: OK.** `manifest.json` (`start_url ./index.html`, `scope ./`, íconos `./...`), `sw.js` (`./`) y la app usan rutas relativas; no hay `/ERP/` fijo. Funciona en la raíz de un dominio nuevo. Los mensajes de bienvenida usan la dirección donde se abre la app (`urlPlataformaErp`), así que cambian solos.
- **Funciones de Supabase: OK.** `enviar-correo` e `indicadores-crm` responden CORS con `*`; no hay que cambiar nada.
- **Supabase Auth: nada que agregar.** Solo se usa correo + contraseña (`signInWithPassword`, `updateUser`); no hay enlaces mágicos, OAuth ni recuperación por correo. Por prudencia Sara puede poner la dirección nueva en Authentication → URL Configuration (Redirect URLs), pero hoy no se usa.
- **Enlaces fijos:** el CRM (repo `lana-rosa/CRM`, `index.html`, función `avisarPedidoEnERP`) tiene `https://lana-rosa.github.io/ERP/`. Lo cambia el Orquestador del CRM con la dirección definitiva. En este repo no hay enlaces fijos (solo menciones en docs).
- 🔴 **BLOQUEO: el Worker de ventas solo acepta el origen `https://lana-rosa.github.io`.** Prueba (OPTIONS y GET con `Origin: https://lana-rosa-erp.pages.dev`): responde `access-control-allow-origin: https://lana-rosa.github.io`, es decir, el navegador **bloqueará** desde `pages.dev` todo lo que pasa por el Worker (ventas, pedidos, compras, clientes, directorio...). Inicio de sesión y lecturas directas a Supabase sí funcionarían.

## Salidas al bloqueo (decide Sara)
1. **Editar el Worker** (en el panel de Cloudflare, no se puede desde aquí): permitir también `https://lana-rosa-erp.pages.dev` (y el dominio propio si lo hay) en su lista de orígenes. Es lo más simple; una línea.
2. **Sin tocar el Worker:** agregar a este repo una función de Cloudflare Pages (`functions/api/[[path]].js`) que reenvíe `/api/*` al Worker, y que `WORKER_URL` use la misma dirección de la app cuando no esté en github.io. No hace falta compilar. Se puede dejar lista aquí.
- Mientras tanto GitHub Pages sigue funcionando; **no hacer privado el repo hasta que la dirección nueva venda de prueba bien.**

## Otra cosa a decidir antes de hacer público en Pages
Con "salida = raíz", Cloudflare publicaría **todo el repo**: `docs/`, `supabase/functions/` y `CLAUDE.md` quedarían legibles en la dirección nueva (hoy ya lo están en GitHub Pages). Recomendación: usar comando de compilación `mkdir dist && cp index.html sw.js manifest.json logo-animado.html *.png dist/` y salida = `dist`.

## Falta (cuando Sara tenga la dirección nueva)
Probar inicio de sesión, venta de prueba (sin confirmar si no hay turno), pedidos y app instalable. Reinstalar la app instalada (cambia de dirección).
