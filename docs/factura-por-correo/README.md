# Facturación DIAN → ERP por correo (segunda etapa) — diseño

**Estado:** diseño y borradores. Nada de esto está desplegado ni probado con correos reales.

## Objetivo
Cada factura que emite la solución gratuita de la DIAN queda registrada sola en el ERP, sin subir el ZIP a mano.
La DIAN no ofrece API ni aviso para la solución gratuita; lo único automático que sale de ella es **el correo con la factura** (ZIP con XML + PDF). El diseño aprovecha ese correo.

## Flujo
1. La DIAN envía el correo de cada factura emitida al correo del emisor (el correo de la empresa).
2. Un script de **Google Apps Script** (en esa cuenta de Gmail) revisa cada 5–10 min los correos nuevos de la DIAN que traen ZIP/XML y no tienen la etiqueta `ERP-procesado`.
3. Por cada adjunto, hace `POST` a la función de Supabase `recibir-factura-dian` (con una clave secreta) enviando el archivo en base64 y el `message_id`.
4. La función lee el XML (misma lógica que el botón "Subir factura de la DIAN" del ERP) y llama a `fn_fe_registrar_factura_auto`.
5. Resultado, según el caso:
   - **Una sola venta pendiente coincide** (mismo valor y, si no es consumidor final, mismo documento; fecha cercana) → se registra la factura (número, CUFE, fecha) y queda en "Facturas emitidas".
   - **Ninguna o varias coinciden** → queda en la **bandeja** `fe_bandeja_correo` con estado `revisar`; en el ERP se muestra para que alguien elija la venta con un clic.
   - **CUFE ya registrado** → `duplicada`, no se vuelve a registrar.
   - **Nota crédito/débito o XML inválido** → `revisar` con el motivo.
6. El script pone la etiqueta `ERP-procesado` al correo solo si la función respondió 200 (así los fallos se reintentan).

## Por qué Apps Script y no Cloudflare Email Routing
- No requiere controlar el DNS del dominio ni acceso a Cloudflare.
- Corre gratis dentro de la cuenta de Gmail que ya recibe el correo de la DIAN.
- Alternativa si más adelante se prefiere: Email Worker de Cloudflare (reenviar a una dirección del dominio). El contrato con la función de Supabase es el mismo.

## Seguridad
- La función valida una clave compartida (`x-clave-correo`); en Supabase solo se guarda su huella SHA-256 (mismo patrón que `indicadores-crm`). La clave real se pone en las propiedades del script, no en el código.
- Solo se aceptan adjuntos `.zip` / `.xml` de hasta ~5 MB; no se ejecuta nada del archivo, solo se lee el XML.
- Se filtra por remitente DIAN (`facturacionelectronica@dian.gov.co` u otro que confirme el primer correo real) para no procesar correos ajenos.
- La función no confía en el XML para decidir la venta: solo registra si hay **exactamente una** candidata; si no, a la bandeja.
- `fn_fe_registrar_factura_auto` solo ejecutable por `service_role`.

## Piezas (borradores en esta carpeta)
| Archivo | Qué es |
|---|---|
| `bandeja.sql` | Tabla `fe_bandeja_correo` y `fn_fe_registrar_factura_auto` |
| `recibir-factura-dian.ts` | Edge function de Supabase |
| `apps-script.gs` | Script de Gmail que envía los adjuntos |

## Pasos para activarlo (cuando se decida)
1. Confirmar con el primer correo real de la DIAN: remitente, nombre del adjunto y estructura del XML.
2. Aplicar `bandeja.sql` y desplegar la función con su huella de clave.
3. Crear el Apps Script en la cuenta de Gmail de la empresa, pegar la clave y programar el disparador cada 10 min.
4. Probar con 1–2 facturas reales; revisar la bandeja.
5. Agregar en el ERP la vista "Bandeja del correo" (lista de `revisar` con selector de venta) — pendiente de construir.

## Pendientes / riesgos
- No se ha visto un correo real de la DIAN: el remitente y el contenido exacto del ZIP pueden variar.
- Si el emisor no recibe copia del correo, hay que activar el envío al emisor en el portal de la DIAN.
- Notas crédito/débito no se procesan todavía.
