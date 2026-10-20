-- Costo del stand de una feria como gasto contable (20-oct-2026, a pedido de Sara).
-- Usa fn_registrar_gasto_local (caja, movimiento, asiento 5235 contra el medio de pago y gasto departamental), una sola vez por feria.
alter table public.ferias add column if not exists gasto_id uuid references public.gastos_departamentales(id);
alter table public.ferias add column if not exists gasto_registrado_at timestamptz;

create or replace function public.fn_conceptos_gasto_local() returns jsonb language sql immutable as $$
  select '[
    {"clave":"arriendo","nombre":"Arrendamiento del local","grupo":"Local","cuenta":"5120","reparto":"tercios"},
    {"clave":"energia","nombre":"Energía (luz)","grupo":"Servicios públicos","cuenta":"5135","reparto":"tercios"},
    {"clave":"acueducto","nombre":"Acueducto y alcantarillado (agua)","grupo":"Servicios públicos","cuenta":"5135","reparto":"tercios"},
    {"clave":"gas","nombre":"Gas","grupo":"Servicios públicos","cuenta":"5135","reparto":"tercios"},
    {"clave":"aseo","nombre":"Aseo y vigilancia","grupo":"Servicios públicos","cuenta":"5135","reparto":"tercios"},
    {"clave":"internet","nombre":"Internet","grupo":"Comunicaciones","cuenta":"5135","reparto":"tercios"},
    {"clave":"telefonia","nombre":"Celular / telefonía","grupo":"Comunicaciones","cuenta":"5135","reparto":"tercios"},
    {"clave":"software","nombre":"Software y suscripciones (Claude, etc.)","grupo":"Administración","cuenta":"5195","reparto":"tercios"},
    {"clave":"papeleria","nombre":"Papelería","grupo":"Administración","cuenta":"5195","reparto":"tercios"},
    {"clave":"publicidad","nombre":"Publicidad (Meta, pauta)","grupo":"Ventas","cuenta":"5235","reparto":"tercios"},
    {"clave":"stand_feria","nombre":"Stand de feria","grupo":"Ventas","cuenta":"5235","reparto":"01"},
    {"clave":"otros","nombre":"Otros gastos del local","grupo":"Otros","cuenta":"5195","reparto":"tercios"}
  ]'::jsonb;
$$;

create or replace function public.fn_ferias_listar() returns jsonb language plpgsql stable security definer set search_path to 'public' as $$
declare v_rol text := public.fn_feria_rol();
begin
  return (select coalesce(jsonb_agg(to_jsonb(x) order by x.fecha_orden desc nulls last, x.nombre), '[]'::jsonb) from (
    select f.id, f.nombre, f.lugar, f.fecha_inicio, f.fecha_fin, f.contacto_nombre, f.contacto_telefono, f.contacto_correo, f.notas,
           case when v_rol = 'administrador' then f.costo_stand end as costo_stand,
           coalesce(f.fecha_inicio, f.created_at::date) as fecha_orden,
           case when v_rol = 'administrador' then (f.gasto_id is not null) end as gasto_registrado,
           (select count(*) from public.ventas_pos v where v.feria_id = f.id and v.estado <> 'anulada') as n_ventas,
           (select coalesce(sum(v.total), 0) from public.ventas_pos v where v.feria_id = f.id and v.estado <> 'anulada') as total_vendido
    from public.ferias f) x);
end $$;

create or replace function public.fn_feria_guardar(p_id uuid, p_datos jsonb) returns uuid language plpgsql security definer set search_path to 'public' as $$
declare v_id uuid := p_id; v_nombre text := nullif(trim(coalesce(p_datos->>'nombre', '')), '');
begin
  perform public.fn_feria_rol(true);
  if v_nombre is null then raise exception 'Escribe el nombre de la feria.'; end if;
  if v_id is null then
    insert into public.ferias (nombre, lugar, fecha_inicio, fecha_fin, contacto_nombre, contacto_telefono, contacto_correo, costo_stand, notas, creada_por)
    values (left(v_nombre, 150), left(nullif(trim(coalesce(p_datos->>'lugar', '')), ''), 200), nullif(p_datos->>'fecha_inicio', '')::date, nullif(p_datos->>'fecha_fin', '')::date,
            left(nullif(trim(coalesce(p_datos->>'contacto_nombre', '')), ''), 120), left(nullif(trim(coalesce(p_datos->>'contacto_telefono', '')), ''), 40),
            left(nullif(trim(coalesce(p_datos->>'contacto_correo', '')), ''), 120), coalesce(nullif(p_datos->>'costo_stand', '')::numeric, 0),
            left(nullif(trim(coalesce(p_datos->>'notas', '')), ''), 1000), auth.uid())
    returning id into v_id;
  else
    if exists (select 1 from public.ferias where id = v_id and gasto_id is not null and costo_stand <> coalesce(nullif(p_datos->>'costo_stand', '')::numeric, 0)) then
      raise exception 'El costo del stand ya se registró como gasto: no se puede cambiar aquí.';
    end if;
    update public.ferias set nombre = left(v_nombre, 150), lugar = left(nullif(trim(coalesce(p_datos->>'lugar', '')), ''), 200),
      fecha_inicio = nullif(p_datos->>'fecha_inicio', '')::date, fecha_fin = nullif(p_datos->>'fecha_fin', '')::date,
      contacto_nombre = left(nullif(trim(coalesce(p_datos->>'contacto_nombre', '')), ''), 120), contacto_telefono = left(nullif(trim(coalesce(p_datos->>'contacto_telefono', '')), ''), 40),
      contacto_correo = left(nullif(trim(coalesce(p_datos->>'contacto_correo', '')), ''), 120), costo_stand = coalesce(nullif(p_datos->>'costo_stand', '')::numeric, 0),
      notas = left(nullif(trim(coalesce(p_datos->>'notas', '')), ''), 1000), updated_at = now()
    where id = v_id;
    if not found then raise exception 'La feria no existe.'; end if;
  end if;
  return v_id;
end $$;

create or replace function public.fn_registrar_stand_feria(p_feria_id uuid, p_metodo_pago text, p_caja text, p_aprobado_por text, p_turno_id uuid default null) returns uuid
language plpgsql security definer set search_path to 'public' as $$
declare v_f record; v_gasto uuid;
begin
  perform public.fn_feria_rol(true);
  select * into v_f from public.ferias where id = p_feria_id for update;
  if v_f.id is null then raise exception 'La feria no existe.'; end if;
  if v_f.gasto_id is not null then raise exception 'El costo del stand de esta feria ya se registró como gasto.'; end if;
  if coalesce(v_f.costo_stand, 0) <= 0 then raise exception 'Escribe primero el costo del stand en la feria.'; end if;
  v_gasto := public.fn_registrar_gasto_local('stand_feria', v_f.nombre || coalesce(' (' || to_char(v_f.fecha_inicio, 'YYYY-MM-DD') || ')', ''),
              v_f.costo_stand, p_metodo_pago, p_aprobado_por, p_turno_id, '01', p_caja, coalesce(v_f.fecha_inicio, current_date));
  update public.ferias set gasto_id = v_gasto, gasto_registrado_at = now(), updated_at = now() where id = p_feria_id;
  return v_gasto;
end $$;
revoke all on function public.fn_registrar_stand_feria(uuid, text, text, text, uuid) from public, anon;
grant execute on function public.fn_registrar_stand_feria(uuid, text, text, text, uuid) to authenticated;
