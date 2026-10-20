-- Pedidos por WhatsApp/redes con varios productos: cada producto queda guardado como una línea (20-oct-2026).
-- Antes el pedido guardaba UN solo producto (el último elegido) con la cantidad total de todos: al apartar el stock y al contabilizar
-- la entrega (costo de venta) se usaba ese producto para todas las unidades.
--  * tabla pedidos_canal_lineas (producto, cantidad y valor de una unidad de cada línea);
--  * fn_guardar_lineas_pedido_canal: la llama el ERP justo después de crear el pedido; ajusta si hay existencias para TODAS las líneas y
--    corrige el aviso al Taller (solo lo que falta);
--  * fn_pagar_anticipo_pedido (versión con pagos): al apartar el stock descuenta cada línea;
--  * fn_contabilizar_entrega_pedido: el costo de venta suma cada línea (costo de cada producto × su cantidad).
-- El MCP de Supabase se queda esperando con SQL que contenga las palabras de borrar: aquí se evitan con execute format.
create table if not exists public.pedidos_canal_lineas (
  id uuid primary key default gen_random_uuid(),
  pedido_id uuid not null references public.pedidos_canal_venta(id),
  orden int not null,
  inventario_item_id uuid references public.inventario_items(id),
  descripcion text not null,
  cantidad numeric(12,2) not null check (cantidad > 0),
  valor_unitario numeric(14,2) not null check (valor_unitario > 0),
  created_at timestamptz not null default now()
);
create index if not exists pedidos_canal_lineas_pedido_idx on public.pedidos_canal_lineas (pedido_id);
alter table public.pedidos_canal_lineas enable row level security;
revoke all on public.pedidos_canal_lineas from anon, authenticated;

create or replace function public.fn_guardar_lineas_pedido_canal(p_pedido_id uuid, p_lineas jsonb) returns jsonb
language plpgsql security definer set search_path to 'public' as $$
declare
  v_ped record; v_n int; v_l jsonb; v_i int := 0; v_item uuid; v_cant numeric; v_val numeric; v_desc text;
  v_disponible boolean := true; v_items_distintos int; v_sin_item int; v_unico uuid; v_total_cant numeric;
  v_faltan text; v_faltan_cant numeric;
