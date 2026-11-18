# Personal (manejo de empleados) — Chat 9

Abierto el 14-nov-2026 por pedido de Sara, inspirado en funciones de plataformas como Buk (sin copiar su diseño).

## Decisión inicial (Orquestador, aprobada por Sara)
Construir en el ERP lo del día a día; la **nómina electrónica a la DIAN NO se construye**: se contrata un proveedor (lo recomienda el contador) y el ERP le pasa horas y novedades.

## Alcance propuesto (por fases)
1. **Ficha del empleado:** datos personales, contrato (tipo, fechas, salario), rol en el ERP, EPS/ARL/pensión/caja, documentos (cédula, contrato firmado, afiliaciones). Reusar la tabla `empleados` existente.
2. **Turnos y asistencia:** horario de la tienda, entrada/salida, horas extra, festivos; enlazado con el turno de caja.
3. **Vacaciones y permisos:** solicitud de la empleada y aprobación de la administradora.
4. **Tejedoras:** horas y pagos (honorarios) usando lo existente: `producto_tejido_plan`, `tejedoras_capacidad`, `tejedoras_usuarios`, `honorarios_tejedora_nomina`.
5. **Exportar novedades** (horas, extras, ausencias) para el proveedor de nómina.

## Equipo y funciones (Sara, 14-nov)
| Persona | Cargo | Funciones | Rol ERP |
|---|---|---|---|
| **Sara** (propietaria) | Tejedora + Administración y contabilidad + **Líder de la Academy** | Administración, manejo contable de la mano con el contador; lidera la Academy apoyada en Claude | `administrador` |
| **Jennifer** | Tejedora + **Líder del Taller** | Redes sociales, fotos de productos, actualizar productos en la web; mantenimiento del entorno digital (web, CRM, ERP) con Claude | `administrador` |
| **Manuela** | **Líder de la Tienda** | Inventarios (surtir almacén, bodega), proveedores, caja, atención al público | `cajero` (+ permisos de inventario/proveedores a revisar) |
| Contador (Hernando) | Prestación de servicios | Contabilidad e impuestos | `contador` |
- **5S:** cada una mantiene el aseo y orden de su área (Taller, Tienda/bodega, oficina/Academy). **Vive en el Sistema Operativo (SO)**, no en el ERP: ya existe `sistema_operativo.auditorias_5s` (repo `lana-rosa/SO`, mismo proyecto de Supabase). No se construye en el ERP (aviso del Orquestador, 14-nov).
- **Pregunta clave para el contador:** Sara es la dueña (persona natural, régimen SIMPLE). En Colombia una persona natural no puede firmar un contrato laboral consigo misma: confirmar si Sara va como empleada (solo posible si hay sociedad, p. ej. SAS) o si sigue recibiendo pagos como **retiros del propietario (3805)** o honorarios. Igual revisar el caso de Jennifer si es socia.
- **Permisos de Manuela (APROBADO por Sara, 14-nov):** además de caja y punto de venta, acceso a **inventario de Tienda y bodega** (surtir almacén, traslados, conteos), **proveedores** (directorio) y **pedidos/órdenes a proveedores**. Las **compras y pagos** (y todo lo del Fondo Emprender) quedan **con aprobación de la administradora** (Sara o Jennifer). Implementarlo el chat 9 (Personal) con la menor modificación posible al rol `cajero` o un rol/permiso nuevo; probar que no ve contabilidad, nómina ni honorarios.
- **Crecimiento (Sara, 14-nov):** arrancan las 3 con muchas funciones; se irá contratando personal con funciones específicas según la necesidad. El diseño de roles debe permitir agregar personas por área (Tienda, Taller, Academy) sin rehacer permisos.

## Nómina electrónica (decisión de Sara, 14-nov)
Se usará la **solución gratuita de la DIAN** (se digita a mano cada mes en el portal de la DIAN). El ERP NO transmite a la DIAN: debe generar un **resumen mensual por empleado listo para copiar** (días/horas trabajadas, salario, horas extra y recargos, auxilio de transporte, incapacidades, vacaciones y licencias, deducciones de salud y pensión), en el mismo orden de los campos del formulario de la DIAN. Confirmar con el contador campos y plazo de transmisión mensual.

