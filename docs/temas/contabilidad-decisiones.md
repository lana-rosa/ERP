# Decisiones contables vigentes
(El detalle completo está en la KB `asistente_ia_base_conocimiento`, modulo "contabilidad"; consultar ahí.)
- Lo pagado a Sara por tejido se registra como retiros del propietario (3805); pendiente confirmar con el contador vs honorarios.
- Arriendo del local: lo paga la socia con recursos propios (aporte).
- Política: todo lo que se teje se paga como honorarios hasta abrir el local y contratar personal.
- Bancos/conciliación: decisión de oct-2026 (KB `bancos_conciliacion_decision`).
- Plan de cuentas: se deja como está; Sara preguntará al contador por los códigos CUIF de 10 dígitos (Anexo-CUIF).
- Pendientes con el contador (Hernando Franco): ver `docs/PENDIENTES.md`.

## Bancos: decisión nueva del 18-nov-2026 (PROPUESTA, sin aplicar en los libros; falta el sí de Sara)
Llegó por el Orquestador general y reemplaza la del 14-oct («no se llevan bancos porque la cuenta es compartida»):
- **Davivienda** = todo lo de Lana Rosa (ventas, gastos, proveedores, nómina).
- **Bancolombia** = SOLO los recursos del Fondo Emprender (desembolsos y pagos con soporte para legalizar).

**Cómo está hoy el ERP (leído el 18-nov):** tabla `cuentas_bancarias` tiene Bancolombia (uso "general", predeterminada, subcuenta 111005, titular Sara Loaiza) y Nequi (desactivada el 14-oct). `medios_pago_cuenta` solo asigna "nequi". Hay 0 movimientos de extracto. En libros, lo único en banco son los $13.888 de Wompi (111005); el resto de cobros pasó a Caja 1105 como efectivo.

**Propuesta para el plan de cuentas y el ERP (nada se aplica sin el sí de Sara):**
1. Crear la cuenta **Davivienda** (uso general, predeterminada) con su subcuenta 1110xx; el ERP la crea sola al agregarla en Conciliación bancaria.
2. Cambiar Bancolombia a uso **Fondo Emprender** (cuenta 1112 exclusiva) y quitarle "predeterminada". Confirmar que la Bancolombia que ya está registrada (número terminado en 7905) es la misma del Fondo.
3. Medios de pago de ventas → Davivienda: transferencia, tarjeta/datáfono, Wompi, Nequi y Daviplata (en "¿A qué cuenta llega cada medio de pago?"). Efectivo sigue a Caja.
4. Los $13.888 de Wompi (hoy en 111005): pasarlos a Davivienda con un asiento de traslado, o dejarlos si Wompi deposita ahí. **Pregunta para Sara:** ¿a cuál cuenta consigna Wompi?
5. Lo que hoy está en Caja 1105 como efectivo (cobros que en realidad entraron por Nequi, julio–septiembre: $775.000, $294.178 y $935.000): **no se toca** sin la decisión del contador; esos movimientos ya quedaron con medio de pago efectivo.
6. Saldos iniciales: cargar con el extracto de cada banco en una fecha de corte (lo que no cuadre queda en 1110 «sin asignar» para el contador).
7. Cruce con Compras SENA (chat 3): los desembolsos del Fondo entran a Bancolombia y los pagos con soporte a legalizar salen solo de Bancolombia; ningún pago de operación (ni de Davivienda) se mezcla con esa cuenta. El chat 3 ya avisa en pantalla que paga la cuenta exclusiva.

**Propuesta (no construida) de conciliación automática, para después de la apertura:** Sara sube el extracto (Excel/CSV) de cada banco; el ERP cruza cada movimiento con ventas, abonos de pedidos, gastos y pagos, y muestra tres listas: *conciliados*, *dudosos con sugerencia* y *no encontrados*, más un cuadro de saldo del banco vs. saldo del ERP por cuenta. Hoy ya existen "Importar extracto" y "Conciliar automáticamente" (mismo valor, fechas a 5 días); lo nuevo sería cruzar por referencia/tercero y sugerir. Con dos cuentas separadas tiene sentido.

