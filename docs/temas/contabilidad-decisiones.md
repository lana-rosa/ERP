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

## Plan tras la reunión con el contador y la interventora (24-nov-2026) — PROPUESTA
Orden y esfuerzo (P=pequeño, M=mediano, G=grande). Todo lo que toque libros o base de datos es 🔴 y necesita el sí de Sara.
1. Catálogo de cuentas visible para el contador (el PUC ya está en Impuestos, PUC y ajustes → Plan de cuentas; falta vista de solo lectura + Excel/PDF si no lo tiene): **P**.
2. Informe de gastos y compras por categoría con fecha inicio y fin (Excel/PDF): **P–M**.
3. Cargar facturas electrónicas de compras y gastos (XML/PDF de la DIAN; borrador para revisar, como las ventas): **G**.
4. Documento soporte electrónico DIAN: depende del Chat 4 (DIAN) y de los datos de la resolución: **M**.
5. Conciliación con extracto en PDF: hoy el ERP importa Excel/CSV; PDF es más frágil: **G**, después de la apertura; Fondo solo pide Bancolombia.
6. Libro fiscal y contabilidad de microempresa: preguntar al contador qué libros exige: **M**.
7. Informes mensuales para el Fondo (Estado de situación financiera + Estado de resultados + extracto + conciliación solo del Fondo, PDF con nombre sin caracteres especiales): ya existen los estados con PDF; falta paquete mensual por cuenta del Fondo: **M**.
8. Salario de Sara como empleada (no anticipo ni retiro 3805): cambia la decisión del 14-oct; 🔴 requiere confirmación escrita del contador (prestaciones, seguridad social, nómina) y avisar al Chat 9: **M**.
9. Nómina electrónica obligatoria: ya hay módulo; revisar que cubra a Sara una vez decidido el punto 8: **P–M**.
10. Soportes de pagos y seguridad social con lugar para adjuntar (enlace al Drive): **P–M**.
Fechas: 1.er informe a la plataforma SENA (actividad 98) del 1 al 8 de cada mes; arranque domingo 6-dic → propuse lunes 7-dic, pero el Chat 3 informa (24-nov, aprobado por Sara en su chat) que el informe de noviembre se sube el **viernes 4-dic-2026** (ya en el calendario del ERP con alerta 2 días antes) y los siguientes el **día 5 de cada mes o el siguiente hábil**: queda esa fecha. Bimestral nov+dic: 2-ene-2027 es sábado y el 1-ene festivo → **jueves 31-dic** (o lunes 4-ene si la interventora lo permite).
Alerta: la reunión dice honorarios del contador $350.000 al mes; la propuesta del 30-sep decía $600.000. Confirmar cuál quedó.

### Hecho el 24-nov-2026 (puntos 1, 2 y 7 del plan; solo lectura, sin cambios en libros ni base de datos; sw v87)
- **1. Catálogo para el contador:** Impuestos, PUC y ajustes → Plan de cuentas → botón «Catálogo para el contador (Excel)»: código, nombre, nivel, naturaleza, recibe movimientos, activa, la usa el sistema, nota.
- **2. Gastos y compras por categoría:** Estados financieros → «Gastos y compras por categoría», con fecha inicio y fin. Sale del Libro Diario (`fn_libro_diario`): gastos = cuentas 51, 52 y 53; compras = cuentas 14 y 15, sin las salidas de inventario del POS; las reversiones restan. Resumen por cuenta + detalle, Excel (2 hojas) y PDF. Límite de 3.000 movimientos (avisa). La «categoría» es la cuenta del PUC; el campo `categoria` de `gastos_departamentales` solo tiene 2 valores hoy.
- **7. Informe mensual del Fondo:** Estados financieros → «Informe mensual del Fondo»: elige el mes y junta el Estado de situación financiera (Balance General al último día) y el Estado de resultados del mes. Excel (2 hojas) y PDF con nombre `LanaRosa_Informe_mensual_Fondo_AAAA-MM` (sin caracteres especiales). **Falta:** el extracto bancario y la conciliación solo del Fondo (Bancolombia) no entran todavía; se hacen en Conciliación bancaria cuando la cuenta del Fondo esté configurada.
- Probado con Playwright (datos simulados): cálculo de gastos/compras con reversión, informe del mes, nombres de archivo y títulos de PDF. Sin probar contra datos reales del contador.