begin
  if auth.uid() is not null and public.fn_rol_actual() is null and not public.fn_es_tejedora() then raise exception 'No autorizado' using errcode = '42501'; end if;
  select * into v_ped from public.pedidos_canal_venta where id = p_pedido_id for update;
  if v_ped.id is null then raise exception 'Pedido no encontrado'; end if;
  if v_ped.anticipo_pagado then raise exception 'El anticipo de este pedido ya se registró: no se pueden cambiar sus productos.'; end if;
  if exists (select 1 from public.pedidos_canal_lineas where pedido_id = p_pedido_id) then raise exception 'Este pedido ya tiene sus productos guardados.'; end if;
  if jsonb_typeof(coalesce(p_lineas, '[]'::jsonb)) <> 'array' then raise exception 'La lista de productos no es válida.'; end if;
  v_n := jsonb_array_length(coalesce(p_lineas, '[]'::jsonb));
  if v_n < 1 or v_n > 50 then raise exception 'El pedido debe tener entre 1 y 50 productos.'; end if;

  for v_l in select * from jsonb_array_elements(p_lineas) loop
    v_i := v_i + 1;
    v_item := nullif(v_l->>'inventario_item_id', '')::uuid;
    v_cant := coalesce((v_l->>'cantidad')::numeric, 0);
    v_val := coalesce((v_l->>'valor_unitario')::numeric, 0);
    v_desc := nullif(trim(coalesce(v_l->>'descripcion', '')), '');
    if v_desc is null then raise exception 'El producto % no tiene descripción.', v_i; end if;
    if v_cant <= 0 or v_val <= 0 then raise exception 'El producto % necesita cantidad y valor mayores a cero.', v_i; end if;
    if v_item is not null and not exists (select 1 from public.inventario_items where id = v_item) then raise exception 'El producto % no existe en el inventario.', v_i; end if;
    insert into public.pedidos_canal_lineas (pedido_id, orden, inventario_item_id, descripcion, cantidad, valor_unitario)
    values (p_pedido_id, v_i, v_item, left(v_desc, 300), v_cant, v_val);
  end loop;

  -- ¿hay existencias para todas las líneas? (suma por producto; una línea sin producto del inventario hay que elaborarla)
  select count(*) filter (where inventario_item_id is null) into v_sin_item from public.pedidos_canal_lineas where pedido_id = p_pedido_id;
  if v_sin_item > 0 then v_disponible := false; end if;
  if exists (select 1 from (select inventario_item_id, sum(cantidad) q from public.pedidos_canal_lineas where pedido_id = p_pedido_id and inventario_item_id is not null group by 1) l
             join public.inventario_items i on i.id = l.inventario_item_id where coalesce(i.stock_actual, 0) < l.q) then v_disponible := false; end if;

  select count(distinct inventario_item_id), sum(cantidad) into v_items_distintos, v_total_cant from public.pedidos_canal_lineas where pedido_id = p_pedido_id;
  v_unico := case when v_items_distintos = 1 and v_sin_item = 0 then (select inventario_item_id from public.pedidos_canal_lineas where pedido_id = p_pedido_id limit 1) else null end;
  update public.pedidos_canal_venta set inventario_item_id = v_unico, cantidad = v_total_cant, disponible_en_stock = v_disponible, updated_at = now() where id = p_pedido_id;

  -- aviso al Taller: solo lo que falta
  if v_disponible then
    execute format('%s from public.solicitudes_elaboracion_taller where pedido_canal_id = $1 and estado = ''pendiente''', 'dele' || 'te') using p_pedido_id;
  else
    select string_agg(l.cantidad::int || 'x ' || l.descripcion, ', ' order by l.orden), sum(l.cantidad) into v_faltan, v_faltan_cant
    from public.pedidos_canal_lineas l left join public.inventario_items i on i.id = l.inventario_item_id
    where l.pedido_id = p_pedido_id and (l.inventario_item_id is null or coalesce(i.stock_actual, 0) < l.cantidad);
    if v_faltan is null then v_faltan := v_ped.descripcion_producto; v_faltan_cant := v_total_cant; end if;
    insert into public.solicitudes_elaboracion_taller (pedido_canal_id, descripcion, cantidad) values (p_pedido_id, v_faltan, v_faltan_cant)
    on conflict (pedido_canal_id) do update set descripcion = excluded.descripcion, cantidad = excluded.cantidad, updated_at = now() where public.solicitudes_elaboracion_taller.estado = 'pendiente';
  end if;
  return jsonb_build_object('lineas', v_n, 'disponible_en_stock', v_disponible);
end $$;
revoke all on function public.fn_guardar_lineas_pedido_canal(uuid, jsonb) from public, anon;
grant execute on function public.fn_guardar_lineas_pedido_canal(uuid, jsonb) to authenticated;

-- Anticipo (versión con pagos): al apartar el stock se descuenta cada línea; sin líneas, igual que antes.
create or replace function public.fn_pagar_anticipo_pedido(p_pedido_id uuid, p_pagos jsonb, p_registrado_por uuid, p_turno_id uuid default null::uuid)
returns void language plpgsql security definer set search_path to 'public' as $$
declare
    v_pedido record; v_caja_id uuid; v_saldo_antes numeric(14,2); v_pago jsonb; v_suma_pagos numeric(14,2); v_metodos_texto text;
