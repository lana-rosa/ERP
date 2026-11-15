# Nuevo modelo de desembolsos y pagos — Fondo Emprender (SENA), 2026

Fuente: `2026-nuevo-modelo-desembolsos-y-pagos.pdf` (Actas 1634-2025, 1638 y 1639 de junio y julio 2026). Recibido el 2026-11-12.

## Qué cambió
- **Antes:** la fiducia le pagaba directo al proveedor.
- **Ahora:** fiducia → **cuenta bancaria exclusiva del beneficiario (Sara)** → Sara paga a sus proveedores.
- Más autonomía, pero más responsabilidad y trazabilidad.

## Flujo (5 etapas)
Etapa previa: registro del beneficiario (datos básicos + cuenta bancaria exclusiva). Se verifica una sola vez; no se vuelve a cargar si está vigente.
1. **Solicitud de desembolso:** se registran las actividades en la pestaña AVANCE, se cargan soportes (cotización, info del proveedor, valor, documentos técnicos/jurídicos/financieros), se diligencia el *Formato de Solicitud de Desembolso* (pestaña PAGOS) y se envía. Resultado del interventor: aprobada / rechazada para subsanar / rechazada.
2. **Desembolso:** SENA autoriza, la fiducia gira a la cuenta exclusiva. Sara verifica el valor y ejecuta según el plan operativo.
3. **Pago a proveedores:** solo a proveedores autorizados (los del plan), solo desde la cuenta exclusiva, guardando comprobantes. **No se mezcla con otros recursos (sin unidad de caja).**
4. **Legalización (obligatoria; sin ella no hay nuevos desembolsos).**
5. **Seguimiento y control:** atender requerimientos del interventor y SENA y conservar soportes.

## Soportes de la legalización (los 6)
1. Factura electrónica o documento equivalente (nombre, NIT, descripción, valor, fecha).
2. Comprobante de pago (transferencia/consignación **desde la cuenta exclusiva**).
3. **Extracto bancario** donde se vea el débito y el movimiento de la cuenta exclusiva.
4. Evidencias de entrega (fotos, actas, remisiones).
5. Cumplimiento tributario (**impuestos, sanciones y recargos los asume el beneficiario; no se financian con el Fondo**).
6. Coherencia con el plan operativo (actividades, rubros, valores y proveedores aprobados).
Adicionales según el caso: actas, contratos, informes, certificaciones, soportes técnicos.

## Errores frecuentes y consecuencia
1. Documentación incompleta → rechazo y retraso. 2. Factura inconsistente → rechazo de la legalización. 3. Pago a proveedor no registrado/diferente al aprobado → uso indebido, posible reintegro. 4. Pagar desde otra cuenta → se pierde trazabilidad, incumplimiento. 5. **Pagos en efectivo → no se aceptan, uso no permitido.** 6. Soportes de pago incompletos (sin transferencia o extracto). 7. Valor pagado distinto al aprobado o a la factura. 8. Gastar en conceptos fuera del plan operativo → desviación, reintegro y sanciones. 9. Sin evidencia de entrega. 10. No atender observaciones o pasarse de plazos → suspensión de desembolsos.
Consecuencias en escalera: requerimientos → suspensión de desembolsos → reintegro → incumplimiento contractual → no condonación.

## 10 reglas de oro
1 Solo la cuenta exclusiva. 2 Pagar solo a proveedores autorizados. 3 Conservar todos los soportes. 4 Verificar valor, proveedor y concepto antes de pagar. 5 Solicitar desembolsos a tiempo. 6 No mezclar recursos. 7 Cumplir obligaciones tributarias. 8 Mantener datos y cuenta actualizados. 9 Atender requerimientos. 10 Legalizar a tiempo.

## Cómo choca con el ERP (revisado 2026-11-12)
| Tema | Hoy en el ERP | Con el nuevo modelo |
|---|---|---|
| Quién paga | Textos dicen "el pago lo gira la fiducia a la cuenta del proveedor" (index.html, pantalla de compras ~l. 14299 y el mensaje de error de efectivo ~l. 14342) | **Sara paga** desde la cuenta exclusiva. Hay que cambiar los textos. |
| Efectivo | Bloqueado en compra "completo" con recursos del Fondo | Se mantiene y es correcto; el motivo ya no es "la fiducia gira". |
| Cuenta de pago | No se pide ni se registra desde qué cuenta se pagó | Falta registrar que el pago salió de la cuenta exclusiva y poder adjuntar **comprobante de transferencia** y **extracto**. |
| Paquete de evidencias (`generarPaqueteEvidenciasSena`) | Incluye factura, RUT, contrato, etc. | Faltan comprobante de pago y extracto como soportes de legalización. |
| Impuestos | — | Impuestos/sanciones/recargos no se pagan con recursos del Fondo: revisar que no se carguen al rubro Fondo. |
| Proveedores | Contrato por proveedor nuevo pendiente con interventora | Se refuerza: solo se paga a proveedores aprobados en el plan. |

Qué falta decidir/hacer: ver `docs/PENDIENTES.md` (bloque "Compras SENA") y `docs/temas/compras-sena.md`.