## Reglas
- Acceso total solo Sara y Jennifer (administrador). Cada empleado nuevo tiene su propia cuenta con su rol (`cajero`, `taller`, `contador`); nunca se comparte usuario.
- Datos personales sensibles (salud, salario): solo administradora; respetar Ley 1581.
- Lo laboral/tributario (prestaciones, seguridad social, tipo de contrato) se consulta con el contador; no decidirlo en el chat.
- Fecha clave: apertura de la tienda 13-dic-2026 (personal contratado antes).

## Datos de Sara (14-nov)
- Para la apertura: **3 empleados** = **2 tejedoras** (rol ERP `taller`, Producción) + **1 persona para atender el almacén** (rol ERP `cajero`, punto de venta y caja) + el **contador por prestación de servicios** (no es empleado: no va en nómina; se le paga con cuenta de cobro/factura y se registra como honorarios).

## Pendiente de Sara
- Contrato: los 3 empleados a **término fijo de 1 año** (decisión de Sara, 14-nov; corrigió "indefinido"). Falta: jornada (completa/medio tiempo) y salario de cada uno. Las 2 tejedoras pasan a ser empleadas: definir con el contador si dejan de pagarse por honorarios y desde qué fecha (afecta `honorarios_tejedora_nomina` y la política contable "todo lo tejido se paga como honorarios hasta abrir el local").
- Si las tejedoras siguen por honorarios o alguna pasa a contrato.


## Fase 1 — Ficha del empleado (hecha 15-nov-2026)
**Qué ya existía** (Nómina → Empleados): datos personales, contrato (tipo, ingreso, retiro, salario, horas por semana), EPS/pensión/cesantías/ARL, beneficiarios, historial de salario, préstamos, certificado laboral y documentos (hoja de vida, contrato, cédula, afiliaciones).

**Qué se agregó** (reusando la tabla `empleados`; ver `index.html`, buscar `FICHA DEL EMPLEADO`):
- Columnas nuevas en `empleados`: `cargo`, `area` (Taller, Tienda, Academy, Administración), `jornada` (completa, medio tiempo, por horas), `fecha_fin_contrato` (solo término fijo; no puede ser anterior al ingreso) y `caja_compensacion`.
- Se usa `empleados.user_id` (ya existía, vacío) como **cuenta de acceso**: el rol en el ERP se toma de `usuarios_roles`. En Editar hay un selector (no deja repetir una cuenta en dos empleados).
- Resumen en la ficha con etiquetas: área, tipo de contrato, jornada, rol del ERP, contrato por vencer (aviso a 60 días, vencido, o "falta fecha de fin" si es término fijo), documentos que faltan y afiliaciones sin dato.
- Documentos requeridos: cédula, hoja de vida, contrato, afiliación EPS, pensión, ARL y caja (la propietaria no necesita contrato). El panel de documentos lista lo que falta.
- Los campos nuevos se guardan directo en Supabase (la administradora tiene permiso por RLS); el Worker no se tocó.
- Las 3 fichas actuales quedaron con cargo y área (Sara: Academy, Jennifer: Taller, Manuela: Tienda). No se cambió ningún salario ni tipo de contrato.

**Probado:** Playwright (se ven las etiquetas, el formulario trae los 7 campos nuevos, el guardado manda los datos correctos y bloquea fecha de fin anterior al ingreso) y SQL con rollback (rechaza área inválida y fecha de fin anterior al ingreso; acepta datos válidos).

**Falta:** al crear un empleado nuevo, pedir estos campos desde el inicio; conectar cada ficha con su cuenta; cargar las 3 fichas reales de la apertura (esperando nombres, jornada y salario de Sara); contador por prestación de servicios va como tercero/honorarios, no en esta lista.

## Fase 2 — Turnos y asistencia (hecha 15-nov-2026)
**Qué ya existía:** marcar entrada y salida desde el menú (Worker `/api/pos/horas/*`, tabla `registro_horas_empleado`, hoy vacía) y la lista "Horas trabajadas" en Talento Humano. Solo lo hace quien tiene su ficha conectada con su cuenta (`empleados.user_id`).