**Para el contador (viernes 20-nov):** confirmar la nueva decisión de bancos y cómo tratar lo ya registrado en Caja. Se agrega a su lista en `docs/PENDIENTES.md` y en `docs/resumen-contador.md`.
Nota: el pedido citaba «la pregunta 17 de la hoja del contador (banco/conciliación)», pero en `impuestos-preguntas-contador.md` la 17 trata de agrupar líneas para el ICA; no se tocó. El tema bancos queda como pregunta nueva.

## Wompi → Nequi como cuenta puente (18-nov-2026) — PROPUESTA, sin aplicar
Dato dado por Sara vía el Orquestador general: Wompi solo desembolsa a cuentas del grupo Bancolombia y permite cambiar el desembolso a un **Nequi**. Plan: Wompi → Nequi (puente) → traslado a Davivienda (transferencia o Bre-B). Wompi sigue encendido en la página. **No se cambia nada en el ERP** hasta que Sara confirme que Wompi ya desembolsa al Nequi.

Cómo se registraría (con el sí de Sara):
1. **Cuenta propia "Nequi–Wompi (puente)"** en Conciliación bancaria, con su subcuenta (1110xx), distinta de Davivienda (operación) y de Bancolombia (Fondo Emprender). Hoy existe un Nequi desactivado desde el 14-oct (`cuentas_bancarias`, titular Sara): se reactivaría con otro nombre/uso, o se crea uno nuevo; hay que revisar que el número sea el que Wompi usará.
2. **Medio de pago Wompi** (tarjeta, PSE, QR, Nequi, otro) → cuenta Nequi puente en `medios_pago_cuenta`. Transferencia, tarjeta/datáfono y Bre-B directos → Davivienda.
3. **Comisión de Wompi:** ya la calcula el ERP; el desembolso llega neto. Se sigue usando "Desembolsos de Wompi" (sube el reporte .xlsx y ajusta diferencias de comisión).
4. **Traslado semanal** Nequi → Davivienda con la función "Traslado entre cuentas" (queda en libros, sin ingreso ni gasto).
5. **Que no se mezclen gastos personales:** ese Nequi solo para Wompi y traslados; sin pagos personales. Si no es posible, un Nequi nuevo exclusivo.
6. Los $13.888 de Wompi en 111005 (Bancolombia) pasarían a la cuenta puente.
7. Si luego se migra a ePayco/Davivienda, **la cuenta puente se cierra**: se traslada el saldo a Davivienda y se desactiva.

Preguntas nuevas para el contador (viernes 20-nov): ver `docs/PENDIENTES.md` (sección Contador).

## Mapeo de medios de pago → cuenta (respuesta de Sara, 19-nov-2026) — pendiente de aplicar
- **Bre-B** (QR de Davivienda en la tienda física, y Bre-B/llave en pedidos) → **Davivienda**.
- **Nequi manual** (el cliente paga por Nequi) → cuenta **Nequi** (no Davivienda).
- **Wompi** → Sara pidió el 18-nov a Wompi cambiar el desembolso a su Nequi (falta la aprobación de Wompi); mientras tanto sigue llegando a Bancolombia.
- Traslados Nequi → Davivienda: movimiento aparte, lo registra Contabilidad.
- **Falta para aplicarlo** (con el sí de Sara): crear la cuenta Davivienda en el ERP (necesita tipo y número), definir si el Nequi de ventas manuales y el Nequi-puente de Wompi son el mismo número, y reasignar `medios_pago_cuenta` (hoy solo existe `nequi` → Nequi inactiva 111010). Chat 2 (Pedidos) solo guarda el nombre del medio (`nequi`, `breb`); el mapeo contable lo aplica este chat.
