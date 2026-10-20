-- Ferias (20-oct-2026, a pedido de Sara): datos de cada feria (fecha, lugar, contacto, costo del stand), ventas marcadas con su feria
-- y «producto rápido» para vender en una feria algo que no está en el inventario.
--  * tabla ferias + ventas_pos.feria_id;
--  * fn_ferias_listar / fn_feria_guardar / fn_feria_resumen / fn_marcar_venta_feria;
--  * fn_producto_rapido: crea el producto tejido (código de barras interno incluido) y le pone las existencias que se vendieron.
-- El MCP de Supabase se queda esperando con SQL que contenga las palabras de borrar: este archivo no las usa.
create table if not exists public.ferias (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  lugar text,
  fecha_inicio date,
  fecha_fin date,
  contacto_nombre text,
  contacto_telefono text,
  contacto_correo text,
  costo_stand numeric(14,2) not null default 0 check (costo_stand >= 0),
  notas text,
  creada_por uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint ferias_fechas check (fecha_fin is null or fecha_inicio is null or fecha_fin >= fecha_inicio)
);
alter table public.ferias enable row level security;
revoke all on public.ferias from anon, authenticated;
alter table public.ventas_pos add column if not exists feria_id uuid references public.ferias(id);
create index if not exists ventas_pos_feria_idx on public.ventas_pos (feria_id) where feria_id is not null;

create or replace function public.fn_feria_rol(p_solo_admin boolean default false) returns text language plpgsql stable security definer set search_path to 'public' as $$
declare v text := coalesce(public.fn_rol_actual()::text, '');
begin
  if auth.uid() is null or v not in ('administrador', 'cajero', 'taller') or (p_solo_admin and v <> 'administrador') then
    raise exception 'No tienes permiso para esto en Ferias.';
  end if;
  return v;
end $$;

