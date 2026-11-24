# SENA: solicitud de desembolso, pago y legalización (plan, 24-nov-2026)
Fuente: paquete del SENA «Lineamientos para solicitud de desembolso, desembolso, pago y legalización» (lineamientos 6-oct y 30-oct-2026; Anexo 1 acciones, Anexo 2 formatos Excel, Anexo 3 guía). **Los originales están en `docs/fondo-emprender/` (ver README) y las columnas de abajo son las **exactas del Excel oficial** (Fase 1 completa el 24-nov). Relacionado: `compras-sena.md`, `contabilidad-decisiones.md`.

## Ciclo
1 Solicitud (pestañas AVANCE y PAGOS de la plataforma SENA; aprueba el interventor) → 2 Desembolso (giro de la fiduciaria **solo** a la cuenta exclusiva) → 3 Pago a proveedores (desde esa cuenta, a proveedores registrados y aprobados, con trazabilidad) → 4 Legalización (obligatoria; sin legalizar no hay nuevo desembolso; actividad «Legalización desembolso X» de $0 por cada desembolso) → 5 Seguimiento.
No válido: efectivo, otra cuenta, recursos propios con reembolso posterior, proveedores no registrados, valores distintos. Cambios de proveedor, concepto o valor se aprueban **antes** de pagar. Impuestos, sanciones y recargos son del beneficiario (no se pagan con el Fondo). Nómina: cada trabajador con su comprobante de pago y la PILA del periodo.

## Formatos: estructura EXACTA del Excel oficial (Anexo 2, copia en `docs/fondo-emprender/`)
**Hoja «Solicitud desembolso»** (A1:H33). Título «SOLICITUD DE DESEMBOLSO No xxxxx». Encabezado: `ID/ Nombre proyecto` (A3), `Fecha de Solicitud` (D3), `Monto autorizado` (A4; B4 = total de E18). Tabla desde la fila 7, 10 filas (ITEM 1 a 10), columnas:
A `ITEM` · B `Actividades solicitadas` (rubro de la lista de abajo) · C `Descripción` · D `Valor total del contrato o negociacion` · E `Monto Solicitado plan de negocio` · F `Saldo por solicitar` (= D − E) · G `Observaciones /condiciones comerciales de pago` (ej. «Saldo contra entrega»). Fila 18 «T O T A L»: E = suma de E8:E17, F = suma de F8:F17. Abajo: `Firma del beneficiario`, `Firma del interventor`, y la `CLÁUSULA DE RESPONSABILIDAD Y DECLARACIÓN TRIBUTARIA` (texto fijo, copiar del original).
**Hoja «Legalización desembolso»** (C3:Q41). Título «LEGALIZACIÓN DESEMBOLSO No xxxxxxx». Encabezado: `ID/ Nombre proyecto` (C5), `Fecha de Legalización` (K5), `Valor total legalización` (C6; E6 = J20). Tabla desde la fila 8 (filas 10 a 19), columnas:
C `Actividades plan operativo` · D `ID Solicitud de pago` · E `Descripción solicitud` · F `Proveedor` · G `Factura/Doc soporte #` (F:G agrupadas como «Documento legalización») · H `Monto desembolsado` (= monto solicitado de la hoja Solicitud) · I `Saldo pendiente por solicitar según condiciones pactadas` (= saldo por solicitar de la hoja Solicitud) · J `Monto legalizado` · K `Reintegro de recursos` (= H − J) · L `Base` · M `ValorReteFuente` · N `ValorReteIVA` · O `ValorReteICA` · P `Otros descuentos` (M:P agrupadas como «Descuentos y retenciones») · Q `ValorPagado` (= Base − ReteFuente − ReteICA − ReteIVA). Fila 20 «TOTAL LEGALIZACIÓN»: sumas de H, J, K, L, M, N, O, P, Q. Notas al pie: «se debe anexar extracto o comprobante Bancario del pago realizado»; `Elaborado por beneficiario`, `Aprobado por`; cláusula de responsabilidad y declaración tributaria; «Anexar soportes de desembolso».
- Ejemplo del Excel (solo ilustrativo, no es regla): ReteFuente = Base × 2,5 %; ReteICA = Base × 11,04 por mil. Las retenciones reales de Lana Rosa las define Contabilidad (chat 7) según su condición tributaria.
- **Rubros permitidos** (hoja auxiliar, lista desplegable de «Actividades solicitadas»): Arrendamientos, Material Publicitario, Adecuaciones, Maquinaria Y Equipo, Equipos De Computo, Muebles Y Enceres, Vehiculo, Software Licencias, Materia Prima, Semovientes Y Agro, Empaques, Prestacion de servicios, Maquila, Importaciones, Nomina, Jornales, Honorarios, Licencias(invima).
- Soportes por legalización (lineamiento 6-oct, 5.4.1): (1) formato de legalización; (2) factura electrónica o equivalente que corresponda a proveedor, concepto, valor y operación (cuenta de cobro solo cuando legalmente corresponda); (3) comprobante de transferencia o de egreso **y** extracto o movimiento de la cuenta exclusiva que identifique destinatario, valor y fecha; más según el caso: recibo o acta de satisfacción, evidencia de entrega o del servicio. Nómina: cada trabajador individual con su comprobante y el soporte de seguridad social del periodo.

