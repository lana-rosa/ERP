-- Fase 2 SENA: desembolsos del Fondo y formato «Legalización desembolso No.» (aprobado por Sara el 24-nov-2026).
-- Dos tablas nuevas; todo se escribe por funciones (administrador y contador). Reutiliza compras_requisitos_sena, fe_plan_operativo_conceptos y fondo_emprender_proyecto.
create table if not exists public.fondo_desembolsos (
  id uuid primary key default gen_random_uuid(),
  numero int not null unique,
  fecha_recibido date,
  monto numeric not null default 0,
  descripcion text,
  estado text not null default 'desembolsado' check (estado in ('solicitado','aprobado','desembolsado','pagado','legalizado','con_observaciones')),
  fecha_solicitud date,
  fecha_legalizacion date,
  notas text,
  created_at timestamptz not null default now(),
  created_by uuid default auth.uid()
);
create table if not exists public.fondo_desembolso_lineas (
  id uuid primary key default gen_random_uuid(),
  desembolso_id uuid not null references public.fondo_desembolsos(id) on delete cascade,
  compra_id uuid unique references public.compras_requisitos_sena(id),
  orden int not null default 0,
  actividad text, id_solicitud_pago text, descripcion text, proveedor text, factura text,
  monto_desembolsado numeric not null default 0, saldo_pendiente numeric not null default 0, monto_legalizado numeric not null default 0,
  base numeric not null default 0, retefuente numeric not null default 0, reteiva numeric not null default 0, reteica numeric not null default 0, otros_descuentos numeric not null default 0,
  created_at timestamptz not null default now()
);
alter table public.fondo_desembolsos enable row level security;
alter table public.fondo_desembolso_lineas enable row level security;
create policy "Admin y contador ven desembolsos" on public.fondo_desembolsos for select to authenticated using (coalesce(public.fn_rol_actual()::text, '') in ('administrador', 'contador'));
create policy "Admin y contador ven lineas de desembolsos" on public.fondo_desembolso_lineas for select to authenticated using (coalesce(public.fn_rol_actual()::text, '') in ('administrador', 'contador'));

create or replace function public.fn_fondo_permiso() returns void language plpgsql stable as $$
begin
  if auth.uid() is null or coalesce(public.fn_rol_actual()::text, '') not in ('administrador', 'contador') then raise exception 'Solo la administradora y el contador manejan los desembolsos del Fondo.' using errcode = '42501'; end if;
end $$;

create or replace function public.fn_fondo_desembolsos_listar() returns jsonb language plpgsql security definer set search_path = public stable as $$
begin
  perform public.fn_fondo_permiso();
  return coalesce((select jsonb_agg(jsonb_build_object('id', d.id, 'numero', d.numero, 'fecha_recibido', d.fecha_recibido, 'monto', d.monto, 'descripcion', d.descripcion, 'estado', d.estado,
      'lineas', (select count(*) from public.fondo_desembolso_lineas l where l.desembolso_id = d.id),
      'legalizado', (select coalesce(sum(l.monto_legalizado), 0) from public.fondo_desembolso_lineas l where l.desembolso_id = d.id)) order by d.numero desc) from public.fondo_desembolsos d), '[]'::jsonb);
end $$;

create or replace function public.fn_fondo_desembolso_crear(p_fecha date, p_monto numeric, p_descripcion text) returns jsonb language plpgsql security definer set search_path = public as $$
declare v_id uuid; v_n int;
begin
  perform public.fn_fondo_permiso();
  if p_monto is null or p_monto < 0 then raise exception 'El monto del desembolso no es válido.'; end if;
  select coalesce(max(numero), 0) + 1 into v_n from public.fondo_desembolsos;
  insert into public.fondo_desembolsos (numero, fecha_recibido, monto, descripcion) values (v_n, p_fecha, coalesce(p_monto, 0), nullif(trim(p_descripcion), '')) returning id into v_id;
  return jsonb_build_object('id', v_id, 'numero', v_n);
end $$;

create or replace function public.fn_fondo_desembolso_actualizar(p_id uuid, p_fecha date, p_monto numeric, p_descripcion text, p_estado text, p_fecha_legalizacion date) returns void language plpgsql security definer set search_path = public as $$
begin
  perform public.fn_fondo_permiso();
  if p_monto is null or p_monto < 0 then raise exception 'El monto del desembolso no es válido.'; end if;
  update public.fondo_desembolsos set fecha_recibido = p_fecha, monto = p_monto, descripcion = nullif(trim(p_descripcion), ''), estado = p_estado, fecha_legalizacion = p_fecha_legalizacion where id = p_id;
  if not found then raise exception 'No se encontró el desembolso.'; end if;
end $$;