**Qué se agregó** (Talento Humano → "🗓️ Turnos y asistencia"; en `index.html` buscar `TURNOS Y ASISTENCIA`):
- Tabla `horarios_personal` (turnos programados: empleado, fecha, entrada, salida, nota). RLS: la administradora gestiona, el contador lee, cada empleado ve solo los suyos.
- Funciones en Supabase (solo administradora): `fn_rh_guardar_turno` (no deja turnos que se crucen ni salida antes de la entrada), `fn_rh_copiar_semana` (copia sin duplicar), `fn_rh_marcacion_manual` (agregar/corregir marcación; exige motivo, queda en observaciones), `fn_rh_resumen_asistencia` (administradora y contador).
- Pantalla: cuadrícula semanal por empleado (programar varios días a la vez, editar, quitar, copiar semana anterior), festivos de Colombia marcados y, bajo cada turno, ✅ cumplió / ⏰ llegó tarde / ❌ no marcó / ➕ trabajó sin turno. Resumen del mes por persona: programadas, trabajadas, diferencia, tardanzas, ausencias y horas en domingo o festivo.
- "Horas trabajadas": botón "Corregir" por registro y formulario para agregar una marcación olvidada.
- Menú: "Mi horario" con los turnos de hoy y de los próximos días, para quien tiene cuenta conectada.
- Se arregló `fn_festivos_colombia` (daba error de tipo de dato siempre; nadie más la usaba).

**Decisiones:** "tarde" = más de 10 minutos después de la hora programada. Las horas se cuentan por la fecha de entrada en hora de Colombia. NO se calculan recargos ni horas extra con recargo: eso es laboral y queda como pregunta al contador (ver PENDIENTES); el resumen solo muestra horas y marca domingos y festivos, para pasarlo luego a Novedades de nómina a mano.

**Probado:** SQL con rollback simulando a la administradora y a un cajero (turno, cruce rechazado, horas invertidas rechazadas, marcación sin motivo rechazada, tarde 15 min, ausente, copiar semana sin duplicar, festivo 16-nov y 8-dic, el cajero no puede programar ni ver el resumen). Playwright con datos de prueba (cuadrícula, guardar varios días, error de cruce, editar, quitar, copiar, resumen mensual, corregir marcación, "Mi horario"). No se probó con datos reales ni con marcaciones reales del Worker (hoy hay 0).

**Falta:** enlazar con el turno de caja; pasar el resumen a Novedades de nómina cuando el contador defina las reglas (fase 5).

## Permisos de Manuela — rol "Líder de Tienda" (hecho 15-nov-2026)
**Cómo está armado (para sumar personas por área sin rehacer permisos):** cada puesto es un *rol personalizado* (`roles_personalizados`, con su rol base `cajero`/`taller`/`contador`) más una lista de ítems de menú extra (`permisos_default_rol_personalizado`). Al crear un usuario en Gestión de usuarios con ese rol se copian a `permisos_modulos_usuario`. Se creó **"Líder de Tienda"** (base `cajero`) y se le asignó a Manuela, con sus permisos extra: `nav-proveedores-dir` y `nav-ordenes-compra`. El rol `cajero` no se tocó. Para otra persona de Tienda, o de Taller/Academy, se crea un rol parecido y se elige al crear su usuario.

**Qué puede hacer Manuela:** caja y punto de venta (ya podía); inventario de Tienda: entrada de mercancía, etiquetas, traslados; directorio de proveedores (ver, crear, editar: el Worker ya lo permitía a cajero); **pedidos a proveedores** (nuevo): los crea y quedan "⏳ Por aprobar"; una administradora los aprueba ("Aprobar y enviar") o rechaza; ella solo puede cancelar los suyos mientras estén por aprobar; **conteo de inventario de la Tienda** (nuevo): abre la toma y cuenta; la administradora finaliza y ajusta el stock. Compras y gastos de Tienda: ya existía (pide escoger quién aprobó; sin aprobación real: pregunta en PENDIENTES).

**No puede:** ver nómina, empleados, honorarios, contabilidad, Fondo Emprender, usuarios, copia de seguridad, listas de precios ni reportes (menú oculto y tablas bloqueadas en la base de datos).

