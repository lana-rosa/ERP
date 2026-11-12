-- Producción: asignar tejedora a la orden, imágenes de referencia (hasta 3), ficha/patrones/insumos sugeridos de la orden.

alter table public.ordenes_produccion add column if not exists imagenes_referencia jsonb not null default '[]'::jsonb;

-- 1) Asignar tejedora (solo administradora). Usa la misma tejedora del paso a paso (produccion_fichas),
--    así "Mi producción", mano de obra y honorarios ya la reconocen.
create or replace function public.fn_op_asignar_tejedora(p_orden_id uuid, p_tipo text, p_tejedora_id uuid)
returns void language plpgsql security definer set search_path to 'public' as $$
declare v_emp uuid; v_ter uuid; v_estado text;
begin
  if auth.uid() is null or coalesce(public.fn_rol_actual()::text, '') <> 'administrador' then
    raise exception 'Solo la administradora asigna tejedoras a las órdenes.' using errcode = '42501';
  end if;
  select estado::text into v_estado from public.ordenes_produccion where id = p_orden_id;
  if v_estado is null then raise exception 'No existe esa orden de producción.'; end if;
  if v_estado <> 'en_proceso' then raise exception 'Solo se asigna tejedora a órdenes en proceso.'; end if;
  if p_tejedora_id is not null then
    if p_tipo = 'e' then
      if not exists (select 1 from public.empleados where id = p_tejedora_id and activo) then raise exception 'Esa tejedora no está activa.'; end if;
      v_emp := p_tejedora_id;
    elsif p_tipo = 't' then
      if not exists (select 1 from public.terceros where id = p_tejedora_id and es_tejedora_externa and activo) then raise exception 'Esa tejedora externa no está activa.'; end if;
      v_ter := p_tejedora_id;
    else raise exception 'Tipo de tejedora no válido.'; end if;
  end if;
  insert into public.produccion_fichas (orden_id, tejedora_id, tejedora_tercero_id, tejedora_nombre)
  values (p_orden_id, v_emp, v_ter, null)
  on conflict (orden_id) do update
    set tejedora_id = excluded.tejedora_id, tejedora_tercero_id = excluded.tejedora_tercero_id,
        tejedora_nombre = null, updated_at = now(), updated_by = auth.uid();
end $$;

-- 2) Imágenes de referencia (hasta 3). Administradora y Taller.
create or replace function public.fn_op_guardar_imagenes(p_orden_id uuid, p_imagenes jsonb)
returns void language plpgsql security definer set search_path to 'public' as $$
declare v jsonb := coalesce(p_imagenes, '[]'::jsonb); e jsonb;
begin
  perform public.fn_op_exigir_rol();
  if jsonb_typeof(v) <> 'array' then raise exception 'Formato de imágenes no válido.'; end if;
  if jsonb_array_length(v) > 3 then raise exception 'Máximo 3 imágenes de referencia por orden.'; end if;
  for e in select * from jsonb_array_elements(v) loop
    if jsonb_typeof(e) <> 'string' or (e #>> '{}') !~ '^https://' then raise exception 'Imagen no válida.'; end if;
  end loop;
  update public.ordenes_produccion set imagenes_referencia = v where id = p_orden_id;
  if not found then raise exception 'No existe esa orden de producción.'; end if;
end $$;

-- 3) Datos de apoyo por orden: imágenes, patrones (enlaces de Telegram de la ficha), y ficha del producto
--    (materiales sugeridos, tejedora habitual del plan). El producto se deduce de la orden, de la línea del pedido o del nombre.
create or replace function public.fn_op_extras(p_ordenes uuid[])
returns jsonb language plpgsql stable security definer set search_path to 'public' as $$
declare v_admin boolean; v_res jsonb := '{}'::jsonb; o record; v_prod uuid; v_ficha public.fichas_tecnicas_producto; v_plan public.producto_tejido_plan;
        v_pat jsonb; v_tej jsonb; v_mats jsonb;
begin
  v_admin := coalesce(public.fn_rol_actual()::text, '') in ('administrador', 'taller', 'contador');
  if not v_admin and not public.fn_es_tejedora() then raise exception 'No tienes acceso a las órdenes de producción.'; end if;
  for o in select * from public.ordenes_produccion where id = any(p_ordenes) loop
    v_prod := o.producto_item_id;
    if v_prod is null and o.pedido_canal_id is not null then
      select l.inventario_item_id into v_prod from public.pedidos_canal_lineas l
       where l.pedido_id = o.pedido_canal_id and lower(trim(l.descripcion)) = lower(trim(o.descripcion)) and l.inventario_item_id is not null limit 1;
    end if;
    if v_prod is null then
      select i.id into v_prod from public.inventario_items i
       where i.tipo::text = 'producto_terminado' and lower(trim(i.nombre)) = lower(trim(o.descripcion)) limit 1;
    end if;
    v_ficha := null; v_plan := null; v_pat := '[]'::jsonb; v_tej := null; v_mats := '[]'::jsonb;
    if v_prod is not null then
      select * into v_ficha from public.fichas_tecnicas_producto where inventario_item_id = v_prod;
      select * into v_plan from public.producto_tejido_plan where inventario_item_id = v_prod;
    end if;
    if v_ficha.inventario_item_id is not null then
      select coalesce(jsonb_agg(trim(x)), '[]'::jsonb) into v_pat from unnest(regexp_split_to_array(coalesce(v_ficha.patron_url, ''), E'[\\r\\n\\s]+')) x where trim(x) ~ '^https?://';
      if v_admin then v_mats := coalesce(v_ficha.materiales, '[]'::jsonb); end if;
    end if;
    if v_admin and v_plan.tejedora_user_id is not null then
      select jsonb_build_object('tipo', case when tu.empleado_id is not null then 'e' else 't' end,
                                'id', coalesce(tu.empleado_id, tu.tercero_id),
                                'nombre', coalesce(e.nombre_completo, t.nombre_completo)) into v_tej
        from public.tejedoras_usuarios tu left join public.empleados e on e.id = tu.empleado_id left join public.terceros t on t.id = tu.tercero_id
       where tu.user_id = v_plan.tejedora_user_id;
    end if;
    v_res := v_res || jsonb_build_object(o.id::text, jsonb_build_object(
      'imagenes', o.imagenes_referencia, 'patrones', v_pat, 'producto_id', v_prod,
      'materiales_ficha', v_mats, 'tejedora_plan', v_tej));
  end loop;
  return v_res;
end $$;

grant execute on function public.fn_op_asignar_tejedora(uuid, text, uuid) to authenticated;
grant execute on function public.fn_op_guardar_imagenes(uuid, jsonb) to authenticated;
grant execute on function public.fn_op_extras(uuid[]) to authenticated;
