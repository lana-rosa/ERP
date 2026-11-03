# Pedidos por redes/WhatsApp y anticipos
- Pedido con varias líneas (cada producto es una línea; stock y costo por línea; aviso al Taller solo con lo que falta). Tabla de líneas: `docs/migraciones/2026-10-20-pedido-canal-lineas.sql`.
- Anticipo: valor libre, mínimo 50 % de los productos, atajos 50/70/100 %. `calcularAnticipoPedido` (~18698).
- **Anticipo < 50 %**: solo la administradora, con motivo; función `fn_agendar_pedido_anticipo_bajo`. KB `pedidos_anticipo_menor_50`.
- **El anticipo se cobra al crear el pedido** (método de pago y recibo en el mismo paso) — PR #96. Falta probar con el Worker real.
- OP-0036: pedido ya entregado sin orden de producción → se dejó en pedidos terminados.
Principio de Sara: el programa debe ahorrar el mayor tiempo posible al registrar.