create or replace function public.fn_fondo_desembolso_detalle(p_id uuid) returns jsonb language plpgsql security definer set search_path = public stable as $$
declare v_d jsonb;
begin
  perform public.fn_fondo_permiso();
  select to_jsonb(d) into v_d from public.fondo_desembolsos d where d.id = p_id;
  if v_d is null then raise exception 'No se encontró el desembolso.'; end if;
  return jsonb_build_object('desembolso', v_d,
    'proyecto', (select nombre_proyecto from public.fondo_emprender_proyecto limit 1),
    'lineas', coalesce((select jsonb_agg(to_jsonb(l) order by l.orden, l.created_at) from public.fondo_desembolso_lineas l where l.desembolso_id = p_id), '[]'::jsonb),
    'compras_disponibles', coalesce((select jsonb_agg(jsonb_build_object('id', r.id, 'fecha_factura', r.fecha_factura, 'numero_factura', r.numero_factura, 'monto', r.monto,
        'proveedor', t.nombre_completo, 'descripcion', g.descripcion) order by r.fecha_factura desc)
      from public.compras_requisitos_sena r left join public.terceros t on t.id = r.proveedor_tercero_id left join public.gastos_departamentales g on g.id = r.gasto_id
      where r.fuente in ('fondo', 'mixto') and not exists (select 1 from public.fondo_desembolso_lineas l where l.compra_id = r.id)), '[]'::jsonb));
end $$;

create or replace function public.fn_fondo_desembolso_agregar_compra(p_id uuid, p_compra uuid) returns void language plpgsql security definer set search_path = public as $$
begin
  perform public.fn_fondo_permiso();
  insert into public.fondo_desembolso_lineas (desembolso_id, compra_id, orden, actividad, descripcion, proveedor, factura, monto_desembolsado, monto_legalizado, base)
  select p_id, r.id, coalesce((select max(orden) from public.fondo_desembolso_lineas where desembolso_id = p_id), 0) + 1,
         (select c.concepto from public.fe_plan_operativo_conceptos c where c.id = r.actividad_plan_operativo), g.descripcion, t.nombre_completo, r.numero_factura, r.monto, r.monto, r.monto
  from public.compras_requisitos_sena r left join public.terceros t on t.id = r.proveedor_tercero_id left join public.gastos_departamentales g on g.id = r.gasto_id
  where r.id = p_compra and r.fuente in ('fondo', 'mixto');
  if not found then raise exception 'La compra no existe o no es con recursos del Fondo.'; end if;
end $$;

create or replace function public.fn_fondo_desembolso_actualizar_linea(p_linea uuid, p_datos jsonb) returns void language plpgsql security definer set search_path = public as $$
declare k text;
begin
  perform public.fn_fondo_permiso();
  for k in select jsonb_object_keys(p_datos) loop
    if k not in ('actividad','id_solicitud_pago','descripcion','proveedor','factura','monto_desembolsado','saldo_pendiente','monto_legalizado','base','retefuente','reteiva','reteica','otros_descuentos') then raise exception 'Campo no permitido: %', k; end if;
  end loop;
  update public.fondo_desembolso_lineas set
    actividad = case when p_datos ? 'actividad' then p_datos->>'actividad' else actividad end,
    id_solicitud_pago = case when p_datos ? 'id_solicitud_pago' then p_datos->>'id_solicitud_pago' else id_solicitud_pago end,
    descripcion = case when p_datos ? 'descripcion' then p_datos->>'descripcion' else descripcion end,
    proveedor = case when p_datos ? 'proveedor' then p_datos->>'proveedor' else proveedor end,
    factura = case when p_datos ? 'factura' then p_datos->>'factura' else factura end,
    monto_desembolsado = coalesce((p_datos->>'monto_desembolsado')::numeric, monto_desembolsado),
    saldo_pendiente = coalesce((p_datos->>'saldo_pendiente')::numeric, saldo_pendiente),
    monto_legalizado = coalesce((p_datos->>'monto_legalizado')::numeric, monto_legalizado),
    base = coalesce((p_datos->>'base')::numeric, base),
    retefuente = coalesce((p_datos->>'retefuente')::numeric, retefuente),
    reteiva = coalesce((p_datos->>'reteiva')::numeric, reteiva),
    reteica = coalesce((p_datos->>'reteica')::numeric, reteica),
    otros_descuentos = coalesce((p_datos->>'otros_descuentos')::numeric, otros_descuentos)
  where id = p_linea;
  if not found then raise exception 'No se encontró la línea.'; end if;
end $$;

create or replace function public.fn_fondo_desembolso_quitar_linea(p_linea uuid) returns void language plpgsql security definer set search_path = public as $$
begin
  perform public.fn_fondo_permiso();
  delete from public.fondo_desembolso_lineas where id = p_linea;
end $$;

revoke all on function public.fn_fondo_permiso(), public.fn_fondo_desembolsos_listar(), public.fn_fondo_desembolso_crear(date, numeric, text), public.fn_fondo_desembolso_actualizar(uuid, date, numeric, text, text, date),
  public.fn_fondo_desembolso_detalle(uuid), public.fn_fondo_desembolso_agregar_compra(uuid, uuid), public.fn_fondo_desembolso_actualizar_linea(uuid, jsonb), public.fn_fondo_desembolso_quitar_linea(uuid) from public, anon;
grant execute on function public.fn_fondo_permiso(), public.fn_fondo_desembolsos_listar(), public.fn_fondo_desembolso_crear(date, numeric, text), public.fn_fondo_desembolso_actualizar(uuid, date, numeric, text, text, date),
  public.fn_fondo_desembolso_detalle(uuid), public.fn_fondo_desembolso_agregar_compra(uuid, uuid), public.fn_fondo_desembolso_actualizar_linea(uuid, jsonb), public.fn_fondo_desembolso_quitar_linea(uuid) to authenticated;
