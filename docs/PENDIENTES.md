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
5. **Chat 8 Menú/Interfaz** — hecho: barra de búsqueda en celular + buscadores de Productos y Clientes (v44).
- Chat 4 DIAN: espera datos de Sara. Chat 5 Impuestos: preguntas para el contador listas (PR #113).

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
- [x] Resolución de numeración registrada (12-nov-2026): N° 18764117094883, prefijo LRCT, rango 1–100.000, habilitada desde 14-oct. Falta anotar su vigencia (no salía en la captura de la DIAN).
- [ ] Numeración de documento soporte y primer respaldo mensual (Sara).
- [ ] Emitir en la DIAN las 7 facturas marcadas "facturar" ($601.000: PED-2026-00541, 545, 549, 553, 554, 555, 550) y registrarlas en Por facturar.
- Revisión 12-nov de ventas sin factura desde el 14-oct: 14 ventas, $2.821.200 (7 con "facturar" definido, $601.000; 6 del punto de venta POS-2026-00016 a 00021, $2.205.000, y PED-2026-00559, $15.200, sin definir).

### Chat 5 · Impuestos
- [x] 12-nov: lista de 22 preguntas para Hernando con los números del ERP, en `docs/temas/impuestos-preguntas-contador.md` (PR #113). Sara dio el "sí".
- [ ] Provisión mensual en espera de la fecha de inauguración del almacén.

### Chat 6 · Producción e inventario (en cola, después del chat 2)
- [x] La administradora asigna cada pedido/orden a una tejedora (reusa tejedoras del plan; v43).
- [x] Hasta 3 imágenes de referencia visibles en la orden de producción (se suben en la orden, v43).
- [x] Insumos automáticos al abrir la entrega de material (ficha técnica → última orden terminada); no mueve inventario hasta "Entregar".
- [x] Patrones: enlaces de Telegram en la ficha técnica + botón "Ver patrón" en la orden.
- [x] Llaveros sin tejedora: asignados (Jennifer: pollos y frailejón; Sara: el resto), 0,6 h provisional. OP-0046 partida (OP-0051 frailejón → Jennifer).
- [ ] Sara: medir horas reales por llavero (las 0,6 h son provisionales).
- [ ] Sara: pegar en cada ficha técnica el enlace Telegram de su patrón y llenar fichas faltantes.
- Revisión 12-nov: 8 agotados sin mínimo, 3 bajo mínimo, 32 productos sin horas por unidad, llaveros de pollo sin tejedora.

### Chat 7 · Contabilidad (no creado)
- Sin tareas de código. Ver preguntas al contador.
- [x] Resumen de pendientes contables listo para llevarle a Hernando: `docs/resumen-contador.md` (llevarlo junto con las 22 preguntas del chat 5) — 12-nov-2026

### Chat 8 · Menú/Interfaz
- [ ] 🔴 Mudanza a Cloudflare Pages: **bloqueo** — el Worker de ventas solo acepta el origen github.io. Falta decisión de Sara (editar Worker o función proxy en Pages). Detalle en `docs/temas/hosting.md`. Ya revisado: rutas, funciones Supabase, Auth.
- [x] 🔴 Sin sesión se veía el ☰ y se abría el menú (13-nov): corregido, nada visible sin iniciar sesión.
- [x] 🔴 Supabase: 5 tablas con política abierta a cualquiera con la llave pública: cerradas 13-nov con el "sí" de Sara (ver menu-lateral.md).
- [x] Buscadores de **Productos** (Gestionar inventario) y **Clientes**: al entrar solo la caja; la lista aparece al escribir.
- [x] Celular: la barra de búsqueda ya no queda por encima del fondo oscuro del menú, no tapa la barra rosada y el texto cabe.
- [x] Menú lateral oculto sin forma de volver a mostrarlo (PR #100).

## Sara
- [ ] 🔴 Mensaje exacto/captura del error de ventas → chat 1.
- [ ] Decidir el "sí" del chat 5 (Impuestos).
- [x] Datos de la resolución DIAN → chat 4 (entregados 12-nov; falta la vigencia).
- [ ] Pegar en Políticas legales los textos de la abogada (cambios y anticipos) cuando el chat 2 publique; revisar que la tienda web diga lo mismo.
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
- [ ] UVT y tarifas SIMPLE, escenario de provisión, tabla de renta — lista de 22 preguntas en `docs/temas/impuestos-preguntas-contador.md`. Faltan: UVT 2026 confirmada y tarifas SIMPLE 2026/2027 (hoy 0 cargadas).
- [ ] Verificar ICA Villamaría (preguntas 15–19 del mismo archivo).
- [ ] Códigos CUIF de 10 dígitos.
- [ ] Aplicabilidad del documento soporte.
- [ ] Ventas desde el 14-oct-2026 (ya facturadora electrónica) que quedaron solo con recibo del ERP, sin factura electrónica: 6 del punto de venta (POS-2026-00016 a 00021, $2.205.000) y 1 pedido (PED-2026-00559, $15.200, parece prueba). Además 7 pedidos con "facturar" definido a consumidor final ($601.000). Pregunta: ¿se emite factura electrónica extemporánea a consumidor final por cada una, o cómo se regulariza? (12-nov-2026)
- [ ] Retenciones, libros y declaraciones como sociedad.
- [ ] Viejos: retiros 3805 vs honorarios, aportes vs deuda, arriendo mayo/junio, confirmación escrita de 27 recibos, medio de pago de 17 ventas antiguas.

## Opcionales (Claude, si se pide)
- [ ] Enlazar soporte de compras a crédito
- [ ] Soporte para facturas manuales antiguas
- [ ] Ingesta de facturas por correo (solo borrador)
- [ ] Probar sincronización CRM↔ERP y pedidos de la tienda virtual
- [ ] Borrar edge functions sin uso y columnas/función antiguas en Supabase