**Qué se creó en Supabase:** estado `por_aprobar` en `ordenes_compra`; funciones `fn_oc_crear_solicitud`, `fn_oc_cancelar_solicitud`, `fn_toma_guardar_conteo` (la Tienda solo cuenta Tienda). Las órdenes de compra y las tomas de inventario del Worker son solo de `administrador` y no se pueden editar desde aquí, por eso la Tienda usa estas funciones directo.

**Hueco de seguridad cerrado:** `fn_abrir_toma_inventario` y `fn_finalizar_toma_inventario` las podía llamar cualquier usuario con rol (un cajero podía cambiar el stock llamándolas directo). Ahora abrir solo lo hace la administradora (o la Tienda, solo para Tienda) y finalizar solo la administradora y solo si la toma está en proceso. El Worker las sigue usando igual.

**Hueco de seguridad pendiente (decide Sara):** 131 funciones de dinero con el mismo candado débil (ver PENDIENTES).

**Probado:** SQL con rollback como Manuela real y como Sara (crear pedido, rechazo de cliente como proveedor, sin ítems, cantidad negativa, no cancelar pedidos ajenos, abrir toma solo de Tienda, contar, no finalizar, finalizar solo Sara y una sola vez; con permisos reales de tabla ve 0 filas de empleados, nómina, honorarios, asientos, Fondo Emprender y documentos; sí ve órdenes, proveedores e inventario de Tienda). Playwright: menú de Manuela (ve Proveedores y Órdenes; no ve Nómina, Talento Humano, Contabilidad, Fondo Emprender, Usuarios), un cajero común no ve esos dos, pantallas de pedidos y de conteo para Manuela y para la administradora. No se probó con su sesión real.

## Lo que vive en el Sistema Operativo (SO), no en el ERP
- **Auditorías 5S** (`sistema_operativo.auditorias_5s`) y **SG-SST** (evaluaciones médicas, encuesta sociodemográfica): ya existen en el SO. **No se construyen en el ERP.** Si Sara pide algo de esto, mandarlo al SO.
- El ERP solo guarda lo del día a día del personal: ficha, turnos y asistencia, vacaciones y permisos, tejedoras y novedades para la nómina.

## Privacidad de las horas trabajadas (hecha 15-nov-2026, aprobada por Sara)
- Antes: cualquier usuario activo (también cajero y taller) podía leer `registro_horas_empleado`. Ahora: **cada empleada ve solo las suyas; el líder de área (`usuarios_roles.es_jefe_departamento` + `centro_costo_liderado_id`) las de los empleados de su departamento; administradoras y contador todas** (el contador para preparar la nómina; Sara lo aprobó). Nadie escribe directo: las marcaciones entran por el Worker (menú) o por `fn_rh_marcacion_manual` (administradora).
- Funciones nuevas (internas, `security definer`): `fn_mi_empleado_id()` y `fn_puede_ver_horas_empleado(empleado)`. Se usan porque una cajera o tejedora **no puede leer la tabla `empleados`**: una regla que la consultara por dentro no le mostraría nada, ni sus propias horas.
- Se corrigió "Mi horario" (fase 2): buscaba la ficha de la empleada leyendo `empleados` y a una cajera no le salía nada; ahora usa `fn_mi_empleado_id()`. La política de `horarios_personal` ("Empleado ve su horario") usa la misma función.
- Probado con SQL con rollback: Manuela (líder de Tienda) ve solo su hora y no la de Jennifer, como empleada común ve solo la suya, Sara ve todas, el contador ve todas, un usuario sin ficha ve 0 y no se puede insertar ni modificar directo. Verificado de nuevo después de aplicarlo.
- Si el Worker deja de funcionar con esto: usa la llave de servicio, que no pasa por estas reglas.

## Fase 3 — Vacaciones y permisos (hecha 15-nov-2026)
**Qué ya existía:** el saldo de vacaciones y las alertas dentro de Nómina (`fn_saldo_vacaciones`, `fn_alertas_vacaciones`: 15 días por cada 360 días, menos lo que la nómina ya descontó) y el registro de los días de vacaciones como caso especial al liquidar un período.