### Punto 10 hecho (24-nov-2026): soportes de pagos y seguridad social del mes (sw v88)
- **Dónde:** Contabilidad → Panel del contador → sección «📎 Soportes de pagos y seguridad social del mes» (sigue el mes elegido arriba).
- **Cómo:** botón «+ Adjuntar soporte (enlace al Drive)»: tipo (pago de nómina, pago de honorarios, seguridad social/PILA, otro), enlace https, descripción y valor opcionales. Lista de verificación: ✅ si hay soporte de nómina/honorarios y de seguridad social del mes; ⚠️ si el mes terminó y falta. «Cambiar enlace» corrige un enlace; no hay botón de borrar (nada se borra).
- **Base de datos:** tabla nueva `soportes_mensuales_contables` (mes, tipo, descripcion, enlace, valor; el enlace debe empezar por https y el mes por día 1), con RLS solo para administrador y contador. SQL en `docs/migraciones/2026-11-24-soportes-mensuales-contables.sql`.
- **Probado:** SQL con rollback (insert como administrador; enlace `javascript:` y mes que no es día 1 rechazados) y Playwright (lista, enlaces seguros, alta con prompts, rechazo de http). Los soportes de pagos de compras/gastos siguen en la foto del comprobante de cada gasto.
- **Falta:** que el informe mensual del Fondo muestre estos enlaces; guardar archivos dentro del ERP (hoy solo enlaces al Drive).

### Punto 3, etapa 1 hecha (24-nov-2026): facturas electrónicas de compras, solo lectura (sw v89)
- **Dónde:** Facturación y nómina electrónica → pestaña «🛒 Facturas de compras» (visible para administrador y contador). Botón «Subir facturas de compras (ZIP o XML)».
- **Qué hace:** abre el ZIP de la DIAN, lee el XML (misma función `leerFacturaXmlDian` de ventas, ampliada con proveedor, NIT, subtotal e IVA) y muestra un borrador por factura. Clasifica: Nueva · Repetida en el lote (mismo CUFE) · Ya registrada (proveedor+número en la tabla de compras de requisitos SENA) · Es una venta de Lana Rosa · A nombre de otro NIT · Prueba/error. Excel de los borradores. **No escribe nada en la base de datos ni en los libros.**
- **Probado** (Playwright, 7 XML simulados en un ZIP): las 7 clasificaciones salieron bien y no hubo errores. Sin probar con ZIP reales de proveedores.
- **Etapa 2 (pendiente, necesita el sí de Sara):** confirmar cada borrador con categoría y centro de costo y registrarlo como gasto/compra con su asiento (toca contabilidad; hay que mirar cómo se registra hoy una compra en el Worker). **Etapa 3:** carpeta vigilada para compras (separar por NIT comprador).

### Punto 3, etapa 2 hecha (24-nov-2026): del borrador al formulario de «Registrar compra» (sw v90)
- **Decisión de diseño:** la etapa 2 NO registra por su cuenta. Registrar una compra hoy pasa por el Worker (`/api/pos/compras`, que no se puede editar desde aquí) y por reglas de dinero y del SENA/Fondo (autorización por monto, quién aprobó, cómo se pagó y de qué caja o cuenta sale, fuente propios/Fondo, cotización, comprobante, extracto, evidencia de entrega). Duplicar eso en el cliente sería peligroso. Por eso cada borrador «Nueva» tiene el botón «Registrar compra →» que abre el formulario normal con los datos de la factura ya puestos (proveedor y NIT, número, fecha, monto, descripción, PDF de la factura si el ZIP lo traía; selecciona al proveedor si ya está en el directorio por NIT). La persona completa lo demás y toca «Registrar compra»; todas las validaciones de siempre aplican.
- **Sin cambios en base de datos.** Después de registrar, la factura sale como «Ya registrada» (se detecta por proveedor+número en la tabla de requisitos del SENA). No se guarda el CUFE de la factura de compra (si se quiere, sería una columna nueva; pendiente de decidir).
- **Probado** (Playwright, datos simulados): el formulario se llena con los datos de la factura, selecciona al proveedor existente por NIT y adjunta el PDF del ZIP. **Sin probar** contra el Worker real ni con ZIP reales.
- **Etapa 3 (pendiente):** carpeta vigilada para compras (separar por NIT comprador); guardar el CUFE; notas crédito de compras.

