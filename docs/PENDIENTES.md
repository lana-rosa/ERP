# Pendientes ERP / CRM

Actualizado: 2026-11-12 (Orquestador)

> **Regla para los chats:** cada chat edita **solo su sección** (y marca con [x] lo que cierre, con fecha y PR). El orden de trabajo lo pone el Orquestador. No empieces algo de "En cola" hasta que el chat anterior haya publicado en `main`.

## Fechas límite
- **2-dic-2026:** informe bimestral a la interventora (empezar la semana del 23-nov; necesita ventas y estados financieros al día).
- Informes mensuales (producción, ventas, estados financieros): fecha por confirmar con la interventora.
- Respaldo mensual de facturación electrónica (desde oct-2026).

## Orden de trabajo (turnos)
Dos chats no deben cambiar `index.html` en la misma zona a la vez.
1. **Chat 1 Ventas** — bloqueado esperando el mensaje del error (Sara).
2. **Chat 2 Pedidos** — en curso: textos legales en recibos → luego lote de pedidos (ver su sección).
3. **Chat 3 Compras SENA** — en curso: ajustes del nuevo modelo de desembolsos (zona Compras, no choca con el chat 2).
4. **Chat 6 Producción** — en cola: empieza **cuando el chat 2 publique** su lote de pedidos.
5. **Chat 8 Menú/Interfaz** — en cola (aún no creado): buscadores. Falta que Sara diga en qué pantallas.
- Chat 4 DIAN: espera datos de Sara. Chat 5 Impuestos: espera el "sí" de Sara para fusionar.

## Por chat

### Chat 1 · Ventas
- [ ] 🔴 **No deja registrar ventas** (desde 03-nov). Falta el mensaje exacto o captura al dar "Confirmar venta". Revisar: "a nombre de quién", marketplace, feria activa, agotados, turno de caja (abierto desde 19-oct), respuesta del Worker.

### Chat 2 · Pedidos y anticipos (enviado 12-nov, en este orden)
- [x] Recibos: el texto de cambios/retracto/garantía respeta saltos de línea y va alineado a la izquierda (venta y anticipo).
- [x] (hecho; falta que Sara pegue el texto) Nuevo campo "Anticipos y cancelación de pedidos personalizados" (en Supabase), solo en recibo de anticipo y en el mensaje del pedido antes de pagar.
- [x] 🔴 Recibo dice "pendiente de pago" aunque el anticipo se cobró al crear el pedido.
- [x] 🔴 Se abren 2 órdenes de producción para el mismo pedido de un solo producto (hecho: bloqueo en Supabase). **Sara decide:** hoy hay 1 duplicada, PED-2026-00555 → OP-0037 (en proceso) y OP-0038 (terminada); no se borró.
- [x] Pedido entregado/despachado debe salir de órdenes de producción (la orden "en proceso" no se cierra sola: se avisa).
- [x] Número del pedido en el mensaje de WhatsApp y en la imagen del recibo.
- [x] Editar datos del cliente en un pedido ya registrado.
- [x] Cambiar el valor del domicilio (recalcular saldo).
- [x] 12-nov: pedido de varios productos ahora permite abrir una orden por producto (Pedidos por elaborar). Sara decidió (12-nov): OP-0046 de PED-2026-00565 se deja como orden única de los 4 productos. Cerrado: OP-0037 (duplicada de OP-0038, PED-2026-00555) anulada con motivo, sin borrar.
- [ ] Probar el cobro de anticipo con el Worker real (3 dudas abiertas, sobre todo si cobra el anticipo ajustado).

