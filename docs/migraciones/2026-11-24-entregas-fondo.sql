-- Entregas del Fondo Emprender (reunión 24-nov-2026): se guardan en el calendario del equipo (eventos_calendario, tipo 'otro',
-- título que empieza por "🏦 Entrega Fondo Emprender") con recordatorio 2 días antes. Sin tablas nuevas.
create or replace function public.fn_entregas_fondo_proximas(p_dias int default 7)
returns jsonb language plpgsql security definer set search_path = public stable as $$
begin
  if coalesce(public.fn_rol_actual()::text, '') not in ('administrador', 'contador') then return '[]'::jsonb; end if;
  return coalesce((select jsonb_agg(jsonb_build_object('id', id, 'titulo', titulo, 'descripcion', descripcion, 'fecha_inicio', fecha_inicio,
      'fecha_fin', fecha_fin, 'dias', ceil(extract(epoch from (fecha_inicio - now())) / 86400.0)::int) order by fecha_inicio)
    from public.eventos_calendario
    where titulo like E'\U0001F3E6 Entrega Fondo Emprender%' and fecha_inicio <= now() + make_interval(days => p_dias)), '[]'::jsonb);
end $$;

create or replace function public.fn_entrega_fondo_marcar(p_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if coalesce(public.fn_rol_actual()::text, '') not in ('administrador', 'contador') then raise exception 'Sin permiso.' using errcode = '42501'; end if;
  update public.eventos_calendario set titulo = E'✅ ' || titulo, recordatorio_minutos_antes = null, updated_at = now()
    where id = p_id and titulo like E'\U0001F3E6 Entrega Fondo Emprender%';
  if not found then raise exception 'No se encontró la entrega.'; end if;
end $$;

revoke all on function public.fn_entregas_fondo_proximas(int), public.fn_entrega_fondo_marcar(uuid) from public, anon;
grant execute on function public.fn_entregas_fondo_proximas(int), public.fn_entrega_fondo_marcar(uuid) to authenticated;

-- Siembra (08:00 hora de Colombia). Recordatorio de 2 días = 2880 minutos.
insert into public.eventos_calendario (titulo, descripcion, tipo, fecha_inicio, fecha_fin, recordatorio_minutos_antes, creado_por)
select v.t, v.d, 'otro', v.f::timestamptz, v.f::timestamptz + interval '1 hour', 2880, '5d148bc8-f5d2-45bb-86ee-910f274d7f2d'
from (values
  (E'\U0001F3E6 Entrega Fondo Emprender — Informe contable de noviembre (actividad 98)', 'Plataforma SENA, actividad 98: estado de situación financiera, resultados, extracto y conciliación solo del Fondo. Prepara: Contabilidad. Revisa antes: Juan Pablo (asesor SENA). PDF sin caracteres especiales en el nombre.', '2026-12-04 08:00-05'),
  (E'\U0001F3E6 Entrega Fondo Emprender — Acta de seguimiento de noviembre (actividad 90)', 'Acta mensual de seguimiento, actividad 90 en la plataforma SENA (primeros 8 días del mes).', '2026-12-07 08:00-05'),
  (E'\U0001F3E6 Entrega Fondo Emprender — Informe de producción y ventas de noviembre', 'Indicadores de producción del mes en el formato «informe de producción y ventas».', '2026-12-07 08:00-05'),
  (E'\U0001F3E6 Entrega Fondo Emprender — Informe bimestral noviembre-diciembre a la interventora', 'Primer informe bimestral (nov+dic). La interventora lo recibe hacia el 2-ene (sábado); se entrega el lunes 4-ene. Revisión previa de Juan Pablo.', '2027-01-04 08:00-05'),
  (E'\U0001F3E6 Entrega Fondo Emprender — Informe contable de diciembre (actividad 98)', 'Plataforma SENA, actividad 98. Primeros 8 días del mes.', '2027-01-05 08:00-05'),
  (E'\U0001F3E6 Entrega Fondo Emprender — Acta de seguimiento de diciembre (actividad 90)', 'Acta mensual de seguimiento, actividad 90.', '2027-01-05 08:00-05'),
  (E'\U0001F3E6 Entrega Fondo Emprender — Informe de producción y ventas de diciembre', 'Indicadores de producción del mes.', '2027-01-05 08:00-05')
) as v(t, d, f)
where not exists (select 1 from public.eventos_calendario e where e.titulo = v.t);
