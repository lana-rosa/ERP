-- Fase 4 SENA: tablero del ciclo de desembolsos (solicitado → aprobado → desembolsado → pagado → legalizado) con alertas.
-- La fecha límite de legalización crea un evento "🏦 Entrega Fondo Emprender — Legalización del desembolso No. N" en el calendario
-- (recordatorio 2 días antes), así reutiliza la alerta de LAROVA y el correo diario de las entregas del Fondo.
alter table public.fondo_desembolsos add column if not exists fecha_limite_legalizacion date;

create or replace function public.fn_fondo_desembolso_limite(p_id uuid, p_fecha date) returns void language plpgsql security definer set search_path = public as $$
declare v_n int; v_titulo text;
begin
  perform public.fn_fondo_permiso();
  update public.fondo_desembolsos set fecha_limite_legalizacion = p_fecha where id = p_id returning numero into v_n;
  if v_n is null then raise exception 'No se encontró el desembolso.'; end if;
  v_titulo := E'\U0001F3E6 Entrega Fondo Emprender — Legalización del desembolso No. ' || v_n::text;
  delete from public.eventos_calendario where titulo in (v_titulo, E'✅ ' || v_titulo);
  if p_fecha is not null then
    insert into public.eventos_calendario (titulo, descripcion, tipo, fecha_inicio, fecha_fin, recordatorio_minutos_antes, creado_por)
    values (v_titulo, 'Fecha límite para legalizar el desembolso No. ' || v_n::text || ' (Formato «Legalización desembolso» + factura, comprobante de transferencia, extracto y evidencia de entrega). Sin legalizar no hay nuevo desembolso.',
            'otro', ((p_fecha::text || ' 08:00-05')::timestamptz), ((p_fecha::text || ' 09:00-05')::timestamptz), 2880, auth.uid());
  end if;
end $$;

-- Al marcar «legalizado» se marca también como entregada la alerta del calendario.
create or replace function public.fn_fondo_desembolso_actualizar(p_id uuid, p_fecha date, p_monto numeric, p_descripcion text, p_estado text, p_fecha_legalizacion date) returns void language plpgsql security definer set search_path = public as $$
declare v_n int; v_titulo text;
begin
  perform public.fn_fondo_permiso();
  if p_monto is null or p_monto < 0 then raise exception 'El monto del desembolso no es válido.'; end if;
  update public.fondo_desembolsos set fecha_recibido = p_fecha, monto = p_monto, descripcion = nullif(trim(p_descripcion), ''), estado = p_estado, fecha_legalizacion = p_fecha_legalizacion where id = p_id returning numero into v_n;
  if v_n is null then raise exception 'No se encontró el desembolso.'; end if;
  if p_estado = 'legalizado' then
    v_titulo := E'\U0001F3E6 Entrega Fondo Emprender — Legalización del desembolso No. ' || v_n::text;
    update public.eventos_calendario set titulo = E'✅ ' || titulo, recordatorio_minutos_antes = null, updated_at = now() where titulo = v_titulo;
  end if;
end $$;

create or replace function public.fn_fondo_tablero() returns jsonb language plpgsql security definer set search_path = public stable as $$
declare v_hoy date := (now() at time zone 'America/Bogota')::date; d record; v_res jsonb := '[]'::jsonb; v_alertas text[]; v_sig text;
  n_lin int; n_compra int; n_listas int; v_asig numeric; v_leg numeric; v_nomina boolean; v_dias int; v_previo int;
