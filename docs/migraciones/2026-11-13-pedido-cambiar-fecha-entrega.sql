-- Cambiar la fecha de entrega de un pedido por redes ya registrado, con historial (no se sobrescribe sin rastro).
create table if not exists public.pedidos_canal_fecha_historial (
  id uuid primary key default gen_random_uuid(),
  pedido_id uuid not null references public.pedidos_canal_venta(id) on delete cascade,
  fecha_anterior date,
  fecha_nueva date not null,
  motivo_tipo text not null check (motivo_tipo in ('cliente', 'material', 'otro')),
  motivo text,
  cambiado_por uuid,
  created_at timestamptz not null default now()
);
create index if not exists idx_pcfh_pedido on public.pedidos_canal_fecha_historial(pedido_id, created_at);
alter table public.pedidos_canal_fecha_historial enable row level security;
create policy "ver historial de fechas" on public.pedidos_canal_fecha_historial for select
  using (exists (select 1 from public.usuarios_roles ur where ur.user_id = auth.uid() and ur.activo = true and ur.rol::text in ('administrador', 'cajero', 'contador', 'taller')));

create or replace function public.fn_cambiar_fecha_entrega_pedido(p_pedido_id uuid, p_fecha date, p_motivo_tipo text, p_motivo text default null)
returns jsonb language plpgsql security definer set search_path to 'public' as $$
declare v record; v_nombre text;
begin
  if auth.uid() is null or coalesce(public.fn_rol_actual()::text, '') not in ('administrador', 'cajero') then
    raise exception 'No tienes permiso para cambiar la fecha de entrega de un pedido.' using errcode = '42501';
  end if;
  if p_fecha is null then raise exception 'Escribe la nueva fecha de entrega.'; end if;
  if p_motivo_tipo not in ('cliente', 'material', 'otro') then raise exception 'Elige el motivo del cambio.'; end if;
  if p_motivo_tipo = 'otro' and length(trim(coalesce(p_motivo, ''))) < 5 then raise exception 'Escribe el motivo del cambio de fecha.'; end if;
  select * into v from public.pedidos_canal_venta where id = p_pedido_id for update;
  if v.id is null then raise exception 'Pedido no encontrado'; end if;
  if v.estado::text = 'entregado' then raise exception 'Este pedido ya se entregó: la fecha de entrega no se puede cambiar.'; end if;
  if v.fecha_estimada_entrega is not distinct from p_fecha then raise exception 'Esa ya es la fecha de entrega del pedido.'; end if;
  insert into public.pedidos_canal_fecha_historial (pedido_id, fecha_anterior, fecha_nueva, motivo_tipo, motivo, cambiado_por)
  values (p_pedido_id, v.fecha_estimada_entrega, p_fecha, p_motivo_tipo, nullif(trim(p_motivo), ''), auth.uid());
  update public.pedidos_canal_venta set fecha_estimada_entrega = p_fecha, updated_at = now() where id = p_pedido_id;
  -- La copia que ve el Taller (Pedidos por elaborar / trazabilidad) usa la fecha nueva
  update public.solicitudes_elaboracion_taller set fecha_entrega_estimada = p_fecha, updated_at = now() where pedido_canal_id = p_pedido_id;
  return jsonb_build_object('fecha_anterior', v.fecha_estimada_entrega, 'fecha_nueva', p_fecha);
end $$;

create or replace function public.fn_historial_fecha_entrega_pedido(p_pedido_id uuid)
returns jsonb language plpgsql stable security definer set search_path to 'public' as $$
begin
  if coalesce(public.fn_rol_actual()::text, '') not in ('administrador', 'cajero', 'contador', 'taller') then
    raise exception 'No tienes acceso a los pedidos.';
  end if;
  return (select coalesce(jsonb_agg(jsonb_build_object('fecha_anterior', h.fecha_anterior, 'fecha_nueva', h.fecha_nueva, 'motivo_tipo', h.motivo_tipo,
            'motivo', h.motivo, 'cuando', h.created_at, 'quien', (select u.nombre_completo from public.usuarios_roles u where u.user_id = h.cambiado_por limit 1)) order by h.created_at), '[]'::jsonb)
          from public.pedidos_canal_fecha_historial h where h.pedido_id = p_pedido_id);
end $$;

-- Cumplimiento de entregas contra la fecha VIGENTE. Si hubo retraso pero la última fecha la pidió la clienta, no cuenta como incumplimiento.
create or replace function public.fn_cumplimiento_entregas(p_desde date, p_hasta date)
returns jsonb language plpgsql stable security definer set search_path to 'public' as $$
begin
  if coalesce(public.fn_rol_actual()::text, '') not in ('administrador', 'contador') then raise exception 'No tienes acceso a este indicador.'; end if;
  return (
    with ent as (
      select p.id, p.consecutivo, p.fecha_estimada_entrega fecha_vigente,
             (select min(h.created_at) from public.pedidos_canal_historial h where h.pedido_id = p.id and h.estado = 'entregado')::date entregado_el,
             (select h.motivo_tipo from public.pedidos_canal_fecha_historial h where h.pedido_id = p.id order by h.created_at desc limit 1) ultimo_motivo
      from public.pedidos_canal_venta p
      where p.estado::text = 'entregado' and p.fecha_estimada_entrega is not null
    ), f as (select * from ent where entregado_el between p_desde and p_hasta)
    select jsonb_build_object(
      'entregados_con_fecha', count(*),
      'a_tiempo', count(*) filter (where entregado_el <= fecha_vigente),
      'tarde_por_nosotros', count(*) filter (where entregado_el > fecha_vigente),
      'cambios_pedidos_por_la_clienta', (select count(*) from public.pedidos_canal_fecha_historial h where h.motivo_tipo = 'cliente' and h.created_at::date between p_desde and p_hasta),
      'cambios_por_nosotros', (select count(*) from public.pedidos_canal_fecha_historial h where h.motivo_tipo <> 'cliente' and h.created_at::date between p_desde and p_hasta))
    from f);
end $$;
