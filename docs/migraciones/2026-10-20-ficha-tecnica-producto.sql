-- Ficha técnica por producto del Taller (20-oct-2026, pedido de Sara).
--  * Una ficha por producto terminado (se hace una sola vez; al producir más unidades se trae lo guardado).
--  * Código de barras interno EAN-13 (prefijo 20, de uso interno en tienda: no choca con códigos de proveedores).
--  * «Registrar producción ya tejida»: orden de producción con fecha pasada, tejedora y cantidad, que sube el stock.
-- Nota: el MCP de Supabase se queda esperando con SQL que contenga las palabras de borrar; este archivo no las usa.

create table if not exists public.fichas_tecnicas_producto (
  inventario_item_id uuid primary key references public.inventario_items(id),
  materiales jsonb not null default '[]'::jsonb,      -- [{inventario_item_id?, nombre, cantidad, unidad, detalle}]
  patron_texto text,
  patron_url text,
  tiempo_horas numeric,
  ojos_tipo text,
  ojos_cantidad int,
  relleno_gramos numeric,
  accesorios jsonb not null default '[]'::jsonb,      -- ["Argolla de llavero", "Marquilla", "Gafas", ...]
  profundidad_cm numeric,
  notas text,
  version int not null default 1,
  creada_por uuid,
  creada_at timestamptz not null default now(),
  actualizada_por uuid,
  actualizada_at timestamptz not null default now()
);
alter table public.fichas_tecnicas_producto enable row level security;
revoke all on public.fichas_tecnicas_producto from anon, authenticated;

create sequence if not exists public.seq_sku_interno start 1;

create or replace function public.fn_ficha_exigir_rol() returns void language plpgsql security definer set search_path to 'public' as $$
begin
  if auth.uid() is null or coalesce(public.fn_rol_actual()::text, '') not in ('administrador', 'taller') then
    raise exception 'Las fichas técnicas las manejan el Taller y la administradora.';
  end if;
end $$;

-- EAN-13 interno: 20 + 10 dígitos de consecutivo + dígito de control
create or replace function public.fn_siguiente_sku_interno() returns text language plpgsql security definer set search_path to 'public' as $$
declare v_base text; v_suma int := 0; v_i int; v_cod text; v_n int := 0;
begin
  perform public.fn_ficha_exigir_rol();
  loop
    v_base := '20' || lpad(nextval('public.seq_sku_interno')::text, 10, '0');
    v_suma := 0;
    for v_i in 1..12 loop
      v_suma := v_suma + substr(v_base, v_i, 1)::int * case when v_i % 2 = 1 then 1 else 3 end;
    end loop;
    v_cod := v_base || ((10 - v_suma % 10) % 10)::text;
    exit when not exists (select 1 from public.inventario_items where sku = v_cod);
    v_n := v_n + 1; if v_n > 50 then raise exception 'No se pudo generar un código de barras libre.'; end if;
  end loop;
  return v_cod;
end $$;

create or replace function public.fn_ficha_obtener(p_item_id uuid) returns jsonb language plpgsql stable security definer set search_path to 'public' as $$
declare v_item record; v_f record;
begin
  if auth.uid() is null or coalesce(public.fn_rol_actual()::text, '') not in ('administrador', 'taller', 'contador') then
    raise exception 'No tienes acceso a las fichas técnicas.';
  end if;
  select * into v_item from public.inventario_items where id = p_item_id;
  if v_item.id is null then raise exception 'El producto no existe.'; end if;
  select * into v_f from public.fichas_tecnicas_producto where inventario_item_id = p_item_id;
  return jsonb_build_object(
    'producto', jsonb_build_object('id', v_item.id, 'nombre', v_item.nombre, 'sku', v_item.sku, 'peso_gramos', v_item.peso_gramos,
      'alto_cm', v_item.alto_cm, 'ancho_cm', v_item.ancho_cm, 'precio_venta', v_item.precio_venta, 'stock_actual', v_item.stock_actual,
      'costo_ojos', v_item.costo_ojos, 'costo_empaque', v_item.costo_empaque, 'costo_otros_accesorios', v_item.costo_otros_accesorios,
      'tiempo_elaboracion', v_item.tiempo_elaboracion, 'tipo', v_item.tipo::text),
    'ficha', case when v_f.inventario_item_id is null then null else to_jsonb(v_f) end);