begin
  perform public.fn_fondo_permiso();
  for d in select * from public.fondo_desembolsos order by numero desc loop
    v_alertas := '{}'; v_sig := null;
    select count(*), count(l.compra_id), coalesce(sum(l.monto_desembolsado), 0), coalesce(sum(l.monto_legalizado), 0),
           coalesce(bool_or(coalesce(l.rubro, '') ilike 'nomina' or coalesce(l.rubro, '') ilike 'jornales'), false),
           count(*) filter (where r.id is not null and (coalesce(r.documentos ? 'comprobante_pago', false) and coalesce(r.documentos ? 'extracto_bancario', false) and coalesce(r.documentos ? 'evidencia_entrega', false)
                 and (coalesce(g.foto_comprobante, '') <> '' or coalesce(g.es_documento_soporte, false))))
      into n_lin, n_compra, v_asig, v_leg, v_nomina, n_listas
    from public.fondo_desembolso_lineas l left join public.compras_requisitos_sena r on r.id = l.compra_id left join public.gastos_departamentales g on g.id = r.gasto_id where l.desembolso_id = d.id;
    v_dias := case when d.fecha_limite_legalizacion is null then null else d.fecha_limite_legalizacion - v_hoy end;
    select numero into v_previo from public.fondo_desembolsos where numero < d.numero and estado <> 'legalizado' order by numero limit 1;

    if d.estado = 'con_observaciones' then v_alertas := array_append(v_alertas, ('La interventora dejó observaciones: respóndelas en la plataforma del SENA y vuelve a enviar.')::text); end if;
    if d.estado = 'solicitado' and v_previo is not null then v_alertas := array_append(v_alertas, (('Antes de pedir este desembolso hay que legalizar el No. ' || v_previo::text || ' (sin legalizar no hay nuevo desembolso).'))::text); end if;
    if d.estado in ('solicitado', 'aprobado') and d.fecha_solicitud is null then v_alertas := array_append(v_alertas, ('Falta la fecha de solicitud.')::text); end if;
    if d.estado in ('desembolsado', 'pagado', 'con_observaciones') and d.fecha_limite_legalizacion is null then v_alertas := array_append(v_alertas, ('Define la fecha límite de legalización (pregúntasela a la interventora): así el ERP te avisa 2 días antes.')::text); end if;
    if d.estado <> 'legalizado' and v_dias is not null and v_dias <= 2 then
      v_alertas := array_append(v_alertas, (case when v_dias < 0 then 'La legalización venció hace ' || (-v_dias)::text || ' día(s).' when v_dias = 0 then 'La legalización vence HOY.' else 'La legalización vence en ' || v_dias::text || ' día(s).' end)::text);
    end if;
    if d.estado in ('desembolsado', 'pagado') and n_lin = 0 then v_alertas := array_append(v_alertas, ('Aún no hay compras ni filas asociadas a este desembolso.')::text); end if;
    if d.estado in ('desembolsado', 'pagado') and n_lin > 0 and round(v_asig) <> round(d.monto) then v_alertas := array_append(v_alertas, (('Lo asignado a compras (' || round(v_asig)::text || ') no es igual al monto recibido (' || round(d.monto)::text || ').'))::text); end if;
    if d.estado in ('desembolsado', 'pagado') and n_compra > 0 and n_listas < n_compra then v_alertas := array_append(v_alertas, (('Faltan soportes (factura, comprobante, extracto o evidencia de entrega) en ' || (n_compra - n_listas)::text || ' de ' || n_compra::text || ' compra(s).'))::text); end if;
    if d.estado in ('desembolsado', 'pagado') and n_lin > n_compra then v_alertas := array_append(v_alertas, (((n_lin - n_compra)::text || ' fila(s) sin compra: agrégales la compra que pagaste.'))::text); end if;
    if v_nomina and d.estado <> 'legalizado' then v_alertas := array_append(v_alertas, ('Nómina: cada trabajador con su comprobante de pago y la PILA del periodo.')::text); end if;
    v_sig := case d.estado
      when 'solicitado' then 'Sube la solicitud a la plataforma del SENA (pestañas AVANCE y PAGOS) y espera la aprobación del interventor.'
      when 'aprobado' then 'Espera el giro del Fondo a la cuenta exclusiva y registra cuándo llegó.'
      when 'desembolsado' then 'Paga a los proveedores aprobados desde la cuenta exclusiva y guarda los comprobantes.'
      when 'pagado' then 'Arma el Formato de legalización con las compras y súbelo con los soportes.'
      when 'con_observaciones' then 'Responde las observaciones y vuelve a enviar.'
      else 'Listo: legalización aprobada, ya puedes pedir el siguiente desembolso.' end;
    if d.estado in ('desembolsado', 'pagado') and n_compra > 0 and n_listas = n_compra and n_lin = n_compra and round(v_asig) = round(d.monto) then
      v_sig := 'Todo está listo: baja el Excel de legalización, súbelo con los soportes y márcalo como Legalizado cuando el SENA lo apruebe.';
    end if;
    v_res := v_res || jsonb_build_object('id', d.id, 'numero', d.numero, 'estado', d.estado, 'monto', d.monto, 'descripcion', d.descripcion, 'fecha_solicitud', d.fecha_solicitud, 'fecha_recibido', d.fecha_recibido,
      'fecha_legalizacion', d.fecha_legalizacion, 'fecha_limite_legalizacion', d.fecha_limite_legalizacion, 'dias_limite', v_dias, 'lineas', n_lin, 'compras', n_compra, 'listas', n_listas,
      'asignado', v_asig, 'legalizado', v_leg, 'saldo_por_legalizar', d.monto - v_leg, 'alertas', to_jsonb(v_alertas), 'siguiente_paso', v_sig);
  end loop;
  return v_res;
end $$;

revoke all on function public.fn_fondo_desembolso_limite(uuid, date), public.fn_fondo_tablero() from public, anon;
grant execute on function public.fn_fondo_desembolso_limite(uuid, date), public.fn_fondo_tablero() to authenticated;
