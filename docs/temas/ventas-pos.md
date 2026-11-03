# Ventas (punto de venta)
Código: `validarAntesDeConfirmarVenta` (index.html ~7805) → `confirmarVenta` (~7891) → POST `/api/pos/ventas` del Worker (no editable).
Reglas al confirmar:
- Hay que marcar "a nombre de quién" (`feQuiere`): Consumidor final o Del cliente. Si es del cliente: nombre, cédula y correo válido.
- Marketplace: nombre, teléfono, dirección. Crédito directo: nombre y cédula.
- Modo feria: exige feria activa (`feriaActivaId`); sin datos del cliente, factura a consumidor final.
- Requiere turno de caja abierto (el de Sara está abierto desde 19-oct-2026).
- Última venta registrada: 2026-11-02. Problema abierto "no deja registrar ventas": ver `docs/PENDIENTES.md` (falta el mensaje exacto).
Decisión: ya no se reciben pagos por Nequi ni llave Bre-B (oct-2026).
KB: modulo "Punto de Venta" (venta_tienda, turno_caja, venta_whatsapp, credito_directo_cliente…).