### Chat 3 · Compras SENA (enviado 12-nov)
- [x] Textos: paga Sara desde la cuenta exclusiva; sin efectivo (12-nov, PR #103).
- [x] Comprobante de transferencia obligatorio y extracto opcional (12-nov, PR #103).
- [x] Pantalla de soportes de pago del Fondo (12-nov, PR #104).
- [ ] Evidencia de entrega (foto/acta/remisión).
- [ ] Estado por compra: "lista para legalizar" / "falta: …".
- [ ] Aviso si el proveedor no está aprobado en el plan operativo.
- [ ] Aviso si el valor pagado ≠ valor de la factura.
- [ ] Control por desembolso: recibido, legalizado, saldo (depende de la respuesta de la interventora).
- [ ] Probar con archivos reales.

### Chat 4 · Facturación DIAN
- [ ] Registrar resolución de numeración (espera datos de Sara: número, fecha, prefijo, rango, vigencia, fecha de habilitación), numeración de documento soporte y primer respaldo mensual.

### Chat 5 · Impuestos
- [ ] Cambio listo esperando el "sí" de Sara para fusionar.
- [ ] Provisión mensual en espera de la fecha de inauguración del almacén.

### Chat 6 · Producción e inventario (en cola, después del chat 2)
- [ ] La administradora asigna cada pedido/orden a una tejedora (reusar tejedoras del plan de tejido).
- [ ] Pedidos personalizados: subir hasta 3 imágenes de referencia visibles en la orden de producción.
- Revisión 12-nov: 8 agotados sin mínimo, 3 bajo mínimo, 32 productos sin horas por unidad, llaveros de pollo sin tejedora.

### Chat 7 · Contabilidad (no creado)
- Sin tareas de código. Ver preguntas al contador.

### Chat 8 · Menú/Interfaz (no creado, en cola)
- [ ] Buscadores: solo la caja de búsqueda; la lista aparece al escribir. Falta: ¿en qué pantallas?
- [x] Menú lateral oculto sin forma de volver a mostrarlo (PR #100).

## Sara
- [ ] 🔴 Mensaje exacto/captura del error de ventas → chat 1.
- [ ] Decidir el "sí" del chat 5 (Impuestos).
- [ ] Datos de la resolución DIAN → chat 4.
- [ ] Pegar en Políticas legales los textos de la abogada (cambios y anticipos) cuando el chat 2 publique; revisar que la tienda web diga lo mismo.
- [ ] Decir en qué pantallas están los buscadores a cambiar.
- [ ] Servicios públicos y arriendo de octubre (atrasado, fecha 2026-10-05).
- [ ] Arqueo físico de caja (última referencia $1.353.066).
- [ ] Fecha de inauguración del almacén.
- [ ] Excel de gramos por orden.
- [ ] Cambiar los 3 códigos de barras internos por GS1.
- [ ] Asignar tejedoras y horas en el plan de tejido.
- [ ] Llenar fichas técnicas de insumos.
- [ ] Certificación bancaria de la cuenta exclusiva del Fondo (si no la tiene).

## Interventora
- [ ] ¿El Formato de Solicitud de Desembolso y las pestañas AVANCE/PAGOS ya aplican a nuestro proyecto? ¿La cuenta exclusiva ya está validada?
- [ ] Fecha de los informes mensuales.
- [ ] Aprobación del lugar de operaciones y plan operativo.
- [ ] Contrato para cada proveedor nuevo.
- [ ] Informes: bimestral (2-dic-2026), mensuales, 5 contrapartidas.

## Abogada
- [ ] ¿Se puede decir "anticipo de **al menos** el 50 %"? (el ERP permite 50/70/100 % y menos con autorización).

## Contador (Hernando)
- [ ] Impuestos no se pagan desde la cuenta del Fondo; cómo registrar los giros del Fondo (cuenta exclusiva, sin mezclar).
- [ ] UVT y tarifas SIMPLE, escenario de provisión, tabla de renta.
- [ ] Verificar ICA Villamaría.
- [ ] Códigos CUIF de 10 dígitos.
- [ ] Aplicabilidad del documento soporte.
- [ ] Retenciones, libros y declaraciones como sociedad.
- [ ] Viejos: retiros 3805 vs honorarios, aportes vs deuda, arriendo mayo/junio, confirmación escrita de 27 recibos, medio de pago de 17 ventas antiguas.

## Opcionales (Claude, si se pide)
- [ ] Enlazar soporte de compras a crédito
- [ ] Soporte para facturas manuales antiguas
- [ ] Ingesta de facturas por correo (solo borrador)
- [ ] Probar sincronización CRM↔ERP y pedidos de la tienda virtual
- [ ] Borrar edge functions sin uso y columnas/función antiguas en Supabase
