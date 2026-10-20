-- ERP: anticipo elegible en los pedidos por WhatsApp/redes (20-oct-2026, Sara: el anticipo mínimo es el 50 %). Aplicada en Supabase.
-- fn_crear_pedido_canal sigue creando el pedido con el 50 % del producto; el ERP llama a esta función después para subirlo.
-- Reglas: solo personal del ERP con rol; el anticipo no puede estar ya pagado; no aplica a la tienda virtual (se cobra completo);
-- mínimo el 50 % del valor de los productos (sin envío) y máximo el total del pedido (con envío). Recalcula el saldo.
create or replace function public.fn_ajustar_anticipo_pedido_canal(p_pedido_id uuid, p_monto numeric)
returns void language plpgsql security definer set search_path to 'public' as $$
declare
  v record;
  v_min numeric(14,2);
  v_monto numeric(14,2) := round(coalesce(p_monto, 0), 2);
begin
  if auth.uid() is null or public.fn_rol_actual() is null then raise exception 'No autorizado' using errcode = '42501'; end if;
  select * into v from public.pedidos_canal_venta where id = p_pedido_id for update;
  if v.id is null then raise exception 'Pedido no encontrado'; end if;
  if v.anticipo_pagado then raise exception 'El anticipo de este pedido ya fue registrado: no se puede cambiar'; end if;
  if v.canal::text = 'tienda_virtual' then raise exception 'Los pedidos de la tienda virtual se cobran completos'; end if;
  v_min := round(v.valor_producto * 0.5, 2);
  if v_monto < v_min then raise exception 'El anticipo mínimo es el 50 %% del valor de los productos (%)', v_min; end if;
  if v_monto > v.total_pedido then raise exception 'El anticipo no puede superar el total del pedido (%)', v.total_pedido; end if;
  update public.pedidos_canal_venta
     set monto_anticipo_requerido = v_monto, monto_saldo_requerido = v.total_pedido - v_monto, updated_at = now()
   where id = p_pedido_id;
end $$;
revoke all on function public.fn_ajustar_anticipo_pedido_canal(uuid, numeric) from public, anon;
grant execute on function public.fn_ajustar_anticipo_pedido_canal(uuid, numeric) to authenticated;
