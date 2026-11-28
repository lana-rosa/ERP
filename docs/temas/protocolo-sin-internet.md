# Protocolo: ¿qué hacemos si el local se queda SIN INTERNET?
Estado: **BORRADOR (25-nov-2026)** para revisar con Jennifer y el contador. Hecho solo con lectura del código y pruebas simuladas (sin tocar datos reales). Quien lo usa en el local: Manuela.

---
## 1. PROTOCOLO DE UNA PÁGINA (para Manuela)

**Regla de oro: NO cierres la pestaña del ERP ni la recargues (F5) mientras no haya internet.** Si se cierra o se recarga, puede que no vuelva a abrir hasta que regrese la señal.

### A. Antes de abrir cada día
1. Abre el ERP y déjalo abierto todo el día (la pestaña no se cierra).
2. Ten a mano: el **cuaderno de contingencia** y el **talonario de recibos** (hojas con fecha, hora, producto, cantidad, valor, medio de pago, datos del cliente).
3. Ten el celular con datos cargados para usarlo de **módem** (compartir internet).

### B. Si se cae el internet
1. **Avisa a Jennifer o a Sara.** Anota la hora en que se cayó.
2. **Prueba el celular como módem:** activa "Compartir internet / punto de acceso" y conecta el computador a esa red. Si funciona, sigue normal.
3. **Si no hay forma de conectarse, sigue vendiendo así:**
   - **Efectivo:** registra la venta en el ERP como siempre. Saldrá un aviso: *"📴 Sin conexión — la venta quedó guardada en este dispositivo"*. **No saldrá recibo del ERP**: dale al cliente un recibo del **talonario** y anota la venta en el cuaderno marcándola **"CONTINGENCIA"**.
   - **Datáfono (tarjeta):** solo si el datáfono funciona por su propia señal. Si no, no se cobra con tarjeta.
   - **Nequi / Bre-B:** no confirmes el pago hasta **verlo en la app Nequi** del negocio (necesita datos en el celular). Pide al cliente la captura del comprobante y anótala.
   - **Factura electrónica:** si el cliente la pide, anota **nombre, cédula/NIT, correo y teléfono** y dile que se emite apenas vuelva la conexión. La venta sigue marcada "CONTINGENCIA".
   - Si el cliente da sus datos para guardar, **anótalos en el cuaderno**: el ERP no podrá guardarlos sin internet.
4. No vendas el mismo producto muchas veces seguidas sin mirar el stock físico: sin internet el ERP **no baja el inventario** hasta que sincroniza.

### C. Cuando vuelve el internet
1. **No cierres la pestaña.** El aviso rojo de "ventas sin guardar" debe desaparecer solo; si no, tócalo para sincronizar.
2. Abre **Historial de ventas** y compara con el cuaderno: cada venta debe salir **UNA sola vez**. Si alguna sale repetida, **no la anules tú**: avisa a Jennifer o a Sara.
3. **Emitir las facturas pendientes** en el portal de la DIAN lo antes posible (si fue una falla técnica real, el plazo es de **48 horas**; ver preguntas al contador). Anota el número de cada factura en el cuaderno.

### D. Cierre de caja
- **No cierres el turno mientras el aviso rojo siga visible**: las ventas en espera no cuentan en el arqueo y saldría un faltante falso.
- Cuenta el efectivo, anótalo en el cuaderno y fírmalo con la hora. Si no volvió el internet al cerrar el local, el cierre en el ERP se hace **apenas haya conexión** con ese conteo (**pregunta para Sara: la regla de cerrar a diario choca con esto**).

### E. A quién llamar
Jennifer · Sara · proveedor de internet: *(poner nombre y teléfono)* · contador: *(poner nombre y teléfono)*.

---
## 2. QUÉ HACE HOY EL ERP SIN INTERNET (hallazgos)

