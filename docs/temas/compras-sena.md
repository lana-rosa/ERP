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
Estado: solo se guardó y revisó el documento; **no se ha tocado código**. Lo que choca con el ERP (textos "lo gira la fiducia", falta registrar comprobante y extracto) está en la tabla del resumen y en PENDIENTES.
