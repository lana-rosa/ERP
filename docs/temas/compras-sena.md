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

## Legalización de compras del Fondo (12-nov-2026, sw.js v44) — pedido del Orquestador, aprobado por Sara
- **Evidencia de entrega** (foto, acta o remisión, PDF o imagen): se puede subir al registrar o después en "Ver soportes de pago". Clave `evidencia_entrega` en `compras_requisitos_sena.documentos`.
- **Estado por compra**: "✅ Lista para legalizar" o "Falta: factura / comprobante de pago / extracto / evidencia de entrega" (`estadoLegalizarCompra`). El extracto sigue opcional al registrar pero cuenta como faltante.
- **Proveedor aprobado en el plan operativo**: tabla nueva `proveedores_plan_operativo` (por tercero). Aviso al registrar y en la pantalla; botón "Marcar proveedor como aprobado en el plan" (pregunta a Sara si la interventora ya lo aprobó). Proveedor nuevo sin registrar = aviso también.
- **Valor pagado vs factura**: campo "Valor que transferiste" (`datos.valor_pagado`), se puede registrar después. Si no coincide con la factura: alerta (no bloquea).
- Objetos de Supabase (SQL en `docs/migraciones/2026-11-12-soportes-fondo-legalizar.sql`): `proveedores_plan_operativo`, `fn_proveedor_plan_marcar`, `fn_proveedor_aprobado_plan`, `fn_compra_registrar_valor_pagado`, `fn_soportes_pago_fondo`, y `fn_compra_agregar_documento` ampliada.
- **Propuesto, NO hecho (punto 5)**: control por desembolso del Fondo (recibido, legalizado, saldo pendiente) reutilizando la pantalla de ingresos/desembolsos del Fondo (index.html ~l. 5638–5670, ingresos y desembolsos por concepto) y la cuenta bancaria de uso `fondo_emprender`. Idea: asociar cada compra Fondo/Mixto a un desembolso recibido; legalizado = suma de compras "listas para legalizar"; saldo = recibido − legalizado. Espera la respuesta de la interventora sobre el Formato de Solicitud de Desembolso.
