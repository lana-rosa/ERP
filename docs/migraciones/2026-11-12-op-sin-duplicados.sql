-- Evita abrir dos órdenes de producción activas para el mismo pedido y el mismo producto (una orden por línea de pedido).
-- Se reconoce el pedido por pedido_canal_id, pedido_crm_id o número de pedido; el producto por su descripción.
create or replace function public.fn_op_abrir(p_producto_item_id uuid, p_descripcion text, p_cantidad numeric, p_pedido_canal_id uuid default null, p_pedido_crm_id uuid default null, p_numero_pedido_crm text default null, p_observaciones text default null)
 returns uuid language plpgsql security definer set search_path to 'public'
as $function$
declare v_tipo text; v_nombre text; v_id uuid; v_desc text; v_num text := nullif(trim(p_numero_pedido_crm), ''); v_dup integer;
begin
  perform public.fn_op_exigir_rol();
  if coalesce(p_cantidad, 0) <= 0 then raise exception 'La cantidad a producir debe ser mayor a cero.'; end if;
  if p_producto_item_id is not null then
    select tipo::text, nombre into v_tipo, v_nombre from public.inventario_items where id = p_producto_item_id;
    if v_tipo is distinct from 'producto_terminado' then
      raise exception 'El producto a tejer debe ser un producto terminado del inventario.';
    end if;
  end if;
  v_desc := coalesce(nullif(trim(p_descripcion), ''), v_nombre);
  if v_desc is null then raise exception 'Describe qué se va a tejer o elige un producto del inventario.'; end if;
  if p_pedido_canal_id is not null or p_pedido_crm_id is not null or v_num is not null then
    select o.numero into v_dup from public.ordenes_produccion o
     where o.estado::text <> 'anulada'
       and lower(trim(coalesce(o.descripcion, ''))) = lower(trim(v_desc))
       and ((p_pedido_canal_id is not null and o.pedido_canal_id = p_pedido_canal_id)
         or (p_pedido_crm_id is not null and o.pedido_crm_id = p_pedido_crm_id)
         or (v_num is not null and o.numero_pedido_crm = v_num))
     limit 1;
    if v_dup is not null then
      raise exception 'Este pedido ya tiene la orden de producción % para este producto: no se abre otra. Si la anterior quedó mal, anúlala primero.', public.fn_op_etiqueta(v_dup);
    end if;
  end if;
  insert into public.ordenes_produccion (producto_item_id, descripcion, cantidad_planeada, pedido_canal_id, pedido_crm_id, numero_pedido_crm, observaciones)
  values (p_producto_item_id, v_desc, p_cantidad, p_pedido_canal_id, p_pedido_crm_id, v_num, nullif(trim(p_observaciones), ''))
  returning id into v_id;
  return v_id;
end $function$;