end $$;

-- Guarda (crea o actualiza) la ficha y, si se envían, los datos del producto que viven en el inventario.
create or replace function public.fn_ficha_guardar(p_item_id uuid, p_ficha jsonb, p_producto jsonb default '{}'::jsonb) returns jsonb
language plpgsql security definer set search_path to 'public' as $$
declare v_item record; v_sku text; v_existe boolean;
begin
  perform public.fn_ficha_exigir_rol();
  select * into v_item from public.inventario_items where id = p_item_id for update;
  if v_item.id is null then raise exception 'El producto no existe.'; end if;
  if v_item.tipo::text <> 'producto_terminado' then raise exception 'La ficha técnica es para productos tejidos del Taller.'; end if;
  if jsonb_typeof(coalesce(p_ficha->'materiales', '[]'::jsonb)) <> 'array' or jsonb_array_length(coalesce(p_ficha->'materiales', '[]'::jsonb)) > 60 then
    raise exception 'La lista de materiales no es válida (máximo 60 filas).';
  end if;
  if jsonb_typeof(coalesce(p_ficha->'accesorios', '[]'::jsonb)) <> 'array' or jsonb_array_length(coalesce(p_ficha->'accesorios', '[]'::jsonb)) > 30 then
    raise exception 'La lista de accesorios no es válida (máximo 30).';
  end if;
  v_existe := exists (select 1 from public.fichas_tecnicas_producto where inventario_item_id = p_item_id);
  insert into public.fichas_tecnicas_producto (inventario_item_id, materiales, patron_texto, patron_url, tiempo_horas, ojos_tipo, ojos_cantidad,
      relleno_gramos, accesorios, profundidad_cm, notas, creada_por, actualizada_por)
  values (p_item_id, coalesce(p_ficha->'materiales', '[]'::jsonb), nullif(trim(p_ficha->>'patron_texto'), ''), nullif(trim(p_ficha->>'patron_url'), ''),
      nullif(p_ficha->>'tiempo_horas', '')::numeric, nullif(trim(p_ficha->>'ojos_tipo'), ''), nullif(p_ficha->>'ojos_cantidad', '')::int,
      nullif(p_ficha->>'relleno_gramos', '')::numeric, coalesce(p_ficha->'accesorios', '[]'::jsonb), nullif(p_ficha->>'profundidad_cm', '')::numeric,
      nullif(trim(p_ficha->>'notas'), ''), auth.uid(), auth.uid())
  on conflict (inventario_item_id) do update set
      materiales = excluded.materiales, patron_texto = excluded.patron_texto, patron_url = excluded.patron_url, tiempo_horas = excluded.tiempo_horas,
      ojos_tipo = excluded.ojos_tipo, ojos_cantidad = excluded.ojos_cantidad, relleno_gramos = excluded.relleno_gramos, accesorios = excluded.accesorios,
      profundidad_cm = excluded.profundidad_cm, notas = excluded.notas, actualizada_por = auth.uid(), actualizada_at = now(),
      version = public.fichas_tecnicas_producto.version + 1;

  -- código de barras: el que se escribió, el que ya tenía, o uno interno nuevo
  v_sku := coalesce(nullif(trim(p_producto->>'sku'), ''), v_item.sku);
  if v_sku is null then v_sku := public.fn_siguiente_sku_interno(); end if;
  if exists (select 1 from public.inventario_items where sku = v_sku and id <> p_item_id) then
    raise exception 'El código de barras % ya lo tiene otro producto.', v_sku;
  end if;

  update public.inventario_items set
    sku = v_sku,
    peso_gramos = coalesce(nullif(p_producto->>'peso_gramos', '')::numeric, peso_gramos),
    alto_cm = coalesce(nullif(p_producto->>'alto_cm', '')::numeric, alto_cm),
    ancho_cm = coalesce(nullif(p_producto->>'ancho_cm', '')::numeric, ancho_cm),
    precio_venta = coalesce(nullif(p_producto->>'precio_venta', '')::numeric, precio_venta),
    costo_ojos = coalesce(nullif(p_producto->>'costo_ojos', '')::numeric, costo_ojos),
    costo_empaque = coalesce(nullif(p_producto->>'costo_empaque', '')::numeric, costo_empaque),
    costo_otros_accesorios = coalesce(nullif(p_producto->>'costo_otros_accesorios', '')::numeric, costo_otros_accesorios),
    tiempo_elaboracion = coalesce(nullif(trim(p_producto->>'tiempo_elaboracion'), ''), tiempo_elaboracion),
    updated_at = now()
  where id = p_item_id;
  return jsonb_build_object('inventario_item_id', p_item_id, 'sku', v_sku, 'creada', not v_existe);
