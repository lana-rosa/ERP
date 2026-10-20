-- Asigna código de barras interno (EAN-13, prefijo 20) a los productos tejidos activos que no tienen uno (20-oct-2026).
-- Lo usa «Imprimir etiquetas → Llaveros». Solo administrador y taller; no toca existencias ni crea movimientos de inventario.
-- Depende de fn_siguiente_sku_interno y fn_ficha_exigir_rol (2026-10-20-ficha-tecnica-producto.sql).
create or replace function public.fn_asignar_sku_interno_lote(p_items uuid[]) returns jsonb
language plpgsql security definer set search_path to 'public' as $$
declare v_id uuid; v_sku text; v_res jsonb := '{}'::jsonb;
begin
  perform public.fn_ficha_exigir_rol();
  if p_items is null or array_length(p_items, 1) is null then return v_res; end if;
  if array_length(p_items, 1) > 200 then raise exception 'Máximo 200 productos por vez.'; end if;
  for v_id in select id from public.inventario_items
              where id = any(p_items) and activo and tipo::text = 'producto_terminado' and nullif(trim(coalesce(sku, '')), '') is null
              order by nombre for update loop
    v_sku := public.fn_siguiente_sku_interno();
    update public.inventario_items set sku = v_sku, updated_at = now() where id = v_id;
    v_res := v_res || jsonb_build_object(v_id::text, v_sku);
  end loop;
  return v_res;
end $$;
revoke all on function public.fn_asignar_sku_interno_lote(uuid[]) from public, anon;
grant execute on function public.fn_asignar_sku_interno_lote(uuid[]) to authenticated;
