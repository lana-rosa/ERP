# Pedidos por redes/WhatsApp y anticipos
- Pedido con varias líneas (cada producto es una línea; stock y costo por línea; aviso al Taller solo con lo que falta). Tabla de líneas: `docs/migraciones/2026-10-20-pedido-canal-lineas.sql`.
- Anticipo: valor libre, mínimo 50 % de los productos, atajos 50/70/100 %. `calcularAnticipoPedido` (~18698).
- **Anticipo < 50 %**: solo la administradora, con motivo; función `fn_agendar_pedido_anticipo_bajo`. KB `pedidos_anticipo_menor_50`.
- **El anticipo se cobra al crear el pedido** (método de pago y recibo en el mismo paso) — PR #96. Falta probar con el Worker real.
- OP-0036: pedido ya entregado sin orden de producción → se dejó en pedidos terminados.
- **Política de anticipos y cancelación de pedidos personalizados** (texto de la abogada, vía Orquestador, 12-nov-2026): columna `configuracion_empresa.politica_anticipos` (Supabase, no el Worker; lectura todos, escritura solo administradora por RLS). Se edita en Políticas legales (`guardarPoliticaAnticipos`). Sale SOLO en el recibo de anticipo (`generarContenidoReciboPedido`, imagen de WhatsApp incluida) y en el resumen del pedido que se envía antes de pagar (botón `enviarResumenPedidoWhatsapp` en el formulario de pedido). No sale en recibos de venta. Migración: `docs/migraciones/2026-11-12-politica-anticipos.sql`. **Falta:** que Sara pegue el texto de la abogada (el campo está vacío).
- **Recibos**: el texto de `politica_cambios` ahora respeta saltos de línea (`white-space:pre-line`) y va alineado a la izquierda (recibo de venta y de pedido/anticipo).
Principio de Sara: el programa debe ahorrar el mayor tiempo posible al registrar.