**Qué se agregó:**
- Tabla `solicitudes_ausencia` (tipos: vacaciones, permiso, calamidad doméstica; estados: pendiente, aprobada, rechazada, cancelada). La empleada solo ve las suyas; administradora y contador todas; el líder de área no las ve (el motivo puede ser de salud).
- Funciones (`security definer`): `fn_aus_solicitar` (valida fechas, motivo obligatorio en permiso y calamidad, no cruza con otra solicitud, máximo 45 días, no pide pasado; una administradora puede registrar a nombre de otra y queda aprobada), `fn_aus_resolver` (solo administradora; **no puede responder su propia solicitud**; rechazar exige motivo; puede ajustar los días), `fn_aus_cancelar` (la empleada cancela solo lo pendiente; la administradora también lo aprobado), `fn_aus_dias_estimados` (días hábiles lunes a sábado, sin domingos ni festivos de Colombia) y `fn_saldo_vacaciones_empleado` (el saldo propio, o el de otra persona para administradora y contador: ganados, tomados en nómina, aprobados por tomar y disponible; no baja de cero antes del ingreso).
- Pantallas: **Mi perfil → 🌴 Vacaciones y permisos** (saldo, formulario con días estimados, mis solicitudes y su respuesta) y **Talento Humano → 🌴 Vacaciones y permisos** (por responder con el saldo de la persona, próximas ausencias aprobadas, historial y el número de pendientes en el botón).
- Asistencia: un turno programado que cae en una ausencia aprobada se muestra "🌴 Vacaciones o permiso aprobado" y no cuenta como ausencia (`fn_rh_resumen_asistencia`).

**No hace (a propósito):** no descuenta ni registra nada en la nómina. Al aprobar vacaciones hay que registrar los días en la nómina del período (Nómina → Empleados → caso especial). El saldo resta lo aprobado que aún no ha pasado y asume que lo ya pasado quedó en la nómina. Las reglas laborales (días hábiles, compensación, permisos pagos) quedan como pregunta al contador.

**Probado:** SQL con rollback (Manuela solicita y ve solo las suyas; fecha pasada, permiso sin motivo, cruce, solo domingo, más de 45 días, registrar por otra y aprobar rechazados para ella; cancelar lo suyo una vez; Sara aprueba con 5 días, no se responde dos veces, no se auto-aprueba, saldo con lo aprobado, usuario sin ficha recibe un mensaje claro; ausencia aprobada = "con_permiso" y sin ella "ausente"). Playwright con datos de prueba: saldo, formulario con días estimados, errores, cancelar, sin ficha, pendientes/próximas/historial, aprobar y rechazar, contador de pendientes. No se probó con sesiones reales.

## Asistencia ↔ turno de caja (hecho 17-nov-2026, aprobado por Sara)
- **Hallazgo:** en esta base el turno de caja no es un turno de trabajo diario (el anterior duró del 19-oct al 12-nov), así que abrir/cerrar caja **no se convierte en entrada/salida**. Lo que sí se cruza es *quién abrió o cerró la caja y a qué hora* contra las horas que esa persona marcó ese día.
- **Función de solo lectura** `fn_rh_caja_vs_asistencia(desde, hasta, tolerancia = 30 min)` (administradora y contador): lee `turnos_caja` (`cajero_user_id`, `fecha_apertura`, `fecha_cierre`) y `registro_horas_empleado` (se enlaza por `empleados.user_id`). Por cada apertura y cierre dice: ✅ dentro de las horas marcadas · ⚠️ fuera de horario (cuántos minutos antes de marcar entrada o después de marcar salida) · ⚠️ ese día no marcó entrada · ℹ️ cuenta sin ficha conectada (no se puede cruzar).
- **Pantalla:** Talento Humano → Turnos y asistencia → panel "🧾 Caja y asistencia" (semana que se está viendo) y aviso si hay una caja abierta (⚠️ si lleva más de un día).
- **No toca** cómo se abre o se cierra el turno ni el Worker; no escribe en `turnos_caja` ni en las horas.
- **Verificado ya aplicado (17-nov):** con la caja real todos los movimientos son de Sara y salen "sin ficha" (su ficha no está conectada con su cuenta); Manuela no puede ver el cruce.
- **Probado:** SQL con rollback (apertura dentro de horas, cierre 40 min tarde, apertura sin entrada marcada, cuenta sin ficha, Manuela no puede ver el cruce) y Playwright con datos de prueba. Con las 3 fichas sin cuenta conectada hoy casi todo saldría "sin ficha": conectar las cuentas (Editar empleado → Cuenta de acceso) es lo que lo hace útil.

