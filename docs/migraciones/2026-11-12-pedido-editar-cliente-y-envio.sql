-- Editar un pedido por redes ya registrado: datos del cliente y valor del domicilio (recalcula total y saldo).
create or replace function public.fn_editar_cliente_pedido_canal(p_pedido_id uuid, p_nombre text, p_telefono text, p_identificacion text, p_direccion text, p_ciudad text, p_email text)
returns void language plpgsql security definer set search_path to 'public' as $$
declare v record;
begin
  if auth.uid() is null or coalesce(public.fn_rol_actual()::text, '') not in ('administrador', 'cajero') then
    raise exception 'No tienes permiso para editar los datos del cliente de un pedido.' using errcode = '42501';
  end if;
  select * into v from public.pedidos_canal_venta where id = p_pedido_id for update;
  if v.id is null then raise exception 'Pedido no encontrado'; end if;
  if v.tercero_id is null then raise exception 'Este pedido no tiene un cliente guardado.'; end if;
  if length(trim(coalesce(p_nombre, ''))) < 2 then raise exception 'Falta el nombre del cliente.'; end if;
  if length(trim(coalesce(p_telefono, ''))) < 7 then raise exception 'Falta el teléfono del cliente.'; end if;
  begin
    update public.terceros set nombre_completo = trim(p_nombre), telefono = trim(p_telefono),
           numero_documento = coalesce(nullif(trim(p_identificacion), ''), numero_documento),
           direccion = nullif(trim(p_direccion), ''), ciudad = nullif(trim(p_ciudad), ''), email = nullif(trim(p_email), ''),
           updated_at = now()
     where id = v.tercero_id;
  exception when unique_violation then
    raise exception 'Ya existe otro cliente con ese número de identificación.';
  end;
  update public.pedidos_canal_venta set direccion_envio = coalesce(nullif(trim(p_direccion), ''), direccion_envio), updated_at = now() where id = p_pedido_id;
end $$;

create or replace function public.fn_cambiar_envio_pedido_canal(p_pedido_id uuid, p_valor_envio numeric)
returns jsonb language plpgsql security definer set search_path to 'public' as $$
declare v record; v_envio numeric(14,2) := round(coalesce(p_valor_envio, -1), 2); v_total numeric(14,2); v_anticipo numeric(14,2);
begin
  if auth.uid() is null or coalesce(public.fn_rol_actual()::text, '') not in ('administrador', 'cajero') then
    raise exception 'No tienes permiso para cambiar el domicilio de un pedido.' using errcode = '42501';
  end if;
  if v_envio < 0 then raise exception 'El valor del domicilio no puede ser negativo.'; end if;
  select * into v from public.pedidos_canal_venta where id = p_pedido_id for update;
  if v.id is null then raise exception 'Pedido no encontrado'; end if;
  if v.canal::text = 'tienda_virtual' then raise exception 'Los pedidos de la tienda virtual ya se cobraron completos: no se cambia el domicilio.'; end if;
  if v.estado::text = 'entregado' or v.saldo_pagado then raise exception 'Este pedido ya se entregó o su saldo ya se cobró: el domicilio no se puede cambiar.'; end if;
  v_total := v.valor_producto + v_envio;
  if v.anticipo_pagado and v_total < v.monto_anticipo_requerido then
    raise exception 'El anticipo ya cobrado (%) supera el nuevo total del pedido (%).', v.monto_anticipo_requerido, v_total;
  end if;
  v_anticipo := case when v.anticipo_pagado then v.monto_anticipo_requerido else least(v.monto_anticipo_requerido, v_total) end;
  update public.pedidos_canal_venta
     set valor_envio = v_envio, total_pedido = v_total, monto_anticipo_requerido = v_anticipo,
         monto_saldo_requerido = v_total - v_anticipo,
         observaciones = trim(both E'\n' from coalesce(observaciones, '') || E'\n' || 'Domicilio cambiado de ' || v.valor_envio || ' a ' || v_envio || ' (' || to_char(now() at time zone 'America/Bogota', 'DD/MM/YYYY HH24:MI') || ')'),
         updated_at = now()
   where id = p_pedido_id;
  return jsonb_build_object('valor_envio', v_envio, 'total_pedido', v_total, 'saldo', v_total - v_anticipo);
end $$;
