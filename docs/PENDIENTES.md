# Pendientes ERP / CRM

Actualizado: 2026-11-12 (Orquestador)

> **Regla para los chats:** cada chat edita **solo su sección** (y marca con [x] lo que cierre, con fecha y PR). El orden de trabajo lo pone el Orquestador. No empieces algo de "En cola" hasta que el chat anterior haya publicado en `main`.

## Fechas límite
- **2-dic-2026:** informe bimestral a la interventora (empezar la semana del 23-nov; necesita ventas y estados financieros al día).
- Informes mensuales (producción, ventas, estados financieros): fecha por confirmar con la interventora.
- Respaldo mensual de facturación electrónica (desde oct-2026).

## Orden de trabajo (turnos)
Dos chats no deben cambiar `index.html` en la misma zona a la vez.
1. **Chat 1 Ventas** — causa probable encontrada; arreglos publicados; falta que Sara pruebe turno nuevo y venta.
2. **Chat 2 Pedidos** — en curso: textos legales en recibos → luego lote de pedidos (ver su sección).
3. **Chat 3 Compras SENA** — en curso: ajustes del nuevo modelo de desembolsos (zona Compras, no choca con el chat 2).
4. **Chat 6 Producción** — en cola: empieza **cuando el chat 2 publique** su lote de pedidos.
5. **Chat 8 Menú/Interfaz** — hecho: barra de búsqueda en celular + buscadores de Productos y Clientes (v44).
- Chat 4 DIAN: resolución registrada; editar cliente publicado (PR #124); falta emitir las 7 facturas. Chat 5 Impuestos: preguntas para el contador listas (PR #113).

## Por chat

### Chat 1 · Ventas
- [ ] 🔴 **No deja registrar ventas** (desde 03-nov). Mensaje: "No hay turno de caja abierto." (lo da el Worker). Causas probables: (a) el turno abierto el 19-oct lleva +24 días y el Worker ya no lo reconoce; (b) Sara tiene 2 cuentas (la del ERP `…@gmai.com`, administrador; otra `…@gmail.com` sin rol, creada 3-nov). 13/15-nov: además "Token inválido o expirado" al abrir turno. Arreglos publicados en el PR (token siempre vigente + bloqueo de cuentas sin rol). **Falta (Sara):** entrar con la cuenta del ERP, cerrar el turno del 19-oct con arqueo, abrir uno nuevo y hacer una venta de prueba; luego marcar [x]. Ver `docs/temas/ventas-pos.md`.

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
- [x] 13-nov: cambiar la fecha de entrega de un pedido con motivo e historial (botón en Pedidos Web/Redes). Falta: pantalla que muestre el cumplimiento de entregas (`fn_cumplimiento_entregas`).
- [ ] 🔴 Pago manual de pedidos web (Nequi/Bre-B/transferencia): código listo y probado; falta que la dueña autorice aplicar `docs/migraciones/2026-11-18-pago-manual-pedido-web.sql`, correr el asesor de seguridad, que el chat 7 asigne cuentas a Nequi/Bre-B, y avisar al chat 6 de la web.
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
- [x] **Editar datos del cliente de una venta/pedido** (pedido de Sara 13-nov, regla: solo si NO tiene factura DIAN registrada). Publicado 13-nov (PR #124, función `fn_editar_cliente_venta` aplicada en Supabase). Botón "✏️ Datos del cliente" en Por facturar. 13-nov: también en Historial de ventas (Tienda y WhatsApp/Redes), publicado (PR #126).
- **Para otro chat (Chat 2 Pedidos):** el panel "Editar datos del cliente" del pedido usa `fn_editar_cliente_pedido_canal`, que sí deja a un cajero editar, modifica el cliente compartido y no revisa si ya hay factura. Conviene que ese panel llame a `fn_editar_cliente_venta('pedido_canal', ...)` o que se bloquee si hay factura.
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
- [ ] 🔴 Mapeo de medios (19-nov, Sara): Bre-B → Davivienda; Nequi manual → Nequi; Wompi → Nequi (pedido a Wompi el 18-nov, falta aprobación). Aplicar con el sí de Sara cuando exista la cuenta Davivienda en el ERP (necesito tipo y número) y se confirme si es el mismo Nequi.
- [ ] 🔴 Wompi → Nequi puente (18-nov): Wompi solo desembolsa a Bancolombia/Nequi; plan Wompi → Nequi (puente) → Davivienda. Propuesta en `docs/temas/contabilidad-decisiones.md`; en el ERP NO se cambian medios de pago hasta que Sara confirme que Wompi ya desembolsa al Nequi (y dé el sí). Si luego se migra a ePayco/Davivienda, esa cuenta puente se cierra.
- [ ] 🔴 Wompi urgente (18-nov) — sustituido por la línea de arriba: el desembolso de la página web no debe llegar a Bancolombia (cuenta del Fondo). Sara ya tiene Davivienda a su nombre; **Sara cambia la cuenta de desembolso en el panel de Wompi** (puede pedir documentos). Cuando Wompi apruebe, ese mismo día Claude crea Davivienda en el ERP, la deja predeterminada, asigna Wompi/transferencia/tarjeta a Davivienda y pasa los $13.888 (necesita: número y tipo de la cuenta y el sí de Sara).
- [ ] 🔴 Bancos (18-nov): Davivienda = operación, Bancolombia = solo Fondo Emprender. Propuesta escrita en `docs/temas/contabilidad-decisiones.md`; **falta el sí de Sara** para tocar cuentas/libros. Pregunta a Sara: ¿a qué cuenta consigna Wompi? Conciliación automática por extractos: solo propuesta, para después de la apertura.
- [x] 24-nov: punto 3 etapa 1 (leer ZIP/XML de facturas de compras y mostrar borradores, sin registrar; v89): en rama; falta el sí de Sara para fusionar y para la etapa 2.
- [x] 24-nov: punto 10 (soportes de pagos y seguridad social con enlace al Drive, Panel del contador, tabla `soportes_mensuales_contables`, v88): listo en rama, falta el sí de Sara para fusionar.
- [x] 24-nov: informes de solo lectura listos en rama (catálogo de cuentas, gastos y compras por categoría, informe mensual del Fondo); falta el sí de Sara para fusionar a `main`. Faltan del plan: extracto+conciliación del Fondo en el informe mensual, y los puntos 3 a 6 y 8 a 10.
- [x] Resumen de pendientes contables listo para llevarle a Hernando: `docs/resumen-contador.md` (llevarlo junto con las 22 preguntas del chat 5) — 12-nov-2026

### Chat 8 · Menú/Interfaz
- [ ] Inicio del ERP por módulos tipo portada LAROVA, menú lateral solo dentro de cada módulo, sin «Gestión» (18-nov, v63) + portada LAROVA sin la tarjeta de Rosina: listo en la rama, **falta el sí de Jennifer** (🟡, fotos antes/después). El menú oscuro con acordeones (v62) se descartó. Plazo: probado el 4-dic o queda para después de la apertura; nunca el 12 ni el 13-dic.
- [ ] 🔴 Pasar `lana-rosa/ERP` a privado (preparado 18-nov, NO aplicado): ver `docs/temas/privatizar-erp.md` y `docs/privatizar-erp/`. Orden: larova estable (4-dic) → repo público mínimo de redirección → privado → verificar. Falta el sí final de Jennifer.
- [x] Respaldo del ERP (18-nov): función `fn_exportar_respaldo` aplicada (0 advertencias nuevas) y botón publicado (v61). [ ] Jennifer: descargar la primera copia y guardarla fuera del repo; probar el Excel. [ ] Restaurar (Worker) probablemente con el mismo límite: revisar. [x] Copia automática: YA EXISTE en `lanarosa-copias` (diaria, cifrada, 90 días, con prueba de restauración); mejoras preparadas en la rama `mejoras-copia` (Gestión incluida, reintentos, aviso si falla): falta el sí para pasarlas a `main`; el CRM sigue sin copia. [ ] Confirmar la causa en los registros del Worker. Ver `respaldo-copias.md`.
- [x] LAROVA 18-nov: Sara verificó `/erp/` y el ingreso único ERP↔Gestión (entra directo); CRM pide su propio ingreso (esperado). [ ] Falta: venta de prueba, revisar un pedido, app instalable, botón «Volver» en Gestión/CRM con cuentas reales, aviso al CRM chat 5. Plazo vie 4-dic.
- [x] LAROVA `/gestion/` y `/CRM/` (18-nov): reenvío en Pages Functions, probado en local. Botón «Volver a LAROVA» en Gestión y CRM (inyectado por el reenvío). [ ] Sara: probar en `larova.lanarosacrochet.com` (ingreso único ERP↔Gestión, CRM). Plazo duro vie 4-dic. Ver `hosting.md`.
- [x] LAROVA paso 2 (18-nov): dominio `larova.lanarosacrochet.com` activo; Worker acepta la dirección. [ ] Sara: borrar token «Claude ERP Worker 2»; probar en `/erp/` inicio de sesión, venta de prueba, pedidos, app instalable. [ ] Yo: `/gestion/` y `/crm/`. Plazo duro vie 4-dic. Ver `hosting.md`.
- [ ] 🔴 LAROVA paso 2 EMPEZADO (17-nov): `larova.lanarosacrochet.com`, plazo duro estable el vie 4-dic (si no, se retoma tras la apertura; del 5 al 13-dic no se toca). `scripts/build-larova.sh` listo. Falta: proyecto en Cloudflare Pages (Jennifer), Worker (orígenes), `/gestion/` y `/crm/`, pruebas de ventas/caja/pedidos, aviso de sesiones cerradas. Ver `hosting.md`.
- [x] Portada LAROVA paso 1 (17-nov, v60): `larova.html` con enlaces a ERP, CRM, Gestión y web; ítem «Volver a LAROVA» y «Gestión» en el menú del ERP. [ ] Paso 2 (después del 13-dic): dirección única `larova.lanarosacrochet.com`, filtro de tarjetas por rol, un solo inicio de sesión. Solo proponer, no construir antes.
- [ ] 🕒 Futuro (desde el 14-dic, después de la apertura): verificación en dos pasos (MFA TOTP, Supabase Auth) solo para administradoras: inscribir factor con QR, pedir código al iniciar sesión y plan de recuperación (códigos de respaldo o restablece la otra administradora). No construir antes. Ver `menu-lateral.md`.
- [x] Ítem "Sistema Operativo" en el menú (admin, Gerencia SO, Taller SO), 14-nov v55. Al mudar de dominio: cambiar `URL_SISTEMA_OPERATIVO`.
- [x] Inicio de sesión: botón 👁 para ver la contraseña y error que sugiere revisar el correo (13-nov, v47).
- [x] Worker de ventas ya acepta la dirección nueva (13-nov). [ ] Sara: crear el proyecto en Cloudflare Pages (reintentar), decidir comando de compilación para no publicar `docs/` y `supabase/`, borrar el token de Cloudflare. [ ] Luego probar inicio de sesión, venta de prueba, pedidos y app instalable. Detalle en `docs/temas/hosting.md`.
- [x] 🔴 Sin sesión se veía el ☰ y se abría el menú (13-nov): corregido, nada visible sin iniciar sesión.
- [x] 🔴 Supabase: 5 tablas con política abierta a cualquiera con la llave pública: cerradas 13-nov con el "sí" de Sara (ver menu-lateral.md).
- [x] Buscadores de **Productos** (Gestionar inventario) y **Clientes**: al entrar solo la caja; la lista aparece al escribir.
- [x] Celular: la barra de búsqueda ya no queda por encima del fondo oscuro del menú, no tapa la barra rosada y el texto cabe.
- [x] Menú lateral oculto sin forma de volver a mostrarlo (PR #100).

### Chat 9 · Personal
- [x] Fase 1 — Ficha del empleado (15-nov): cargo, área, jornada, tipo y fin de contrato, caja de compensación, cuenta de acceso (rol) y avisos de documentos que faltan y de contrato por vencer (ver `docs/temas/personal.md`).
- [x] Fase 2 — Turnos y asistencia (15-nov): turnos por semana, copiar semana, festivos, resumen de asistencia y del mes, corregir marcaciones, "Mi horario" en el menú (ver `docs/temas/personal.md`).
- [x] Fase 3 — Vacaciones y permisos (15-nov): la empleada pide desde Mi perfil, una administradora aprueba o rechaza en Talento Humano, saldo de días, y la asistencia no cuenta como ausente lo aprobado (ver `docs/temas/personal.md`).
- [ ] Fase 4 — Tejedoras · Fase 5 — Exportar novedades / resumen mensual para la DIAN.
- [ ] Vacaciones: avisar a la empleada cuando le respondan (hoy lo ve al entrar en Mi perfil → Vacaciones y permisos); pantalla para que una administradora registre una ausencia a nombre de otra persona (la función ya existe: `fn_aus_solicitar` con `p_empleado`); mostrar las ausencias aprobadas en el calendario del equipo.
- [x] Asistencia ↔ turno de caja (17-nov, aprobado por Sara): cruce de solo lectura en Talento Humano → Turnos y asistencia → "Caja y asistencia" (ver `docs/temas/personal.md`). No cambia cómo se abre o cierra el turno (eso pasa por el Worker). Para que sirva hay que conectar cada ficha con su cuenta (hoy todo sale "sin ficha").
- [x] Privacidad de las horas (15-nov, aprobado por Sara): `registro_horas_empleado` ya no la lee cualquier usuario; cada empleada ve las suyas, el líder de área las de su área, administradoras y contador todas (ver `docs/temas/personal.md`).
- **Para otro chat (Contabilidad/Calendario):** `fn_festivos_colombia` fallaba siempre (devolvía fecha con hora en los festivos que pasan a lunes). Se corrigió el tipo de dato el 15-nov sin cambiar ninguna fecha; conviene que quien use festivos lo confirme.
- [x] Permisos de Manuela (15-nov): rol "Líder de Tienda" (base cajero) con Proveedores y Órdenes de compra visibles; pedidos a proveedores quedan "por aprobar" y los aprueba una administradora; cuenta el inventario de la Tienda y la administradora finaliza la toma. Detalle en `docs/temas/personal.md`.
- [x] 🔴 Seguridad de funciones de dinero (17-nov, aprobado por Sara): se restringieron **20 funciones** (nómina, pago de nómina, retiros del propietario y socias, reparto de utilidades, honorarios, cierre contable, eliminar período, reinicio de datos, alertas y saldo de vacaciones) a administradora (el saldo de vacaciones también al contador). El Worker y las tareas del sistema no se afectan. Detalle en `docs/temas/personal.md`.
- [x] Seguridad paso 2 (19-nov, aprobado por Sara): se restringieron **23 funciones** más (bancos y conciliación: administradora y contador; transferencias internas, activos fijos, presupuesto, Fondo Emprender y capital: solo administradora). En total **43 funciones** con el candado nuevo.
- [x] Seguridad paso 3 (23-nov, aprobado por Sara): **58 funciones más** (67 versiones) pasaron al candado por rol: ventas y devoluciones, pedidos y anticipos, caja y turnos, inventario y traslados, producción e insumos, kits, notas crédito, facturación electrónica y contabilizar ventas. Cada una quedó con **los mismos roles que ya le exigía el Worker** (administradora; administradora y cajera; con taller; con contador, según el caso). Con esto, **111 versiones tienen candado por rol**.
- [ ] 🟡 **Seguridad, lo que se dejó a propósito (20 funciones, candado débil):** las usan flujos que no pasan por un solo rol o que son de la web: `fn_marcar_entrada` y `fn_marcar_salida` (todo colaborador, también tejedoras), `fn_incrementar_uso_codigo` y `fn_validar_codigo_descuento` (códigos de descuento), `fn_contabilizar_pago_pedido_canal` (pedidos de la web y CRM), `fn_correo_compra_web`, `fn_correo_membresia` y `fn_avisos_membresia` (correos y cron), `fn_cuenta_banco_medio` y `fn_cuenta_medio_pago` (ayudantes de cuentas usados por ventas, pagos y nómina), `fn_costos_fijos_linea`, `fn_parametros_costeo`, `fn_valor_en_proceso`, `fn_valor_encargos_terminados`, `fn_valor_hora_honorarios`, `fn_op_mano_obra`, `fn_prevision_impuestos` (costos y previsión: las leen varios roles), `fn_reporte_departamento`, `fn_reporte_presupuesto` (los ven todos los roles) y `fn_marcar_cuentas_vencidas`. Son lectura, avisos o procesos automáticos; revisar con Ventas/Contabilidad si algún día se quiere cerrarlas más. Consulta: `pg_proc` con `fn_rol_actual() is null and not public.fn_es_tejedora()`.
- [ ] Manuela y las compras: hoy puede registrar compras y gastos de Tienda (ya podía como cajero) escogiendo quién las aprobó; no hay aprobación real. ¿Se deja así o solo las registra una administradora?
- [x] Aviso a las administradoras de lo que está por responder (24-nov): en el inicio sale «⏳ Por responder» con botones (autorizaciones de compra, pedidos a proveedor por aprobar y solicitudes de vacaciones o permiso) y el menú muestra el número en cada opción. Ver `docs/temas/personal.md`.
- **Para otro chat (Inventario/Compras):** el Worker deja crear/ver órdenes de compra y manejar tomas de inventario solo a `administrador` (no editable desde aquí); por eso se hicieron funciones en Supabase para la Tienda. El directorio de proveedores incluye al equipo y a tejedoras (honorarios): la Tienda los ve.
- [x] Horario de la tienda y límite legal de 42 horas (19-nov, pedido de Sara): lunes a viernes 8:30–12:30 y 2:30–6:00 p. m., sábado 8:30–1:00 p. m. = **42,0 h por semana**, justo en el límite. Botón «Cargar el horario de la tienda» en Turnos y asistencia, contador de horas por persona (rojo si pasa de 42), tope de 42 en la ficha y en la base de datos. Ver `docs/temas/personal.md`.
- [ ] 🔴 **Preguntas laborales para el contador Oscar (23-nov; el contador cambió, ya no es Hernando):** documento en `docs/temas/personal-preguntas-contador.md` y **PDF listo para enviarle** en `docs/temas/Preguntas-laborales-para-Oscar-Lana-Rosa.pdf` (16 preguntas: quién va en nómina, contrato y salario, 42 horas y horas extra, vacaciones y permisos, nómina electrónica y tarifas). Falta que Sara se lo envíe y que Oscar responda; su cuenta del ERP **ya está creada** (Oscar Rondon, rol `contador` con el rol personalizado «Contador»; creada el 20-nov; **aún no ha entrado**; la de Hernando está inactiva); las marcadas 🔴 son para antes de firmar contratos (apertura 13-dic). Incluye y reemplaza la línea de abajo sobre el horario de 42 h.
- [ ] 🟠 **Para el contador (horario de 42 h):** con 42 h exactas no hay margen: cualquier minuto extra es hora extra con recargo. Confirmar: (a) que 42 h/semana es el límite aplicable hoy (Ley 2101 de 2021, 42 h desde el 15-jul-2026); (b) la base para el valor de la hora de extras (hoy `salario ÷ (horas por semana × 4,3333)` con 42); (c) si la pausa de 2 h 30 min del mediodía no cuenta como tiempo de trabajo; (d) semanas con festivo (menos horas) y cómo pagar el festivo trabajado.
- [x] Compras de Manuela con autorización previa de una administradora (23-nov, decisión de Sara: «permiso antes de comprar, y la administradora aprueba»): pantalla Compras → Autorizar compras. Ver `docs/temas/personal.md`. Pendiente: que Manuela y una administradora lo prueben con una compra real; **Regla de Sara (23-nov): solo desde $1.000.000 hace falta la autorización previa** (por debajo de ese valor se registra como siempre, eligiendo quién aprobó). Riesgo anotado: dos compras de, p. ej., $900.000 seguidas no piden permiso; revisar el Registro de compras de vez en cuando.
- [ ] 🟠 **Supabase plan Pro (Sara, 19-nov, «pide que sea Pro»):** la protección contra contraseñas filtradas solo está en el plan Pro. Solicitado al orquestador general (el plan es de todo el proyecto compartido: Web, ERP, CRM y SO); lo paga/decide quien administra la cuenta de Supabase.
- [ ] «Gestión Colaboradores» (antes «Talento»; Jennifer): **diseño FINAL aprobado por Jennifer el 23-nov-2026** (`docs/temas/gestion-colaboradores.md`: módulo dentro de LAROVA como página aparte `colaboradores.html`, misma base y sesión del ERP, permisos por rol). **No construir ni tocar la base hasta que Jennifer fije la fecha.** Pendiente de ella: la fecha de construcción y el texto de su especificación original, si quiere cruzarlo con el diseño.
- [ ] Al crear un empleado nuevo, pedir cargo/área/jornada/fin de contrato desde el inicio (hoy se llenan al "Editar").
- [x] Recuperar contraseña desde el inicio de sesión (18-nov, pedido de Sara): enlace "¿Se te olvidó la contraseña?" en la pantalla de entrada; envía un correo con un enlace para elegir una contraseña nueva (ver `docs/temas/personal.md`). Falta una prueba real por correo (Sara o Jennifer).
- [x] Correo de Sara mal escrito (resuelto): el 18-nov se pasó al alias `+erp` y el 19-nov, por decisión de Sara (el pedido de la tienda era de prueba), el chat 8 lo dejó en el correo exacto `saralmunoz1301@gmail.com` y borró su cuenta de clienta web. Verificado el 19-nov: misma contraseña, rol administradora activo, 95 asientos, ficha conectada. **Ya no se usa el `+erp`.** Solo falta que Sara pruebe "¿Se te olvidó la contraseña?" con ese correo. Detalle en `docs/temas/personal.md`.
- [ ] 🟠 Seguridad de acceso (asesor de Supabase, 18-nov): **activar la protección contra contraseñas filtradas** (Authentication → Password security, en el panel de Supabase; no se puede desde aquí); 33 tablas tienen seguridad activa pero sin reglas (solo las usa el Worker; informativo); 24 funciones se pueden ejecutar sin iniciar sesión y son las públicas de la tienda web (esperado).
- **Fuera del ERP (14-nov, Orquestador):** lista de chequeo 5S y todo lo de SG-SST viven en el Sistema Operativo (`sistema_operativo.auditorias_5s`); no se construyen aquí.
- **Para otro chat:** nada por ahora.

## Sara
- [ ] 🔴 Mensaje exacto/captura del error de ventas → chat 1.
- [ ] Decidir el "sí" del chat 5 (Impuestos).
- [x] Datos de la resolución DIAN → chat 4 (entregados 12-nov; falta la vigencia).
- [ ] Pegar en Políticas legales los textos de la abogada (cambios y anticipos) cuando el chat 2 publique; revisar que la tienda web diga lo mismo.
- [ ] Servicios públicos y arriendo de octubre (atrasado, fecha 2026-10-05).
- [ ] Arqueo físico de caja (última referencia $1.353.066).
- [ ] Fecha de inauguración del almacén.
- [ ] Personal: nombres de las 2 tejedoras y de quien atiende el almacén (¿Manuela?), con jornada y salario de cada una; decidir si las filas actuales (Sara, Jennifer, Manuela, hoy "indefinido") se quedan o se reemplazan por los 3 contratos a término fijo de 1 año. Sara y Jennifer: ver pregunta al contador.
- [x] Personal: cuentas conectadas con las fichas (17-nov, hecho por Claude con visto bueno de Sara): Sara, Jennifer y Manuela. Falta repetirlo con cada persona nueva (Nómina → Empleados → Editar → Cuenta de acceso).
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
- [ ] Personal (15-nov): vacaciones y permisos. ¿Los días de vacaciones se cuentan de lunes a sábado o de lunes a viernes (hoy lunes a sábado sin festivos)? ¿Se mantiene 15 días hábiles por año, desde cuándo se pueden tomar, y con cuánto aviso se piden? ¿Los permisos y la calamidad doméstica se pagan, se descuentan o se reponen? ¿Hay vacaciones compensadas en dinero? Mientras tanto la administradora ajusta los días al aprobar.
- [ ] Personal (15-nov): recargos de horas extra y trabajo en domingo/festivo (diurnas, nocturnas, dominicales; desde cuándo cuenta la hora nocturna), jornada máxima semanal, tolerancia para llegadas tarde y qué hacer con el descanso. El ERP hoy solo suma horas y marca domingos y festivos.
- [ ] Personal (14-nov): ¿Sara (y Jennifer si es socia) pueden ir como empleadas siendo persona natural, o siguen como retiros del propietario (3805) u honorarios? Prestaciones, seguridad social y tipo de contrato de los 3 empleados; si las 2 tejedoras dejan de pagarse por honorarios y desde qué fecha; campos y plazo mensual de la nómina electrónica gratuita de la DIAN.
- [ ] Impuestos no se pagan desde la cuenta del Fondo; cómo registrar los giros del Fondo (cuenta exclusiva, sin mezclar).
- [ ] UVT y tarifas SIMPLE, escenario de provisión, tabla de renta — lista de 22 preguntas en `docs/temas/impuestos-preguntas-contador.md`. Faltan: UVT 2026 confirmada y tarifas SIMPLE 2026/2027 (hoy 0 cargadas).
- [ ] Verificar ICA Villamaría (preguntas 15–19 del mismo archivo).
- [ ] Códigos CUIF de 10 dígitos.
- [ ] Aplicabilidad del documento soporte.
- [ ] Ventas desde el 14-oct-2026 (ya facturadora electrónica) que quedaron solo con recibo del ERP, sin factura electrónica: 6 del punto de venta (POS-2026-00016 a 00021, $2.205.000) y 1 pedido (PED-2026-00559, $15.200, parece prueba). Además 7 pedidos con "facturar" definido a consumidor final ($601.000). Pregunta: ¿se emite factura electrónica extemporánea a consumidor final por cada una, o cómo se regulariza? (12-nov-2026)
- [ ] Libro fiscal y contabilidad de microempresa (punto 6, 24-nov): qué libros exige, qué marco contable aplica, si se pueden llevar solo desde el ERP, qué le falta al ERP. Preguntas en `docs/resumen-contador.md` (punto 8). De esto depende el punto 6 del plan.
- [ ] Retenciones, libros y declaraciones como sociedad.
- [ ] Bancos (18-nov, contador nuevo el viernes 20-nov): confirmar la decisión Davivienda (operación) / Bancolombia (Fondo) y qué hacer con lo ya registrado en Caja por cobros hechos en Nequi; reemplaza la decisión del 14-oct.
- [ ] Wompi en Nequi (18-nov, viernes 20-nov): ¿cómo se tratan los desembolsos de Wompi que llegan a un Nequi (ingreso por venta, comisión, retención si aplica)? ¿Qué reporta la DIAN de los pagos por pasarelas y a nombre de quién? ¿Límites de Nequi (monto por mes) y riesgo de que se mezcle con lo personal, o conviene un Nequi exclusivo? ¿Cómo se registra el traslado semanal a Davivienda?
- [ ] Viejos: retiros 3805 vs honorarios, aportes vs deuda, arriendo mayo/junio, confirmación escrita de 27 recibos, medio de pago de 17 ventas antiguas.

## Compras SENA — entregas del Fondo (24-nov-2026)
- [x] Calendario de entregas sembrado + alerta en LAROVA + descarga .ics (sw.js v86)
- [x] Campo "cuenta desde la que pagaste" fusionado (PR #188)
- [ ] Sara: subir el informe contable de noviembre a la plataforma SENA el vie 4-dic (lo prepara Contabilidad, chat 7)
- [ ] Sembrar las entregas de enero en adelante (informes mensuales, bimestral de marzo) y las de mercadeo/contrapartidas cuando haya fecha
- [x] Alerta por correo diaria 8 a. m. (24-nov): tarea `avisos-entregas-fondo`
- [x] Correo de prueba de la alerta recibido por Sara (24-nov); funciona de punta a punta

## Opcionales (Claude, si se pide)
- [ ] Enlazar soporte de compras a crédito
- [ ] Soporte para facturas manuales antiguas
- [ ] Ingesta de facturas por correo (solo borrador)
- [ ] Probar sincronización CRM↔ERP y pedidos de la tienda virtual
- [ ] Borrar edge functions sin uso y columnas/función antiguas en Supabase

- [x] Correo de Sara (19-nov): cuenta del ERP ahora `saralmunoz1301@gmail.com` (exacto); cuenta de clienta de prueba y su pedido borrados con el sí de Sara. Falta que Sara pruebe la recuperación de contraseña con ese correo.