## Reglas nuevas del lineamiento del 6-oct que el ERP debe respetar
- Pagos parciales de un mismo contrato: en la solicitud se registra el **valor total comprometido** y las condiciones en «Observaciones/condiciones comerciales de pago»; cualquier cambio lo valida el orientador SENA y el profesional de seguimiento (si no, reintegro con GMF).
- Cambios de proveedor, concepto o valor se registran y **se aprueban antes de pagar**.
- **No válido:** pagos desde otra cuenta, con recursos propios para pedir reembolso, a proveedores no registrados, a cuentas de terceros, sin identificar proveedor/valor/fecha/destino, o en efectivo cuando no haya trazabilidad.
- **Impuestos:** ICA, GMF (4 x mil), avisos y tableros y demás impuestos, sanciones e intereses los paga el beneficiario con recursos propios (no financiables). El **IVA** solo cuenta como mayor valor si no es descontable/recuperable. Las retenciones no son gasto adicional; los documentos deben mostrar valor total, valor pagado y retenciones.
- Reintegro de saldos no ejecutados o no demostrados **incluye el GMF**.
- Legalización: actividad «Legalización desembolso X» con valor $0 por cada desembolso; aprobada la legalización se puede pedir el siguiente desembolso. Los soportes de periodos distintos no se reutilizan (facturas, comprobantes, extractos); los documentos del beneficiario vigentes no se vuelven a pedir.
- Persona natural no obligada a contabilidad: debe llevar libro fiscal y conservar soportes y comprobantes de la cuenta exclusiva.
- Los requisitos documentales por rubro están en la **matriz del Anexo 3** (solicitar vs legalizar). Ojo: el SENA aclaró por correo (24-nov) que el Anexo 3 es solo orientador y **no reemplaza el Instructivo de Pagos 2024**, que sigue siendo el documento oficial para validar requisitos y soportes; si hay diferencia, manda el Instructivo (y se confirma con la interventora). El lineamiento será cargado en la plataforma de Fondo Emprender.

## Qué ya existe en el ERP
Compras del Fondo con cuenta de pago, comprobante, extracto, evidencia de entrega, valor transferido, proveedor aprobado y estado «lista para legalizar» (`fn_soportes_pago_fondo`); calendario de entregas con alertas en LAROVA y correo; pantalla del Fondo con consignaciones recibidas y gasto por concepto; reporte de PILA; Bancolombia = solo Fondo (decisión de Contabilidad).

## Qué falta
1. Un **desembolso numerado** al que se amarren las compras (hoy solo hay consignaciones y gasto por concepto, sin número ni estado).
2. **Retenciones por pago** (base, retefuente, reteIVA, reteICA, otros): chat 7 (Contabilidad).
3. **Estados del ciclo:** solicitada, aprobada, desembolsada, pagada, legalizada, con observaciones.
4. **Excel y PDF** de los dos formatos con columnas exactas y nombres de archivo sin caracteres especiales.
5. Validación de **nómina sin PILA** al legalizar.

## Plan por fases (cada fase que toque la base se confirma con Sara antes)
- **Fase 1 (hecha):** documentos guardados y estructura exacta de los formatos copiada.
- **Fase 2:** Formato 2 «Legalización»: por desembolso, con las compras listas, en Excel y PDF.
- **Fase 3:** Formato 1 «Solicitud» (hasta 10 filas, saldo por solicitar, total).
- **Fase 4:** tablero del ciclo con estados y alertas 2 días antes (reutiliza el calendario de entregas).
- Validaciones de los 10 errores frecuentes: ya cubiertas efectivo, cuenta, proveedor aprobado, valor distinto y faltantes de soporte; pendiente nómina sin PILA.

## Lo manual en la plataforma SENA (no se automatiza)
Subir formatos y soportes en AVANCE/PAGOS, firmas del beneficiario e interventor y la aprobación del interventor.

## Coordinación
Chat 7: retenciones, extracto, informe mensual del Fondo, **Bancolombia en ceros antes del desembolso de diciembre**. Chat 4: facturas y documento soporte.