create or replace function public.fn_ferias_listar() returns jsonb language plpgsql stable security definer set search_path to 'public' as $$
declare v_rol text := public.fn_feria_rol();
begin
  return (select coalesce(jsonb_agg(to_jsonb(x) order by x.fecha_orden desc nulls last, x.nombre), '[]'::jsonb) from (
    select f.id, f.nombre, f.lugar, f.fecha_inicio, f.fecha_fin, f.contacto_nombre, f.contacto_telefono, f.contacto_correo, f.notas,
           case when v_rol = 'administrador' then f.costo_stand end as costo_stand,
           coalesce(f.fecha_inicio, f.created_at::date) as fecha_orden,
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

create or replace function public.fn_marcar_venta_feria(p_consecutivo text, p_feria_id uuid) returns void language plpgsql security definer set search_path to 'public' as $$
begin
  perform public.fn_feria_rol();
  if not exists (select 1 from public.ferias where id = p_feria_id) then raise exception 'La feria no existe.'; end if;
  update public.ventas_pos set feria_id = p_feria_id where consecutivo = p_consecutivo;
  if not found then raise exception 'No se encontró la venta %.', p_consecutivo; end if;
end $$;

create or replace function public.fn_feria_resumen(p_feria_id uuid) returns jsonb language plpgsql stable security definer set search_path to 'public' as $$
declare v_rol text := public.fn_feria_rol(); v_f record; v_total numeric; v_n int; v_costo numeric; v_pagos jsonb; v_prod jsonb;
begin
  select * into v_f from public.ferias where id = p_feria_id;
  if v_f.id is null then raise exception 'La feria no existe.'; end if;
  select count(*), coalesce(sum(total), 0) into v_n, v_total from public.ventas_pos where feria_id = p_feria_id and estado <> 'anulada';
  select coalesce(sum(d.cantidad * coalesce(i.costo_promedio_ponderado, 0)), 0) into v_costo
    from public.ventas_pos_detalle d join public.ventas_pos v on v.id = d.venta_id left join public.inventario_items i on i.id = d.inventario_item_id
    where v.feria_id = p_feria_id and v.estado <> 'anulada';
  select coalesce(jsonb_object_agg(metodo_pago, monto), '{}'::jsonb) into v_pagos from (
    select p.metodo_pago, sum(p.monto) monto from public.ventas_pos_pagos p join public.ventas_pos v on v.id = p.venta_id
    where v.feria_id = p_feria_id and v.estado <> 'anulada' group by 1) q;
  select coalesce(jsonb_agg(jsonb_build_object('descripcion', descripcion, 'cantidad', cantidad, 'total', total) order by cantidad desc, descripcion), '[]'::jsonb) into v_prod from (
    select d.descripcion, sum(d.cantidad) cantidad, sum(d.subtotal_linea) total from public.ventas_pos_detalle d join public.ventas_pos v on v.id = d.venta_id
    where v.feria_id = p_feria_id and v.estado <> 'anulada' group by 1) q2;
  return jsonb_build_object('feria', jsonb_build_object('id', v_f.id, 'nombre', v_f.nombre), 'n_ventas', v_n, 'total_vendido', v_total, 'por_metodo', v_pagos, 'productos', v_prod,
    'costo_productos', case when v_rol = 'administrador' then round(v_costo) end,
    'costo_stand', case when v_rol = 'administrador' then v_f.costo_stand end,
    'resultado', case when v_rol = 'administrador' then round(v_total - v_costo - v_f.costo_stand) end);
end $$;

-- Producto tejido nuevo para vender ya (por ejemplo en una feria): queda en el inventario de la Tienda con código de barras interno y las existencias que se vendieron.
create or replace function public.fn_producto_rapido(p_nombre text, p_precio numeric, p_categoria_id uuid, p_cantidad numeric) returns jsonb
language plpgsql security definer set search_path to 'public' as $$
declare v_nombre text := nullif(trim(coalesce(p_nombre, '')), ''); v_cc uuid; v_id uuid; v_sku text;
begin
  if auth.uid() is null or coalesce(public.fn_rol_actual()::text, '') not in ('administrador', 'taller') then
    raise exception 'Los productos nuevos los crean el Taller y la administradora.';
  end if;
  if v_nombre is null then raise exception 'Escribe el nombre del producto.'; end if;
  if coalesce(p_precio, 0) <= 0 then raise exception 'Escribe el precio de venta.'; end if;
  if coalesce(p_cantidad, 0) <= 0 or p_cantidad > 500 then raise exception 'Escribe cuántas unidades hay.'; end if;
  if exists (select 1 from public.inventario_items where activo and tipo::text = 'producto_terminado' and lower(nombre) = lower(v_nombre)) then
    raise exception 'Ya existe un producto llamado «%»: búscalo en la lista.', v_nombre;
  end if;
  select id into v_cc from public.centros_costo where codigo = '01';
  v_sku := public.fn_siguiente_sku_interno();
  insert into public.inventario_items (nombre, sku, tipo, categoria_id, unidad_medida, centro_costo_id, precio_venta, costo_promedio_ponderado, stock_actual, stock_minimo, activo)
  values (left(v_nombre, 150), v_sku, 'producto_terminado', p_categoria_id, 'unidad', v_cc, p_precio, 0, 0, 0, true)
  returning id into v_id;
  perform public.fn_mover_stock(v_id, p_cantidad, 'ajuste_manual', 'Producto agregado al vender en una feria (falta su ficha técnica)');
  return jsonb_build_object('id', v_id, 'nombre', left(v_nombre, 150), 'sku', v_sku, 'precio', p_precio, 'stock', p_cantidad);
end $$;

do $mig$ begin
  revoke all on function public.fn_feria_rol(boolean) from public, anon;
  revoke all on function public.fn_ferias_listar() from public, anon;
  revoke all on function public.fn_feria_guardar(uuid, jsonb) from public, anon;
  revoke all on function public.fn_marcar_venta_feria(text, uuid) from public, anon;
  revoke all on function public.fn_feria_resumen(uuid) from public, anon;
  revoke all on function public.fn_producto_rapido(text, numeric, uuid, numeric) from public, anon;
  grant execute on function public.fn_ferias_listar() to authenticated;
  grant execute on function public.fn_feria_guardar(uuid, jsonb) to authenticated;
  grant execute on function public.fn_marcar_venta_feria(text, uuid) to authenticated;
  grant execute on function public.fn_feria_resumen(uuid) to authenticated;
  grant execute on function public.fn_producto_rapido(text, numeric, uuid, numeric) to authenticated;
end $mig$;
