# SENA: solicitud de desembolso, pago y legalización (plan, 24-nov-2026)
Fuente: paquete del SENA «Lineamientos para solicitud de desembolso, desembolso, pago y legalización» (lineamientos 6-oct y 30-oct-2026; Anexo 1 acciones, Anexo 2 formatos Excel, Anexo 3 guía). **Resumen de segunda mano** (vía Orquestador general); falta copiar las columnas exactas de los Excel originales (Sara los adjunta en el chat de Compras SENA). Relacionado: `compras-sena.md`, `contabilidad-decisiones.md`.

## Ciclo
1 Solicitud (pestañas AVANCE y PAGOS de la plataforma SENA; aprueba el interventor) → 2 Desembolso (giro de la fiduciaria **solo** a la cuenta exclusiva) → 3 Pago a proveedores (desde esa cuenta, a proveedores registrados y aprobados, con trazabilidad) → 4 Legalización (obligatoria; sin legalizar no hay nuevo desembolso; actividad «Legalización desembolso X» de $0 por cada desembolso) → 5 Seguimiento.
No válido: efectivo, otra cuenta, recursos propios con reembolso posterior, proveedores no registrados, valores distintos. Cambios de proveedor, concepto o valor se aprueban **antes** de pagar. Impuestos, sanciones y recargos son del beneficiario (no se pagan con el Fondo). Nómina: cada trabajador con su comprobante de pago y la PILA del periodo.

## Formatos (columnas según resumen; confirmar con el original)
- **Formato 1 «Solicitud de desembolso No.»:** proyecto, fecha, monto autorizado; hasta 10 filas: ítem, actividad/rubro, descripción, valor total del contrato o negociación, monto solicitado del plan de negocio, saldo por solicitar, observaciones/condiciones de pago (obligatorio el valor total comprometido en pagos parciales); total; firmas del beneficiario e interventor; cláusula de responsabilidad y declaración tributaria.
- **Formato 2 «Legalización desembolso No.»:** proyecto, fecha, valor total legalizado; por actividad: ID solicitud de pago, descripción, proveedor, factura/documento soporte #, monto desembolsado, saldo pendiente por solicitar, monto legalizado, reintegro, base, retefuente, reteIVA, reteICA, otros descuentos, valor pagado; totales; elaborado por / aprobado por; anexar extracto o comprobante del pago.
- Soportes por legalización: formato, factura electrónica o equivalente (nombre, NIT, descripción, valor, fecha), comprobante de transferencia + extracto de la cuenta exclusiva (destinatario, valor, fecha), evidencia de entrega, cumplimiento tributario.

## Qué ya existe en el ERP
Compras del Fondo con cuenta de pago, comprobante, extracto, evidencia de entrega, valor transferido, proveedor aprobado y estado «lista para legalizar» (`fn_soportes_pago_fondo`); calendario de entregas con alertas en LAROVA y correo; pantalla del Fondo con consignaciones recibidas y gasto por concepto; reporte de PILA; Bancolombia = solo Fondo (decisión de Contabilidad).

## Qué falta
1. Un **desembolso numerado** al que se amarren las compras (hoy solo hay consignaciones y gasto por concepto, sin número ni estado).
2. **Retenciones por pago** (base, retefuente, reteIVA, reteICA, otros): chat 7 (Contabilidad).
3. **Estados del ciclo:** solicitada, aprobada, desembolsada, pagada, legalizada, con observaciones.
4. **Excel y PDF** de los dos formatos con columnas exactas y nombres de archivo sin caracteres especiales.
5. Validación de **nómina sin PILA** al legalizar.

## Plan por fases (cada fase que toque la base se confirma con Sara antes)
- **Fase 1 (hecha en parte):** este documento. Falta copiar columnas exactas de los Excel.
- **Fase 2:** Formato 2 «Legalización»: por desembolso, con las compras listas, en Excel y PDF.
- **Fase 3:** Formato 1 «Solicitud» (hasta 10 filas, saldo por solicitar, total).
- **Fase 4:** tablero del ciclo con estados y alertas 2 días antes (reutiliza el calendario de entregas).
- Validaciones de los 10 errores frecuentes: ya cubiertas efectivo, cuenta, proveedor aprobado, valor distinto y faltantes de soporte; pendiente nómina sin PILA.

## Lo manual en la plataforma SENA (no se automatiza)
Subir formatos y soportes en AVANCE/PAGOS, firmas del beneficiario e interventor y la aprobación del interventor.

## Coordinación
Chat 7: retenciones, extracto, informe mensual del Fondo, **Bancolombia en ceros antes del desembolso de diciembre**. Chat 4: facturas y documento soporte.