## Seguridad de las funciones de nómina, retiros, honorarios y cierre contable (hecha 17-nov-2026, aprobada por Sara)
- **Problema:** esas funciones (en Supabase, `security definer`) solo comprobaban que quien llamaba tuviera *algún* rol. Un cajero o una tejedora con su sesión podía ejecutarlas llamándolas directo aunque no viera el menú. La aplicación nunca las llama directo (las llama el Worker con la llave de servicio, que no pasa por `auth.uid()`), así que se pudieron cerrar sin romper nada. El Worker ya exigía administradora en todas.
- **Qué se hizo:** en las **20 funciones** (`fn_liquidar_empleado_periodo` ×5 versiones, `fn_liquidar_nomina_periodo`, `fn_liquidar_retiro_empleado`, `fn_eliminar_periodo_nomina`, `fn_registrar_pago_nomina`, `fn_contabilizar_liquidacion_nomina`, `fn_registrar_retiro_propietario` ×2, `fn_registrar_retiro_socia`, `fn_repartir_utilidades_entre_socias`, `fn_registrar_honorarios`, `fn_pagar_honorario_produccion` (versión vieja de 2 parámetros), `fn_cierre_contable_periodo`, `fn_reiniciar_datos_prueba`, `fn_alertas_vacaciones`, `fn_saldo_vacaciones`) el primer chequeo ahora es: si hay un usuario, debe ser **administradora** (el saldo de vacaciones: administradora o contador). Sin usuario (Worker, tareas programadas) pasa como antes. Se reescribió solo ese chequeo con `CREATE OR REPLACE` (mismas firmas, mismos permisos de ejecución).
- **No se tocó** `fn_valor_hora_honorarios`: otras funciones de costos y precios que usan Tienda y Taller la llaman, y solo devuelve el valor de la hora.
- **Probado:** prueba en seco con rollback antes de aplicar y verificación después. Manuela (cajera) es rechazada con "No autorizado" (42501) en todas las versiones con firma única; la administradora y el sistema pasan; el contador solo pasa en el saldo de vacaciones. Las versiones con varias firmas se comprobaron leyendo su código (las 20 tienen el candado nuevo y ninguna el viejo).
- **Después de esto** el candado débil queda en 111 funciones de otras áreas (ver PENDIENTES), ninguna de nómina, retiros, honorarios ni cierre contable.
- **Cómo revisarlo de nuevo:** `select proname from pg_proc where prosecdef and prosrc ilike '%fn_rol_actual() is null and not public.fn_es_tejedora()%'`.

## Cuentas conectadas con las fichas (17-nov-2026, aprobado por Sara)
- Se conectó `empleados.user_id` con la cuenta de cada persona: Sara (propietaria), Jennifer y Manuela. Contador (Hernando) no tiene ficha.
- **Qué activa:** marcar entrada y salida desde el menú y "Mi horario"; pedir vacaciones y permisos; la regla de privacidad de las horas (cada quien ve las suyas); el cruce de caja con asistencia; y la identidad propia en ventas (para detectar una venta hecha a sí misma).
- **Ajuste:** en el cruce de caja la propietaria no se marca como alerta cuando no marca horas (`estado = propietaria`, solo información).
- **Cada persona nueva:** conectar su cuenta al crear la ficha (Editar → Cuenta de acceso). Verificado con rollback: Manuela ve solo sus horas y su turno, puede pedir vacaciones, Sara aprueba el permiso de Jennifer y la apertura de caja de Manuela dentro de sus horas sale ✅.

