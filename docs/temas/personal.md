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

## Reglas
- Acceso total solo Sara y Jennifer (administrador). Cada empleado nuevo tiene su propia cuenta con su rol (`cajero`, `taller`, `contador`); nunca se comparte usuario.
- Datos personales sensibles (salud, salario): solo administradora; respetar Ley 1581.
- Lo laboral/tributario (prestaciones, seguridad social, tipo de contrato) se consulta con el contador; no decidirlo en el chat.
- Fecha clave: apertura de la tienda 13-dic-2026 (personal contratado antes).

## Datos de Sara (14-nov)
- Para la apertura: **3 empleados** + el **contador por prestación de servicios** (no es empleado: no va en nómina; se le paga con cuenta de cobro/factura y se registra como honorarios).

## Pendiente de Sara
- Tipo de contrato de los 3 empleados (término fijo/indefinido, tiempo completo/medio) y cargos (¿cajera/vendedora, taller?).
- Si las tejedoras siguen por honorarios o alguna pasa a contrato.
- Proveedor de nómina electrónica (preguntar a Hernando).
