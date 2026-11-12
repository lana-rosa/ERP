# Pendientes ERP / CRM

Actualizado: 2026-11-03

## Para revisar con Claude
- [ ] **No deja registrar ventas** (reportado 03-nov). Falta el mensaje exacto que sale al dar "Confirmar venta" (texto o captura). Revisar: factura "Consumidor final / Del cliente" (si es del cliente: nombre, cédula, correo válido), marketplace (nombre, teléfono, dirección), feria activa en modo feria, productos agotados, turno de caja (abierto desde 19-oct), respuesta del Worker.
- [x] Menú lateral oculto sin forma de volver a mostrarlo (PR #100, resuelto).

## Sara
- [ ] Excel de gramos por orden
- [ ] Servicios públicos y arriendo de octubre (fecha 2026-10-05)
- [ ] Arqueo físico de caja (última referencia $1.353.066)
- [ ] Fecha de inauguración del almacén (activa la provisión mensual de impuestos)
- [ ] Cambiar los 3 códigos de barras internos por GS1
- [ ] Asignar tejedoras y horas en el plan de tejido
- [ ] Llenar fichas técnicas de insumos
- [ ] Registrar resolución de numeración, numeración de documento soporte y primer respaldo mensual

## Contador (Hernando)
- [ ] UVT y tarifas SIMPLE, escenario de provisión, tabla de renta
- [ ] Verificar ICA Villamaría
- [ ] Códigos CUIF de 10 dígitos: qué quiere hacer
- [ ] Aplicabilidad del documento soporte
- [ ] Retenciones, libros y declaraciones como sociedad
- [ ] Pendientes viejos: retiros 3805 vs honorarios, aportes vs deuda, arriendo mayo/junio, confirmación escrita de 27 recibos, medio de pago de 17 ventas antiguas

## Interventora
- [ ] Aprobación del lugar de operaciones y plan operativo
- [ ] Contrato para cada proveedor nuevo
- [ ] Informes: bimestral (2-dic-2026), mensuales de producción, ventas y estados financieros, 5 contrapartidas

## Compras SENA — nuevo modelo de pagos (12-nov-2026)
- [ ] Cambiar textos de compras que dicen "el pago lo gira la fiducia al proveedor": ahora paga Sara desde la cuenta exclusiva (index.html ~l. 14299 y ~14342)
- [ ] Registrar en cada compra con recursos del Fondo el comprobante de transferencia y el extracto, e incluirlos en `generarPaqueteEvidenciasSena`
- [ ] Preguntar a la interventora: ¿el Formato de Solicitud de Desembolso y la pestaña AVANCE/PAGOS aplican ya a nuestro proyecto?

## Opcionales (Claude, si se pide)
- [ ] Enlazar soporte de compras a crédito
- [ ] Soporte para facturas manuales antiguas
- [ ] Ingesta de facturas por correo (solo borrador)
- [ ] Probar sincronización CRM↔ERP y pedidos de la tienda virtual
- [ ] Probar cobro de anticipo con el Worker real
- [ ] Borrar edge functions sin uso y columnas/función antiguas en Supabase