end $$;

-- «Registrar producción ya tejida»: lo que se tejió antes de crear la orden (por ejemplo, llaveros vendidos en una feria).
-- Crea la orden ya terminada con la fecha indicada, deja a la tejedora en su ficha de producción y sube el stock del producto.
-- p_materiales: [{inventario_item_id, cantidad}] con el TOTAL usado en el lote. Si p_descontar_material es verdadero, se descuenta del inventario;
-- si no, solo se usa para estimar el costo del material (el inventario de insumos no se toca).
create or replace function public.fn_op_registrar_tejido_previo(
  p_producto_item_id uuid, p_fecha date, p_tejedora_id uuid, p_tejedora_tipo text, p_cantidad numeric, p_peso_gramos numeric default null,
  p_observaciones text default null, p_materiales jsonb default '[]'::jsonb, p_descontar_material boolean default false) returns jsonb
language plpgsql security definer set search_path to 'public' as $$
declare v_prod record; v_id uuid; v_num int; v_m jsonb; v_costo numeric := 0; v_nom text; v_emp uuid; v_ter uuid; v_ts timestamptz;
begin
  perform public.fn_op_exigir_rol();
  select * into v_prod from public.inventario_items where id = p_producto_item_id;
  if v_prod.id is null or v_prod.tipo::text <> 'producto_terminado' then raise exception 'Elige un producto tejido del inventario.'; end if;
  if coalesce(p_cantidad, 0) <= 0 or p_cantidad > 1000 then raise exception 'Escribe cuántas unidades se tejieron.'; end if;
  if p_fecha is null or p_fecha > current_date then raise exception 'La fecha de tejido no puede ser futura.'; end if;
  if p_fecha < current_date - 400 then raise exception 'La fecha de tejido es demasiado antigua.'; end if;
  if p_tejedora_id is null then raise exception 'Elige quién lo tejió.'; end if;
  if jsonb_typeof(coalesce(p_materiales, '[]'::jsonb)) <> 'array' or jsonb_array_length(coalesce(p_materiales, '[]'::jsonb)) > 50 then raise exception 'La lista de materiales no es válida.'; end if;
  if p_tejedora_tipo = 'externa' then
    select nombre_completo into v_nom from public.terceros where id = p_tejedora_id and es_tejedora_externa; v_ter := p_tejedora_id;
  else
    select nombre_completo into v_nom from public.empleados where id = p_tejedora_id; v_emp := p_tejedora_id;
  end if;
  if v_nom is null then raise exception 'No se encontró a la tejedora elegida.'; end if;
  v_ts := (p_fecha::timestamp + interval '12 hours') at time zone 'America/Bogota';

  insert into public.ordenes_produccion (producto_item_id, descripcion, cantidad_planeada, observaciones)
  values (p_producto_item_id, v_prod.nombre, p_cantidad,
          'Producción registrada después de tejerla (' || to_char(p_fecha, 'YYYY-MM-DD') || ')' || coalesce('. ' || nullif(trim(p_observaciones), ''), ''))
  returning id, numero into v_id, v_num;

  if p_descontar_material and jsonb_array_length(coalesce(p_materiales, '[]'::jsonb)) > 0 then
    for v_m in select * from jsonb_array_elements(p_materiales) loop
      if nullif(v_m->>'inventario_item_id', '') is not null and coalesce((v_m->>'cantidad')::numeric, 0) > 0 then
        perform public.fn_op_entregar_material(v_id, (v_m->>'inventario_item_id')::uuid, (v_m->>'cantidad')::numeric, 'Producción ya tejida');
      end if;
    end loop;
    if exists (select 1 from public.ordenes_produccion_material where orden_id = v_id and tipo = 'entrega') then
      perform public.fn_op_terminar(v_id, p_cantidad, '[]'::jsonb);
      select costo_material into v_costo from public.ordenes_produccion where id = v_id;
    else
      p_descontar_material := false;
    end if;
  end if;
  if not p_descontar_material then
    select coalesce(sum((m->>'cantidad')::numeric * coalesce(i.costo_promedio_ponderado, 0)), 0) into v_costo
    from jsonb_array_elements(coalesce(p_materiales, '[]'::jsonb)) m
    join public.inventario_items i on i.id = nullif(m->>'inventario_item_id', '')::uuid
    where coalesce((m->>'cantidad')::numeric, 0) > 0;
    perform public.fn_mover_stock(p_producto_item_id, p_cantidad, 'entrada_produccion',
              'Producción ya tejida ' || public.fn_op_etiqueta(v_num) || ' (' || to_char(p_fecha, 'YYYY-MM-DD') || ')', null, v_id);
    update public.ordenes_produccion set estado = 'terminada', cantidad_terminada = p_cantidad, costo_material = v_costo, terminada_por = auth.uid() where id = v_id;
  end if;

  update public.ordenes_produccion set fecha_apertura = v_ts, fecha_terminacion = v_ts, abierta_por = coalesce(abierta_por, auth.uid()) where id = v_id;

  insert into public.produccion_fichas (orden_id, tejedora_id, tejedora_tercero_id, tejedora_nombre, peso_gramos, iniciada_at, terminada_at)
  values (v_id, v_emp, v_ter, v_nom, nullif(p_peso_gramos, 0), v_ts, v_ts)
  on conflict (orden_id) do update set tejedora_id = excluded.tejedora_id, tejedora_tercero_id = excluded.tejedora_tercero_id,
    tejedora_nombre = excluded.tejedora_nombre, peso_gramos = excluded.peso_gramos, terminada_at = excluded.terminada_at;

  -- el peso real del lote queda en el producto si todavía no tenía uno; el costo aproximado también si estaba vacío
  update public.inventario_items set
    peso_gramos = coalesce(peso_gramos, nullif(p_peso_gramos, 0)),
    costo_promedio_ponderado = case when coalesce(costo_promedio_ponderado, 0) = 0 and v_costo > 0 then round(v_costo / p_cantidad, 2) else costo_promedio_ponderado end
  where id = p_producto_item_id;

  return jsonb_build_object('orden', public.fn_op_etiqueta(v_num), 'orden_id', v_id, 'costo_material', v_costo,
    'costo_unitario', round(v_costo / p_cantidad, 2), 'stock', (select stock_actual from public.inventario_items where id = p_producto_item_id));
end $$;

do $mig$ begin
  revoke all on function public.fn_ficha_exigir_rol() from public, anon;
  revoke all on function public.fn_siguiente_sku_interno() from public, anon;
  revoke all on function public.fn_ficha_obtener(uuid) from public, anon;
  revoke all on function public.fn_ficha_guardar(uuid, jsonb, jsonb) from public, anon;
  revoke all on function public.fn_op_registrar_tejido_previo(uuid, date, uuid, text, numeric, numeric, text, jsonb, boolean) from public, anon;
  grant execute on function public.fn_siguiente_sku_interno() to authenticated;
  grant execute on function public.fn_ficha_obtener(uuid) to authenticated;
  grant execute on function public.fn_ficha_guardar(uuid, jsonb, jsonb) to authenticated;
  grant execute on function public.fn_op_registrar_tejido_previo(uuid, date, uuid, text, numeric, numeric, text, jsonb, boolean) to authenticated;
end $mig$;
