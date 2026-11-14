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
| **Sara** (propietaria) | Tejedora + Administración y contabilidad + Líder de Lana Rosa Academy | Administración, manejo contable de la mano con el contador; lidera la Academy apoyada en Claude | `administrador` |
| **Jennifer** | Tejedora + Líder del Taller | Redes sociales, fotos de productos, actualizar productos en la web; mantenimiento del entorno digital (web, CRM, ERP) con Claude | `administrador` |
| **Manuela** | Líder de la Tienda | Inventarios (surtir almacén, bodega), proveedores, caja, atención al público | `cajero` (+ permisos de inventario/proveedores a revisar) |
| Contador (Hernando) | Prestación de servicios | Contabilidad e impuestos | `contador` |
- **5S:** cada una mantiene el aseo y orden de su área (Taller, Tienda/bodega, oficina/Academy). Idea: lista de chequeo 5S por área en el ERP (diaria/semanal, con foto opcional).
- **Pregunta clave para el contador:** Sara es la dueña (persona natural, régimen SIMPLE). En Colombia una persona natural no puede firmar un contrato laboral consigo misma: confirmar si Sara va como empleada (solo posible si hay sociedad, p. ej. SAS) o si sigue recibiendo pagos como **retiros del propietario (3805)** o honorarios. Igual revisar el caso de Jennifer si es socia.
- Manuela necesita poder manejar inventario, bodega y proveedores; hoy el rol `cajero` solo ve el inventario de la Tienda. Definir permisos exactos (¿compras?, ¿pagos a proveedores?: el dinero y las compras del Fondo Emprender deberían quedar con aprobación de la administradora).

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

