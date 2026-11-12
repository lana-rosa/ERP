# Ventas (punto de venta)
Código: `validarAntesDeConfirmarVenta` (index.html ~7805) → `confirmarVenta` (~7891) → POST `/api/pos/ventas` del Worker (no editable).
Reglas al confirmar:
- Hay que marcar "a nombre de quién" (`feQuiere`): Consumidor final o Del cliente. Si es del cliente: nombre, cédula y correo válido.
- Marketplace: nombre, teléfono, dirección. Crédito directo: nombre y cédula.
- Modo feria: exige feria activa (`feriaActivaId`); sin datos del cliente, factura a consumidor final.
- Requiere turno de caja abierto (el de Sara está abierto desde 19-oct-2026).
- Última venta registrada: 2026-11-02. Problema abierto "no deja registrar ventas": ver `docs/PENDIENTES.md` (falta el mensaje exacto).
- Revisión 12-nov-2026 (sin el mensaje exacto, causa NO encontrada). Descartado en Supabase: turno abierto OK; `fn_registrar_venta_pos` + `fn_contabilizar_venta_pos` funcionan en una venta de prueba con rollback (efectivo, 1 ítem con stock, consecutivo POS-2026-xxxxx se genera bien); sin errores de Postgres ni de la API en las últimas 24 h (nadie intentó vender en ese lapso, o el fallo ocurre antes de llegar a Supabase: en el Worker o en el navegador). Sin el texto del error no se puede avanzar más.
- MENSAJE EXACTO (Sara, vía Orquestador, 12-nov): **"No hay turno de caja abierto."** Ese texto NO está en index.html: lo devuelve el Worker. En Supabase el turno `78de0917…` sigue `abierto` (cajero Sara, centro 01) pero lleva 24 días abierto (desde 19-oct 01:43 UTC); la última venta fue 2-nov, es decir ~14-15 días después de abrir. Ninguna función de Supabase (`fn_abrir/cerrar_turno_departamento`, etc.) limita la antigüedad del turno, así que lo más probable es que el Worker no considera "activo" un turno de más de ~2 semanas (HIPÓTESIS, no verificable: el Worker no se puede editar ni leer). Solución propuesta (pendiente de que Sara confirme, toca caja): cerrar el turno viejo con arqueo (pantalla "Cerrar turno", index.html ~5772: contar el efectivo y confirmar) y abrir uno nuevo. Recomendación a futuro: cerrar y abrir turno al menos cada semana.
Decisión: ya no se reciben pagos por Nequi ni llave Bre-B (oct-2026).
KB: modulo "Punto de Venta" (venta_tienda, turno_caja, venta_whatsapp, credito_directo_cliente…).
