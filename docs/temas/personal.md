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
- **5S:** cada una mantiene el aseo y orden de su área (Taller, Tienda/bodega, oficina/Academy). Idea: lista de chequeo 5S por área en el ERP (diaria/semanal, con foto opcional).
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

**Falta:** enlazar con el turno de caja; privacidad de `registro_horas_empleado` (hoy la lee cualquier usuario activo); pasar el resumen a Novedades de nómina cuando el contador defina las reglas (fase 5).