## Acceso: recuperar contraseña y correo de Sara (18-nov-2026)
**Recuperar contraseña (hecho):** en la pantalla de entrada hay un enlace "¿Se te olvidó la contraseña?". La persona escribe su correo, Supabase le manda un enlace (`resetPasswordForEmail`, vuelve a la misma dirección del ERP) y al abrirlo aparece "Elige tu nueva contraseña" (mínimo 6 caracteres, dos veces). Al guardar se cierra la sesión temporal y se vuelve a la entrada con un aviso: **no se entra al sistema con el enlace sin cambiar la clave** (el enlace se lee antes de que Supabase lo borre: `ENTRADA_RECUPERACION`). Enlace vencido o ya usado: mensaje claro para pedir otro. El mensaje de envío es el mismo exista o no el correo. El ingreso normal no cambió.
- **Probado:** Playwright con Supabase simulado (entrada normal, pedir el enlace, demasiados correos seguidos, llegada desde el enlace, claves distintas o muy cortas, misma clave que la anterior, enlace ya usado, enlace vencido). **No se probó el correo real:** depende de la configuración de correo y de las direcciones permitidas de Supabase (Authentication → URL Configuration debe incluir la dirección del ERP); lo más fácil es que Sara o Jennifer lo prueben una vez.
- **Límite de Supabase:** si el envío de correos es el básico, pide pocos correos por hora; si falla, revisar el correo propio (SMTP) del proyecto.

**Correo mal escrito de Sara (pendiente de su decisión):**
- Hallazgo (solo lectura): hay **dos cuentas** de Sara en `auth.users`. (a) `5d148bc8…` con correo `saralmunoz1301@gmai.com` (mal escrito), entra con contraseña, es la que tiene el rol de administradora y **todo el historial** (unas 40 columnas en más de 25 tablas: asientos, bitácora contable, ventas, caja, gastos, inventario, pedidos, calendario, permisos, ficha de empleada, tejedoras…). (b) `a6f3b2c9…` con `saralmunoz1301@gmail.com`, entra con Google, **es su cuenta de clienta de la tienda web** (1 pedido pagado el 11-nov, 1 carrito, 3 mensajes, 1 cuenta de cliente). Hay una tercera parecida (`saraloaizam1301@gmail.com`) que no se tocó.
- El correo mal escrito no está en ninguna tabla del negocio: solo en la cuenta de acceso. El correcto sí está en datos del negocio (ficha, pedidos web, terceros, avisos) y no cambia.
- **Opción B (recomendada):** cambiar el correo de (a) a `saralmunoz1301+erp@gmail.com` (llega a la misma bandeja de Gmail). Probada con rollback: la contraseña, el rol y el historial no cambian; la cuenta web no se toca.
- **Opción A (correo exacto):** primero cambiar el correo interno de (b) a `saralmunoz1301+tienda@gmail.com` y luego poner el correcto en (a). Probada con rollback, pero toca la cuenta con el pedido pagado y no se sabe si la tienda web depende de ese correo: conviene que el chat Web lo confirme antes.
- **Descartado:** mover el rol a la cuenta web (obligaría a reescribir todo el historial). Nunca borrar una cuenta sin el sí de Sara.
- Cómo se aplica: se cambian `auth.users.email` y `auth.identities.identity_data` (las dos tablas deben quedar iguales); la contraseña se conserva; Sara tendrá que volver a entrar. Después, asesor de seguridad y probar la recuperación con el correo nuevo.

### Aplicado el 18-nov-2026 (miércoles 3:27 p. m., hora de Colombia), opción B, escogida por Sara
- Se cambió el correo de la cuenta del ERP (`5d148bc8…`) de `saralmunoz1301@gmai.com` a `saralmunoz1301+erp@gmail.com` en `auth.users` y en `auth.identities` (las dos quedaron iguales), en un solo paso que se cancelaba si algo no cuadraba.
- **Verificado:** misma huella de contraseña (no cambió), rol administradora activo, ficha de empleada conectada, historial intacto (95 asientos, 8 ventas POS, 4 turnos de caja, igual que antes), cuenta web `a6f3b2c9…` intacta. Sara entra con **el correo nuevo y la misma contraseña**; la recuperación de clave le llega a su bandeja normal de Gmail.
- **Asesor de seguridad (Supabase):** sin hallazgos nuevos por este cambio. Pendiente de activar en el panel: protección contra contraseñas filtradas. Quedan 33 tablas con seguridad activa y sin reglas (solo las usa el Worker) y 24 funciones públicas de la tienda web (esperado).
- **Pendiente de probar con correo real:** que Sara pida "¿Se te olvidó la contraseña?" con el correo nuevo y verifique que le llega.
