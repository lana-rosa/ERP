-- Entregas del Fondo Emprender para todo el plazo del contrato (acta de inicio 6-nov-2026 → 6-nov-2027). Idempotente.
-- Fechas: informes contables, actas e informes de producción el día 5 de cada mes (o siguiente día hábil); bimestrales el día 2 (o siguiente hábil);
-- visitas de interventoría cada 4 meses desde el acta (fecha aproximada); fin del plazo 6-nov-2027. Festivos 2027 (Ley Emiliani) dentro de la consulta.
with fest(f) as (values ('2027-01-01'::date),('2027-01-11'),('2027-03-22'),('2027-03-25'),('2027-03-26'),('2027-05-10'),('2027-05-31'),('2027-06-07'),('2027-07-05'),('2027-07-20'),('2027-08-16'),('2027-10-18'),('2027-11-01'),('2027-11-15'),('2027-12-08')),
habiles as (select d::date d from generate_series('2027-01-01'::date, '2027-12-31'::date, '1 day') d where extract(isodow from d) < 6 and d::date not in (select f from fest)),
meses(n, nombre) as (values (1,'enero'),(2,'febrero'),(3,'marzo'),(4,'abril'),(5,'mayo'),(6,'junio'),(7,'julio'),(8,'agosto'),(9,'septiembre'),(10,'octubre'),(11,'noviembre'),(12,'diciembre')),
mensuales as (
  select (select min(d) from habiles where d >= make_date(2027, m.n, 5)) fecha, p.nombre mes_informe
  from meses m join meses p on p.n = m.n - 1 where m.n between 2 and 11),
items(orden, plantilla, descripcion) as (values
  (1, 'Informe contable de %s (actividad 98)', 'Plataforma SENA, actividad 98: estado de situación financiera, resultados, extracto y conciliación solo del Fondo. Prepara: Contabilidad. Revisa antes: Juan Pablo (asesor SENA). PDF sin caracteres especiales en el nombre.'),
  (2, 'Acta de seguimiento de %s (actividad 90)', 'Acta mensual de seguimiento, actividad 90 en la plataforma SENA.'),
  (3, 'Informe de producción y ventas de %s', 'Indicadores de producción del mes en el formato «informe de producción y ventas».')),
bimestrales(t, nombre) as (values ('2027-03-02'::date,'enero-febrero'),('2027-05-02','marzo-abril'),('2027-07-02','mayo-junio'),('2027-09-02','julio-agosto'),('2027-11-02','septiembre-octubre')),
nuevos as (
  select format(E'\U0001F3E6 Entrega Fondo Emprender — ' || i.plantilla, m.mes_informe) titulo, i.descripcion, m.fecha
  from mensuales m cross join items i
  union all
  select E'\U0001F3E6 Entrega Fondo Emprender — Informe bimestral ' || b.nombre || ' a la interventora', 'Informe bimestral de ejecución a la interventora (día 2 del mes siguiente al bimestre, o siguiente día hábil). Revisión previa de Juan Pablo.', (select min(d) from habiles where d >= b.t) from bimestrales b
  union all select E'\U0001F3E6 Entrega Fondo Emprender — Visita 2 de interventoría: tener todo listo (fecha aproximada, confirmar con la interventora)', 'Segunda visita: cada 4 meses desde el acta de inicio (6-nov-2026). Fecha calculada; la interventora puede programarla otro día.', '2027-03-06'::date
  union all select E'\U0001F3E6 Entrega Fondo Emprender — Visita 3 de interventoría: tener todo listo (fecha aproximada, confirmar con la interventora)', 'Tercera visita: cada 4 meses desde el acta de inicio (6-nov-2026). Fecha calculada; la interventora puede programarla otro día.', '2027-07-06'::date
  union all select E'\U0001F3E6 Entrega Fondo Emprender — Fin del plazo de ejecución del contrato FE-0392-2026 (12 meses)', 'El plazo de 12 meses termina el 6-nov-2027 (acta de inicio del 6-nov-2026). Todo debe estar ejecutado y legalizado; una prórroga se pide antes y puede ser de máximo 3 meses.', '2027-11-06'::date)
insert into public.eventos_calendario (titulo, descripcion, tipo, fecha_inicio, fecha_fin, recordatorio_minutos_antes, creado_por)
select n.titulo, n.descripcion, 'otro', (n.fecha::text || ' 08:00-05')::timestamptz, (n.fecha::text || ' 09:00-05')::timestamptz, 2880, '5d148bc8-f5d2-45bb-86ee-910f274d7f2d'
from nuevos n where not exists (select 1 from public.eventos_calendario e where e.titulo = n.titulo);
