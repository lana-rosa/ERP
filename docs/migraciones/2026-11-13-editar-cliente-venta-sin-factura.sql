-- 2026-11-13 · Facturación DIAN: editar los datos del cliente de una venta SIN factura electrónica registrada.
-- Solo administradora; no toca montos, pagos ni caja; deja registro en bitacora_contable (accion 'editar_cliente_venta').
-- Bloquea si la venta ya tiene factura DIAN (documentos_electronicos tipo factura, estado emitida).
-- Si hay que crear un cliente nuevo exige confirmar la autorización de tratamiento de datos (check terceros_requiere_aceptacion_datos).
create or replace function public.fn_editar_cliente_venta(
  p_origen text, p_origen_id uuid, p_nombre text, p_tipo_documento text, p_numero_documento text,
  p_dv text, p_correo text, p_telefono text, p_direccion text, p_ciudad text,
  p_acepta_datos boolean default false, p_medio_autorizacion text default null)
returns jsonb
language plpgsql security definer set search_path to 'public'
as $f$
declare
  v_actual uuid; v_destino uuid; v_usos int;
  v_tipo text := upper(trim(coalesce(p_tipo_documento, '')));
  v_doc text := regexp_replace(trim(coalesce(p_numero_documento, '')), '\s+', '', 'g');
  v_nombre text := trim(coalesce(p_nombre, ''));
  v_correo text := nullif(trim(coalesce(p_correo, '')), '');
  v_tel text := nullif(trim(coalesce(p_telefono, '')), '');
  v_dir text := nullif(trim(coalesce(p_direccion, '')), '');
  v_ciu text := nullif(trim(coalesce(p_ciudad, '')), '');
  v_dv text := case when v_tipo = 'NIT' then nullif(trim(coalesce(p_dv, '')), '') else null end;
  v_antes jsonb; v_despues jsonb;
begin
  if auth.uid() is null or coalesce(public.fn_rol_actual()::text, '') <> 'administrador' then
    raise exception 'Solo la administradora puede editar los datos del cliente de una venta.' using errcode = '42501';
  end if;
  if p_origen not in ('venta_pos', 'pedido_canal') then raise exception 'Origen no válido.'; end if;
  if length(v_nombre) < 2 then raise exception 'Falta el nombre o razón social del cliente.'; end if;
  if v_tipo not in ('CC', 'CE', 'NIT', 'PASAPORTE', 'TI') then raise exception 'Tipo de documento no válido.'; end if;
  if length(v_doc) < 5 then raise exception 'Falta el número de documento (mínimo 5 caracteres).'; end if;
  if v_correo is not null and v_correo !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then raise exception 'El correo no es válido.'; end if;
  if v_tel is not null and length(v_tel) < 7 then raise exception 'El teléfono parece incompleto.'; end if;

  if exists (select 1 from public.documentos_electronicos where origen = p_origen and origen_id = p_origen_id and tipo = 'factura' and estado = 'emitida') then
    raise exception 'Esta venta ya tiene factura DIAN; para cambiar el comprador se necesita nota crédito y nueva factura. Consulta al contador.';
  end if;
  if p_origen = 'venta_pos' then
    select tercero_id into v_actual from public.ventas_pos where id = p_origen_id for update;
  else
    select tercero_id into v_actual from public.pedidos_canal_venta where id = p_origen_id for update;
  end if;
  if not found then raise exception 'No encontré esa venta.'; end if;

  if v_actual is not null then
    select jsonb_build_object('nombre', nombre_completo, 'tipo_documento', tipo_documento::text, 'numero_documento', numero_documento,
           'dv', digito_verificacion, 'correo', email, 'telefono', telefono, 'direccion', direccion, 'ciudad', ciudad)
      into v_antes from public.terceros where id = v_actual;
  end if;

  -- ¿Ya existe un cliente con ese documento? Se usa ese (así no se duplica).
  select id into v_destino from public.terceros where numero_documento = v_doc limit 1;

  if v_destino is null and v_actual is not null then
    -- El cliente actual se edita en el mismo registro solo si es cliente y nadie más lo usa.
    select (select count(*) from public.ventas_pos where tercero_id = v_actual and not (p_origen = 'venta_pos' and id = p_origen_id))
         + (select count(*) from public.pedidos_canal_venta where tercero_id = v_actual and not (p_origen = 'pedido_canal' and id = p_origen_id))
      into v_usos;
    if v_usos = 0 and (select tipo::text from public.terceros where id = v_actual) = 'cliente' then
      v_destino := v_actual;
    end if;
  end if;

  begin
    if v_destino is null then
      if coalesce(p_acepta_datos, false) is not true then
        raise exception 'Hay que crear un cliente nuevo: confirma que el cliente autorizó el tratamiento de sus datos personales.';
      end if;
      insert into public.terceros (tipo, tipo_documento, numero_documento, nombre_completo, email, telefono, direccion, ciudad, digito_verificacion,
                                   acepta_tratamiento_datos, fecha_aceptacion_datos, medio_autorizacion)
      values ('cliente', v_tipo::text::public.tipo_documento, v_doc, v_nombre, v_correo, v_tel, v_dir, v_ciu, v_dv,
              true, now(), coalesce(nullif(trim(coalesce(p_medio_autorizacion, '')), ''), 'Confirmado por la administradora al editar los datos de una venta'))
      returning id into v_destino;
    else
      update public.terceros set tipo_documento = v_tipo::text::public.tipo_documento, numero_documento = v_doc, nombre_completo = v_nombre,
             email = v_correo, telefono = v_tel, direccion = v_dir, ciudad = v_ciu, digito_verificacion = v_dv, updated_at = now()
       where id = v_destino;
    end if;
  exception when unique_violation then
    raise exception 'Ya existe otro cliente con ese número de documento.';
  end;

  -- Enlazar la venta al cliente. No se toca ningún valor, pago ni caja.
  if p_origen = 'venta_pos' then
    update public.ventas_pos set tercero_id = v_destino where id = p_origen_id;
  else
    update public.pedidos_canal_venta set tercero_id = v_destino, direccion_envio = coalesce(v_dir, direccion_envio), updated_at = now() where id = p_origen_id;
  end if;

  v_despues := jsonb_build_object('nombre', v_nombre, 'tipo_documento', v_tipo, 'numero_documento', v_doc, 'dv', v_dv,
                                  'correo', v_correo, 'telefono', v_tel, 'direccion', v_dir, 'ciudad', v_ciu);

  perform public.fn_bitacora_registrar('editar_cliente_venta', p_origen, p_origen_id::text,
    jsonb_build_object('tercero_antes', v_actual, 'tercero_despues', v_destino, 'antes', v_antes, 'despues', v_despues));

  return jsonb_build_object('tercero_id', v_destino);
end $f$;