| Pregunta | Respuesta (evidencia) |
|---|---|
| ¿Deja registrar ventas? | **Sí, solo con efectivo/sin datos de cliente**, si la pestaña ya estaba abierta. Si falla el envío al Worker, `confirmarVenta` llama `encolarVentaOffline` y avisa "Sin conexión" (index.html ~8629). |
| ¿Dónde guarda lo pendiente? | `localStorage` del navegador, clave `lanaRosa_ventasPendientesOffline` (index.html ~6396). Sobrevive a recargar (probado). **Se pierde** si se borra el historial/datos del navegador o se cambia de computador. |
| ¿Descuenta inventario, mueve caja, imprime recibo? | **No.** Nada de eso pasa hasta sincronizar: el servidor aún no la conoce; no se crea `ultimaVentaCache`, así que no hay recibo/WhatsApp/correo; el stock en pantalla no baja (puede venderse de más). Tampoco se genera asiento. |
| ¿Cuándo sincroniza? | Al volver el evento `online` y al abrir la pantalla de venta (~7405). Usa `navigator.onLine`, que puede decir "sí" aunque el wifi no tenga internet. |
| ¿Riesgo de duplicado? | **Sí.** Si el servidor guarda la venta pero la respuesta se pierde, el ERP cree que falló y la reenvía. Simulado: 2 envíos → **2 ventas guardadas** con 1 sola en la cola. No hay llave anti-duplicado. |
| ¿Riesgo de pérdida? | Si el error es del servidor (ej. sin stock) la venta queda en la cola con el error y reintenta cada vez; la administradora debe revisarla. Si se limpia el navegador, se pierde. |
| ¿Qué falla con datos de cliente? | Si el cliente aceptó guardar sus datos, el ERP primero llama a `/api/pos/clientes` **sin protección de red**: sin internet esa llamada falla y la venta **ni se registra ni se encola** (aparece un error). Hay que vender sin guardar datos del cliente y anotarlos en el cuaderno. |
| ¿Qué pantallas dejan de funcionar? | Todas las que consultan Supabase o el Worker: historial, reportes, pedidos, compras, inventario, cierre de turno, factura. Solo se ve lo ya cargado. |
| ¿El service worker abre la app sin red? | **Solo en parte.** `sw.js` guarda `index.html` (red primero, copia como respaldo). Pero las librerías vienen de internet (`supabase-js`, xlsx, Chart.js… en index.html líneas 20-25) y **no están en el caché**: recargar sin internet puede dejar la app sin arrancar. Por eso la regla de oro: no recargar. |
| 🔴 **Regresión mía (PR #143)** | Si se recarga con la sesión guardada y **sin internet**, `obtenerRolUsuario` no puede leer el rol, queda `null` y el nuevo bloqueo de "cuenta sin rol" **cierra la sesión** diciendo "no tiene acceso al ERP" (probado con simulación). **Corregido en la rama (sw v100, pendiente de publicar con el sí de Jennifer/Sara):** solo bloquea si la base respondió "0 filas" (PGRST116); cualquier otro error (sin internet) no cierra la sesión. Probado antes/después a 1280 y 390 px. |

### Pagos
- **Efectivo:** funciona (se cobra y se registra en el ERP al volver).
- **Datáfono:** depende de su propia conexión; el ERP no interviene.
- **Nequi/Bre-B:** el ERP solo anota el medio; la confirmación está en la app Nequi (necesita datos del celular). El cobro se registra como `nequi` al reconectar.

### Facturación (resumen, ver `docs/auditoria-dian-software-propio.md`)
Hoy se emite en el portal gratuito de la DIAN (necesita internet) y se registra en el ERP. La factura de contingencia solo vale con **falla tecnológica real**, con **numeración de contingencia autorizada antes**, y se transmite dentro de **48 horas** desde que se supere el problema. El ERP solo marca "contingencia" y **no controla las 48 horas**.

---
## 3. LO QUE FALTA EN EL ERP (propuestas; cada cambio necesita el "sí" de Sara/Jennifer)
1. ✅ (en rama, v100) **Corregir mi regresión**: que sin internet la recarga no cierre la sesión (solo bloquear si la consulta respondió y de verdad no hay rol).
2. 🔴 **Anti-duplicado al sincronizar:** poner una marca única en cada venta en espera (p. ej. en `referencia` del pago) y, antes de reenviar, revisar en Supabase si ya existe. El Worker no se puede editar.
3. 🟡 **Que guardar datos del cliente no bloquee la venta sin internet** (poner la llamada a `/api/pos/clientes` con su propio manejo de error).
4. 🟡 **Guardar las librerías en el service worker** para que recargar sin internet sí abra la app.
5. 🟡 **Recibo de contingencia** impreso desde el ERP con número provisional (hoy se usa el talonario).
6. 🟡 **Control de las 48 horas**: lista de ventas en "contingencia" con la hora límite para emitir su factura.
7. 🟡 **Aviso al abrir** si quedan ventas en la cola (hoy el aviso rojo solo aparece al entrar a ciertas pantallas).

## 4. PREGUNTAS PARA EL CONTADOR
1. ¿Hay que tener **numeración de contingencia autorizada** antes? ¿Cómo se solicita y cuántos números pedir? ¿Aplica para quien factura con el portal gratuito de la DIAN?
2. Durante una caída, ¿qué hacemos con las **ventas a consumidor final sin factura**? ¿Sirve un documento/recibo interno y después se emite la factura, o toca emitirla siempre?
3. ¿El plazo de **48 horas** corre desde que vuelve el internet o desde la venta? ¿Cómo se prueba la "falla tecnológica real" (captura del proveedor, hora del corte)?
4. Si el cliente **no pide factura** durante la caída, ¿qué soporte debe quedar?
5. ¿Cómo registramos contablemente las ventas anotadas en cuaderno cuando se sincronizan al día siguiente (fecha de la venta vs. fecha de registro)?

## 5. Decisiones abiertas (Sara/Jennifer)
- Cierre de turno diario vs. cierre cuando vuelva el internet.
- ¿El datáfono funciona con su propia señal?
- Nombre y teléfono del proveedor de internet; ¿tener un segundo servicio (celular de respaldo) fijo?