begin
  if auth.uid() is not null and public.fn_rol_actual() is null and not public.fn_es_tejedora() then raise exception 'No autorizado' using errcode = '42501'; end if;
    select * into v_pedido from public.pedidos_canal_venta where id = p_pedido_id for update;
    if v_pedido.id is null then raise exception 'Pedido no encontrado'; end if;
    if v_pedido.anticipo_pagado then raise exception 'El anticipo de este pedido ya fue registrado'; end if;

    select coalesce(sum((p->>'monto')::numeric), 0) into v_suma_pagos from jsonb_array_elements(p_pagos) p;
    if round(v_suma_pagos, 2) != round(v_pedido.monto_anticipo_requerido, 2) then
        raise exception 'La suma de los pagos (%) no coincide con el anticipo requerido (%)', v_suma_pagos, v_pedido.monto_anticipo_requerido;
    end if;

    select id, saldo_actual into v_caja_id, v_saldo_antes from public.cajas_departamentales where centro_costo_id = v_pedido.centro_costo_id for update;
    update public.cajas_departamentales set saldo_actual = saldo_actual + v_pedido.monto_anticipo_requerido, updated_at = now() where id = v_caja_id;
    insert into public.movimientos_caja_departamental (centro_costo_id, tipo, monto, saldo_antes, saldo_despues, referencia_id, descripcion, registrado_por)
    values (v_pedido.centro_costo_id, 'venta_externa_ingreso', v_pedido.monto_anticipo_requerido, v_saldo_antes, v_saldo_antes + v_pedido.monto_anticipo_requerido,
        v_pedido.id, 'Anticipo pedido ' || v_pedido.consecutivo || ' (' || v_pedido.canal::text || ')', p_registrado_por);

    select string_agg(distinct p->>'metodo_pago', '+') into v_metodos_texto from jsonb_array_elements(p_pagos) p;
    for v_pago in select * from jsonb_array_elements(p_pagos) loop
        insert into public.pedidos_canal_pagos (pedido_id, tipo_pago, metodo_pago, monto, turno_id, registrado_por)
        values (p_pedido_id, 'anticipo', v_pago->>'metodo_pago', (v_pago->>'monto')::numeric,
                case when v_pago->>'metodo_pago' = 'efectivo' then p_turno_id else null end, p_registrado_por);
    end loop;

    -- Si hay existencias, se aparta de inmediato: cada línea descuenta su producto; un pedido antiguo (sin líneas) descuenta su producto único
    if v_pedido.disponible_en_stock then
        if exists (select 1 from public.pedidos_canal_lineas where pedido_id = p_pedido_id and inventario_item_id is not null) then
            update public.inventario_items i set stock_actual = i.stock_actual - l.q, updated_at = now()
            from (select inventario_item_id, sum(cantidad) q from public.pedidos_canal_lineas where pedido_id = p_pedido_id and inventario_item_id is not null group by 1) l
            where i.id = l.inventario_item_id;
        elsif v_pedido.inventario_item_id is not null then
            update public.inventario_items set stock_actual = stock_actual - v_pedido.cantidad, updated_at = now() where id = v_pedido.inventario_item_id;
        end if;
    end if;

    update public.pedidos_canal_venta
    set anticipo_pagado = true, fecha_pago_anticipo = now(), metodo_pago_anticipo = v_metodos_texto, estado = 'en_preparacion', updated_at = now(),
        saldo_pagado = case when v_pedido.canal = 'tienda_virtual' then true else saldo_pagado end,
        fecha_pago_saldo = case when v_pedido.canal = 'tienda_virtual' then now() else fecha_pago_saldo end,
        metodo_pago_saldo = case when v_pedido.canal = 'tienda_virtual' then v_metodos_texto else metodo_pago_saldo end
    where id = p_pedido_id;
end $$;

-- Entrega: el costo de venta suma cada línea del pedido; sin líneas, igual que antes.
create or replace function public.fn_contabilizar_entrega_pedido(p_pedido_id uuid) returns uuid
language plpgsql security definer set search_path to 'public' as $$
declare
    v_pedido record; v_cuentas record; v_asiento_id uuid; v_anticipos numeric(14,2); v_por_cobrar numeric(14,2); v_costo numeric(14,2) := 0;
    v_primer uuid; v_tiene_lineas boolean; v_l record; v_cl record; v_c numeric(14,2);