### Davivienda creada en el ERP (24-nov-2026, con el sí de Sara)
- **Aclaración de Sara:** Davivienda es la cuenta de la tienda (operación; el QR de Bre-B de Davivienda recibe los pagos de la tienda física); **Bancolombia es la cuenta exclusiva del Fondo Emprender**. El certificado de Davivienda a nombre de «SENA – Fondo Emprender» es solo un soporte de la cuenta.
- **Hecho** (con las funciones oficiales `fn_bancos_crear_cuenta` y `fn_bancos_asignar_medio`): cuenta «Davivienda ahorros» (ahorros fijo diario, titular Sara Loaiza Muñoz, abierta 24-09-2026, saldo inicial $0), subcuenta contable **111015**, uso «general», **no predeterminada**. Solo el medio **Bre-B** (`breb`) quedó asignado a ella.
- **No se tocó** (a propósito): Wompi, transferencia y tarjeta; la cuenta predeterminada (sigue Bancolombia 111005); pagos ya registrados.
- **Por hacer cuando Wompi apruebe el cambio de cuenta (o se defina otra pasarela), con el sí de Sara:** asignar Wompi, transferencia y tarjeta; dejar Davivienda como predeterminada; pasar los $13.888 de Wompi; y **cambiar Bancolombia a uso «Fondo Emprender»** (hoy figura como «general» y predeterminada). También se vio que el Nequi quedó **activo** otra vez (se había desactivado el 14-oct): confirmar con Sara si se deja así.

### 🔴 Cuenta Bancolombia en ceros antes del desembolso del Fondo (nota del 24-nov-2026)
- **Dato (Fondo Emprender, vía Jennifer):** la cuenta Bancolombia/Wompi actual debe estar **en ceros** cuando lleguen los recursos del Fondo. No hay desembolsos hasta diciembre. Mientras no se cambie la cuenta de Wompi, esa cuenta sigue recibiendo pagos de clientas.
- **Propuesta (sin aplicar):** (1) recordatorio en el Panel del contador (tabla `obligaciones_contador`, con alerta a 10 días y en rojo si vence): «Vaciar y conciliar la cuenta Bancolombia antes del desembolso del Fondo», con fecha propuesta **1-dic-2026** (se corrige cuando el Fondo confirme el día); (2) antes de esa fecha: pasar a Davivienda todo lo que sea de Lana Rosa con «Traslado entre cuentas» (queda en libros y con su descripción), y guardar el soporte de cada movimiento (comprobante o extracto, enlace en «Soportes del mes»); (3) conciliar Bancolombia hasta dejarla en cero y sin movimientos de operación; (4) los informes para el Fondo ya salen del Estado de situación y de resultados; falta que traigan **solo** los movimientos de la cuenta del Fondo (junto con el extracto y la conciliación de esa cuenta). Eso es parte del punto 7 pendiente.
- **Relación con Wompi:** mientras Wompi consigne a Bancolombia, cada pago de clienta entra a la cuenta que debe quedar en ceros; por eso el cambio de cuenta de Wompi es urgente o hay que ofrecer transferencia/Bre-B a Davivienda en la página.

