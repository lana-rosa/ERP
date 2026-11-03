# Compras: requisitos del Instructivo de pagos del Fondo Emprender (mayo 2024 v2)
Para Fondo Emprender se cumple todo como si fuera sociedad, aunque Sara esté en SIMPLE.
- Código: `actualizarRequisitosCompra`/`validarRequisitosCompra`/`guardarRequisitosCompra` (index.html ~14257–14348). Tabla `compras_requisitos_sena`.
- 1 cotización por compra es suficiente (confirmado por la interventora); se pide solo el motivo de la elección.
- Factura a nombre de la empresa, foto/PDF de la factura obligatorio (opcional si el proveedor no factura y se usa documento soporte), RUT del proveedor, contrato y póliza según tipo, fuente de recursos, actividad del plan operativo, logos.
- Validar documentos (Fondo Emprender, ~l. 5524): alineado al instructivo (PR #82), `fn_validar_documento_fe`.
- Paquete de evidencias: `generarPaqueteEvidenciasSena` (~31684).
KB: `compras_requisitos_instructivo_sena` y todas las `fondo_emprender_*`.
Pendiente con la interventora: contrato para cada proveedor nuevo; aprobación del lugar de operaciones y plan operativo; informes (bimestral 2-dic-2026, mensuales).
