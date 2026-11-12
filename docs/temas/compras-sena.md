# Compras: requisitos del Instructivo de pagos del Fondo Emprender (mayo 2024 v2)
Para Fondo Emprender se cumple todo como si fuera sociedad, aunque Sara esté en SIMPLE.
- Código: `actualizarRequisitosCompra`/`validarRequisitosCompra`/`guardarRequisitosCompra` (index.html ~14257–14348). Tabla `compras_requisitos_sena`.
- 1 cotización por compra es suficiente (confirmado por la interventora); se pide solo el motivo de la elección.
- Factura a nombre de la empresa, foto/PDF de la factura obligatorio (opcional si el proveedor no factura y se usa documento soporte), RUT del proveedor, contrato y póliza según tipo, fuente de recursos, actividad del plan operativo, logos.
- Validar documentos (Fondo Emprender, ~l. 5524): alineado al instructivo (PR #82), `fn_validar_documento_fe`.
- Paquete de evidencias: `generarPaqueteEvidenciasSena` (~31684).
KB: `compras_requisitos_instructivo_sena` y todas las `fondo_emprender_*`.
Pendiente con la interventora: contrato para cada proveedor nuevo; aprobación del lugar de operaciones y plan operativo; informes (bimestral 2-dic-2026, mensuales).

## Nuevo modelo de desembolsos y pagos (recibido 2026-11-12)
Documento guardado en `docs/fondo-emprender/` (PDF + resumen). Cambio clave: la fiducia ya no paga al proveedor; **gira a la cuenta exclusiva de Sara y ella paga**, solo desde esa cuenta, sin efectivo y sin mezclar con otros recursos. La legalización es obligatoria y pide factura, comprobante de transferencia, **extracto bancario**, evidencias de entrega, cumplimiento tributario y coherencia con el plan.
**Hecho en el ERP (sw.js v38):** textos corregidos (paga Sara desde la cuenta exclusiva; impuestos no se pagan con el Fondo). Con fuente Fondo/Mixto y "Pagado completo": solo transferencia o tarjeta débito (se bloquean efectivo, Daviplata y tarjeta crédito), comprobante de transferencia PDF obligatorio y extracto PDF opcional. Se guardan en `compras_requisitos_sena.documentos` (claves `comprobante_pago`, `extracto_bancario`), sin cambios en Supabase. Funciones: `actualizarBloquePagoFondo`, `validarRequisitosCompra`.
**Pantalla de soportes (sw.js v39):** en Compras, botón "Ver soportes de pago de las compras con recursos del Fondo" (`verSoportesPagoFondo`, `abrirSoporteCompra`, `subirSoportePagoFondo`): lista las compras Fondo/Mixto del rango, abre cada documento y deja subir el comprobante o extracto que falte. Usa la función de Supabase `fn_compra_agregar_documento` (solo administradora; claves permitidas `comprobante_pago` y `extracto_bancario`; SQL en `docs/migraciones/2026-11-12-compra-agregar-documento.sql`).
Falta: respuesta de la interventora sobre el Formato de Solicitud de Desembolso.
