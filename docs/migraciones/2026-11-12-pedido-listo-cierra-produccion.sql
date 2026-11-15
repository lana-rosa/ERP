-- Cuando un pedido por redes pasa a "listo para despacho" o "entregado":
--  1) su solicitud en "Pedidos por elaborar" queda terminada (sale de la lista del Taller);
--  2) si es entregado, las órdenes de producción YA terminadas (sin producto de inventario) pasan a "entregada".
-- Las órdenes que siguen "en proceso" no se tocan solas (terminarlas exige registrar material y sobrantes): la pantalla avisa.
create or replace function public.fn_pedido_canal_cierra_produccion() returns trigger
language plpgsql security definer set search_path to 'public' as $$
begin
  update public.solicitudes_elaboracion_taller
     set estado = 'terminado', fecha_terminado = coalesce(fecha_terminado, now()), updated_at = now()
   where pedido_canal_id = new.id and estado <> 'terminado';
  if new.estado::text = 'entregado' then
    update public.ordenes_produccion
       set estado = 'entregada', fecha_entrega = clock_timestamp()
     where pedido_canal_id = new.id and estado::text = 'terminada' and producto_item_id is null;
  end if;
  return null;
end $$;
create trigger trg_pedido_canal_cierra_produccion after update of estado on public.pedidos_canal_venta
  for each row when (new.estado::text in ('listo_despacho','entregado') and old.estado is distinct from new.estado)
  execute function public.fn_pedido_canal_cierra_produccion();