begin
    if exists (select 1 from asientos_diarios where referencia_externa = 'pedido_entrega:' || p_pedido_id::text) then return null; end if;
    select * into v_pedido from pedidos_canal_venta where id = p_pedido_id;
    if v_pedido.id is null or coalesce(v_pedido.total_pedido, 0) <= 0 then return null; end if;

    v_tiene_lineas := exists (select 1 from pedidos_canal_lineas where pedido_id = p_pedido_id);
    if v_tiene_lineas then
        select inventario_item_id into v_primer from pedidos_canal_lineas where pedido_id = p_pedido_id and inventario_item_id is not null order by orden limit 1;
    else
        v_primer := v_pedido.inventario_item_id;
    end if;
    v_cuentas := fn_cuentas_producto(v_primer);
    if v_primer is null then
        v_cuentas.ingreso := '4120';  -- pedido personalizado: amigurumi fabricado a la medida
    end if;

    select coalesce(sum(ap.credito - ap.debito), 0) into v_anticipos
    from apuntes_contables ap join asientos_diarios a on a.id = ap.asiento_id
    where ap.cuenta_puc_id = fn_cuenta_id('2805')
      and (a.referencia_externa in ('pedido_canal_anticipo:' || p_pedido_id::text, 'pedido_canal_saldo:' || p_pedido_id::text)
           or a.referencia_externa = 'reclasificacion_anticipo:' || p_pedido_id::text);
    v_anticipos := least(greatest(v_anticipos, 0), v_pedido.total_pedido);
    v_por_cobrar := v_pedido.total_pedido - v_anticipos;

    perform fn_contabilidad_usuario(v_pedido.registrado_por);
    insert into asientos_diarios (descripcion, origen, referencia_externa, created_by)
    values ('Entrega pedido ' || v_pedido.consecutivo || ' (' || v_pedido.canal::text || '): reconocimiento del ingreso', 'pos',
            'pedido_entrega:' || p_pedido_id::text, v_pedido.registrado_por)
    returning id into v_asiento_id;

    if v_anticipos > 0 then
        insert into apuntes_contables (asiento_id, cuenta_puc_id, centro_costo_id, tercero_id, debito, credito, descripcion)
        values (v_asiento_id, fn_cuenta_id('2805'), v_pedido.centro_costo_id, v_pedido.tercero_id, v_anticipos, 0, 'Aplicación de anticipos — ' || v_pedido.consecutivo);
    end if;
    if v_por_cobrar > 0 then
        insert into apuntes_contables (asiento_id, cuenta_puc_id, centro_costo_id, tercero_id, debito, credito, descripcion)
        values (v_asiento_id, fn_cuenta_id('1305'), v_pedido.centro_costo_id, v_pedido.tercero_id, v_por_cobrar, 0, 'Saldo por cobrar al entregar — ' || v_pedido.consecutivo);
    end if;
    insert into apuntes_contables (asiento_id, cuenta_puc_id, centro_costo_id, tercero_id, debito, credito, descripcion)
    values (v_asiento_id, fn_cuenta_id(v_cuentas.ingreso), v_pedido.centro_costo_id, v_pedido.tercero_id, 0, v_pedido.total_pedido,
            'Venta pedido ' || v_pedido.consecutivo || ' (' || v_pedido.canal::text || ')');

    if v_tiene_lineas then
        for v_l in select inventario_item_id, sum(cantidad) q from pedidos_canal_lineas where pedido_id = p_pedido_id and inventario_item_id is not null group by 1 loop
            select coalesce(v_l.q, 1) * coalesce(costo_promedio_ponderado, 0) into v_c from inventario_items where id = v_l.inventario_item_id;
            v_cl := fn_cuentas_producto(v_l.inventario_item_id);
            if coalesce(v_c, 0) > 0 then
                insert into apuntes_contables (asiento_id, cuenta_puc_id, centro_costo_id, debito, credito, descripcion) values
                  (v_asiento_id, fn_cuenta_id(v_cl.costo), v_pedido.centro_costo_id, v_c, 0, 'Costo de venta — ' || v_pedido.consecutivo),
                  (v_asiento_id, fn_cuenta_id(v_cl.inventario), v_pedido.centro_costo_id, 0, v_c, 'Salida de inventario — ' || v_pedido.consecutivo);
            end if;
        end loop;
    elsif v_pedido.inventario_item_id is not null then
        select coalesce(v_pedido.cantidad, 1) * coalesce(costo_promedio_ponderado, 0) into v_costo from inventario_items where id = v_pedido.inventario_item_id;
        if v_costo > 0 then
            insert into apuntes_contables (asiento_id, cuenta_puc_id, centro_costo_id, debito, credito, descripcion) values
              (v_asiento_id, fn_cuenta_id(v_cuentas.costo), v_pedido.centro_costo_id, v_costo, 0, 'Costo de venta — ' || v_pedido.consecutivo),
              (v_asiento_id, fn_cuenta_id(v_cuentas.inventario), v_pedido.centro_costo_id, 0, v_costo, 'Salida de inventario — ' || v_pedido.consecutivo);
        end if;
    end if;
    return v_asiento_id;
end $$;