### Respuestas de Sara del 24-nov (tarde) — cambian el mapa de bancos
- **Transferencias de clientas:** siguen llegando a la cuenta **Nequi**; **Nequi se deja activo**. Bancolombia es solo del Fondo Emprender.
- **Davivienda (dato nuevo):** Sara la deja como su **cuenta personal** (para recibir su nómina y manejar su dinero). Esto contradice lo anotado el 18-nov (Davivienda = operación) y que el QR de Bre-B de Davivienda recibe los pagos de la tienda. **Pregunta abierta para Sara y el contador:** si el QR de Bre-B de la tienda sigue en Davivienda, esos pagos entran a una cuenta personal (mezcla operación con lo personal): ¿se cambia el QR a Nequi/otra cuenta de la operación, o se registra cada pago como aporte/retiro? Mientras tanto, en el ERP la cuenta «Davivienda ahorros» (111015) quedó creada con Bre-B y **sin movimientos**; no se borra ni se reclasifica nada hasta decidirlo.
- **Pendiente derivado:** las cuentas de la operación serían Nequi (y Wompi→Nequi); ya no hay «Davivienda predeterminada»; revisar que el Nequi usado para la operación no mezcle gastos personales (pregunta al contador del 20-nov, punto 7).
- **Recordatorio creado** (con el sí de Sara): en el Panel del contador, «Vaciar y conciliar la cuenta Bancolombia antes del desembolso del Fondo Emprender», vence el **1-dic-2026** (tentativa, editable), responsable Sara / Contador.

### Decisión final de bancos (Sara, 24-nov tarde)
- **Davivienda ya no recibe pagos de Lana Rosa** (es la cuenta personal de Sara). **Solo Nequi** recibe los pagos de la operación (transferencias, Bre-B, Wompi cuando se apruebe el cambio); Bancolombia es solo del Fondo.
- **Aplicado en la base (con el sí de Sara):** medio `breb` pasó de Davivienda a **Nequi (111010)**. Hoy `medios_pago_cuenta` tiene `nequi` y `breb`, ambos → Nequi 111010.
- **También aplicado (24-nov, sí de Sara):** `transferencia` → Nequi 111010; la cuenta «Davivienda ahorros» (111015) quedó **desactivada** (sin borrar, sin movimientos). `medios_pago_cuenta` = nequi, breb y transferencia → Nequi. **Falta:** tarjeta y Wompi (cuando Wompi apruebe el cambio) siguen por defecto en Bancolombia 111005; y Bancolombia sigue marcada «general» y predeterminada: pasarla a uso «Fondo Emprender» y dejar Nequi como predeterminada (con el sí de Sara). Pregunta para el contador (20-nov, punto 7): el Nequi de la operación no debe mezclarse con gastos personales; límites de Nequi.

## Texto de arranque para un chat NUEVO de Contabilidad
```
TEMA: Contabilidad (archivo: docs/temas/contabilidad-decisiones.md)
Trabajas en el ERP de Lana Rosa (repo lana-rosa/ERP). Lee CLAUDE.md, docs/temas/contabilidad-decisiones.md (de abajo hacia arriba: lo último está al final), docs/asistente-financiero/ y la sección «Chat 7» de docs/PENDIENTES.md. No leas index.html completo (usa docs/mapa-index-html.md). Responde a Sara en español sencillo.
Estado: puntos 1, 2, 3, 7 y 10 de la reunión del 24-nov hechos; Asistente financiero activo; Davivienda (111015) creada con solo Bre-B; bancos: Bancolombia = SOLO Fondo Emprender (en ceros antes del desembolso de diciembre; recordatorio del 1-dic creado); transferencias y Wompi llegan a Nequi (activo); Davivienda = cuenta PERSONAL de Sara, sin uso en la operación (ver «Decisión final de bancos»); Bre-B y transferencia ya van a Nequi; Davivienda desactivada; falta tarjeta/Wompi y marcar Bancolombia como «Fondo Emprender».
Pendiente: Wompi/Nequi puente, mapeo de medios y Davivienda predeterminada (con el sí de Sara), puntos 4 a 6, 8 y 9 (esperan al contador), probar facturas de compras con un ZIP real, revisión de abogada y contador del asistente.
Reglas: lo contable o tributario no se decide solo: va como pregunta al contador; todo cambio en dinero/base de datos pide el sí de Sara aquí; rama → PR → squash; si tocas index.html sube CACHE_NAME en sw.js; prueba antes de decir «listo».
```
