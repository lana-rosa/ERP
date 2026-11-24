# Rosina del ERP (botón flotante «Asistente Rosina»): ¿está actualizada? — 24-nov-2026

Revisión **solo de lectura** (no se cambió nada). Resultado corto: **no está actualizada**; la última edición de su conocimiento fue el 26-oct-2026.

## 1. Dónde vive su conocimiento y quién lo edita
| Parte | Dónde | Quién la edita |
|---|---|---|
| Pantalla del chat | `index.html` (`enviarMensajeAsistenteIA`): solo manda el historial de mensajes (y una imagen opcional) a `WORKER_URL + /api/pos/asistente-ia/chat` con la sesión de la persona. No manda ningún texto de instrucciones. | Repo ERP (este chat) |
| Instrucciones (prompt) y búsqueda | **Worker** `lana-rosa-os-pos` (Cloudflare). No se puede ver ni editar desde aquí. | Solo Sara (panel de Cloudflare) |
| Base de conocimiento | Tabla `public.asistente_ia_base_conocimiento` en Supabase (159 filas, 158 activas, columnas `seccion, titulo, contenido, modulo, orden, activo`). Se edita con `fn_upsert_conocimiento_ia(seccion, titulo, contenido, publico)` y luego `UPDATE` de `modulo`/`orden`. | Este chat (con el sí de Sara/Jennifer) |

## 2. Qué sabe hoy de lo reciente (búsqueda de palabras clave en las filas activas)
| Tema | ¿Está? |
|---|---|
| Horario nuevo (L–V 8:30–12:30 y 2:30–6:00; sáb 8:30–1:00; inauguración dom 13-dic 2:00–6:00 p. m.) | ❌ **Desactualizado**: `casas_lana_rosa` (6-oct) dice inauguración **domingo 15 de noviembre**, L–V **7:30 a. m.–6:15 p. m.**, sáb **8:00–12:00** |
| «Pieza artesanal personalizada…» ya no existe | ✅ No aparece en la base (el Worker puede tenerla en su prompt: no se pudo ver) |
| Gestión Colaboradores: muro, onboarding | ❌ 0 filas (cumplimiento da 17 coincidencias, pero por la palabra general; no se confirmó que sea de Gestión) |
| Marketing en LAROVA (calendario, colores por marca, estadísticas) | ❌ solo 1 fila (15-ago), anterior a esa pantalla |
| Asistente financiero | ❌ 0 filas |
| Recuperación de contraseña | ❌ 0 filas |
| Correo de Sara | ❌ 0 filas (y **no conviene** ponerlo: es un dato personal; basta decir «pide ayuda a la administración») |
| Pago manual Nequi / Bre-B | 🟡 16 filas (última 14-oct): existe, no se verificó que tenga lo último |
| Informes del contador (catálogo de cuentas; gastos y compras por fecha; facturas de compras) | ❌ 0 filas con esos nombres |

## 3. Qué falta y cómo actualizarlo
**Desde el repo/la base (lo hace este chat, con el sí):** agregar o corregir filas de la base de conocimiento. Textos propuestos listos:

1. **Horario y inauguración (corrige `casas_lana_rosa`):** «Tienda física de Lana Rosa, Villamaría. Horario: lunes a viernes de 8:30 a. m. a 12:30 p. m. y de 2:30 a 6:00 p. m.; sábados de 8:30 a. m. a 1:00 p. m. Inauguración: domingo 13 de diciembre de 2026, de 2:00 a 6:00 p. m. (fecha y horas sujetas a cambios).» Y quitar de `casas_lana_rosa` la frase vieja (inauguración 15-nov y horario 7:30–6:15).
2. **Recuperar contraseña (ERP):** «En la pantalla de entrada toca “¿Se te olvidó la contraseña?”, escribe tu correo y toca “Enviar enlace de recuperación”. Si el correo está registrado como colaborador, te llega un enlace; ábrelo y crea tu nueva contraseña. Se permiten 3 intentos por hora. Si no te llega, revisa spam o pide ayuda a la administración.»
3. **Marketing (solo administradoras):** «En LAROVA → Administración → Marketing y comunicación: lista, calendario y resultados. Las piezas de Lana Rosa Crochet van en rosado y las de Academy en azul; se filtra por marca, plataforma, tipo (reel, carrusel, stories…) y estado. En “Resultados” se suben las estadísticas en CSV o Excel y se ve qué rindió mejor.»
4. **Gestión Colaboradores, Asistente financiero e Informes del contador:** el texto debe redactarlo el chat de cada tema (están en `docs/temas/gestion-colaboradores*.md`, `asistente-financiero.md` y los informes del contador). Este chat solo los carga a la base.

**Lo que le toca a Sara en el Worker:** nada que yo pueda confirmar. No se puede ver el prompt del Worker. **Prueba sin riesgo:** pregúntale a Rosina «¿a qué hora abre la tienda y cuándo es la inauguración?» y «¿qué es una pieza artesanal personalizada?». Si responde con el horario viejo después de actualizar la base, o menciona esa pieza, entonces el dato está en el prompt del Worker y Sara debe pegar allí el texto 1 (reemplazando lo viejo) y quitar esa pieza.
