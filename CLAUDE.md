# ERP Lana Rosa Crochet — guía para Claude

Dueña: Sara (habla español; responder siempre en español, claro y sin tecnicismos).
Negocio: amigurumis tejidos (Taller), Mercería, Academia, tienda web. Manizales/Villamaría, Colombia. Régimen SIMPLE, proyecto Fondo Emprender (SENA).

## Cómo trabajar (ahorra tokens)
1. NO leas `index.html` completo (~31.900 líneas). Usa `docs/mapa-index-html.md` para ir a la línea exacta y lee solo ese tramo (`Read` con offset/limit o `Grep`).
2. Antes de preguntar o releer el chat, abre el archivo del tema en `docs/temas/` (índice abajo).
3. Estado de lo abierto: `docs/PENDIENTES.md`. Márcalo al cerrar cosas.
4. Al terminar un tema: actualiza su archivo en `docs/temas/` (decisión, por qué, objetos de Supabase, qué falta). Si Sara dice "guarda en docs", hazlo.

## Datos fijos
- Repo `lana-rosa/ERP`, un solo archivo de app `index.html` + `sw.js` (service worker). **Cada cambio en index.html requiere subir `CACHE_NAME` en `sw.js`** (hoy `lana-rosa-os-v37`).
- Flujo: rama → PR → squash merge a `main`. Rama de trabajo de esta sesión: `claude/inspiring-heisenberg-l2905a` (si su PR ya se fusionó, reiniciarla desde `origin/main`).
- Supabase proyecto `ngjoognzvehwjtpqwrqe`. Lógica en funciones RPC plpgsql `security definer`, con RLS.
- Cloudflare Worker `lana-rosa-os-pos` (https://lana-rosa-os-pos.saralmunoz1301.workers.dev) maneja ventas, pedidos y compras. **No se puede editar desde aquí**: las reglas nuevas se aplican en el cliente (index.html) y/o en funciones de Supabase.
- CRM aparte en `/home/user/crm` (todo fusionado a la fecha).
- Base de conocimiento del asistente del ERP: tabla `asistente_ia_base_conocimiento`; se actualiza con `fn_upsert_conocimiento_ia(seccion, titulo, contenido, publico)` y luego `UPDATE` de `modulo`/`orden`. Consultar: `select seccion,titulo from asistente_ia_base_conocimiento where modulo ilike '%tema%'`.

## Trampas conocidas de Supabase (MCP)
- `execute_sql` devuelve solo la última sentencia.
- `DROP FUNCTION`, `ALTER ... DROP COLUMN` y algunos `UPDATE` se cuelgan (event triggers): dejar lo viejo, revocar `execute` de sobrecargas antiguas.
- Pruebas con rollback: `do $$ ... raise exception '...' $$` y simular usuario con `set_config('request.jwt.claims','{"sub":"5d148bc8-f5d2-45bb-86ee-910f274d7f2d","role":"authenticated"}',true)`.
- Cast `::text` al concatenar en plpgsql (`v_lista || 'literal'` falló).
- Si da error 28P01 (auth), esperar y reintentar.

## Pruebas de interfaz
Playwright ya instalado: `NODE_PATH=/opt/node22/lib/node_modules`, chromium `/opt/pw-browsers/chromium`. Al abrir `index.html` desde archivo, reemplazar `window.supabase.createClient` por un stub y abortar peticiones externas.

## Índice de temas (`docs/temas/`)
| Tema | Archivo |
|---|---|
| Vender, factura "a nombre de quién", feria, turno | `ventas-pos.md` |
| Pedidos por redes/WhatsApp, anticipo, anticipo <50 % | `pedidos-anticipo.md` |
| Compras: requisitos SENA/Fondo Emprender, Validar documentos | `compras-sena.md` |
| Facturación electrónica, documento soporte, respaldo mensual (DIAN Res. 165/2023) | `dian-facturacion.md` |
| Previsión de impuestos, ICA, SIMPLE, topes, provisión | `impuestos-prevision.md` |
| Plan de tejido, códigos de barras GS1, ficha técnica de productos e insumos | `produccion-inventario.md` |
| Menú lateral (ocultar/fijar) | `menu-lateral.md` |
| Decisiones contables y políticas (retiros, aportes, honorarios, CUIF) | `contabilidad-decisiones.md` |

Mapa del código: `docs/mapa-index-html.md`. Pendientes: `docs/PENDIENTES.md`.
