-- Alerta diaria por correo de las entregas del Fondo Emprender (24-nov-2026). Mismo patrón que fn_avisos_membresia:
-- función SQL + pg_cron + net.http_post a Resend con la clave guardada en vault ('resend_api_key').
-- Avisa a administradoras y contador activos 2 días antes, 1 día antes, el mismo día y hasta 7 días después si no se marcó entregada.
create or replace function public.fn_avisar_entregas_fondo(p_hoy date default null, p_simular boolean default false, p_prueba_para text default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_hoy date := coalesce(p_hoy, (now() at time zone 'America/Bogota')::date);
  v_key text; v_cfg record; v_filas text := ''; v_n int := 0; v_asunto text; v_html text; v_unico text;
  v_dest text[]; v_mail text; v_enviados int := 0; e record; v_cuando text;
begin
  select decrypted_secret into v_key from vault.decrypted_secrets where name = 'resend_api_key';
  select * into v_cfg from public.configuracion_correo where id = 1;
  for e in
    select replace(titulo, E'\U0001F3E6 Entrega Fondo Emprender — ', '') nombre, descripcion,
           ((fecha_inicio at time zone 'America/Bogota')::date - v_hoy) dias, (fecha_inicio at time zone 'America/Bogota')::date fecha
    from public.eventos_calendario
    where titulo like E'\U0001F3E6 Entrega Fondo Emprender%'
      and ((fecha_inicio at time zone 'America/Bogota')::date - v_hoy) between -7 and 2
    order by fecha_inicio
  loop
    v_n := v_n + 1; v_unico := e.nombre;
    v_cuando := case when e.dias < 0 then 'venció hace ' || (-e.dias)::text || ' día(s)' when e.dias = 0 then 'es HOY' when e.dias = 1 then 'es mañana' else 'es en 2 días' end;
    v_filas := v_filas || '<li style="margin-bottom:10px"><strong>' || replace(replace(e.nombre, '&', '&amp;'), '<', '&lt;') || '</strong><br>' ||
      to_char(e.fecha, 'DD/MM/YYYY') || ' — <span style="color:' || case when e.dias <= 0 then '#C0392B' else '#856404' end || '">' || v_cuando || '</span>' ||
      case when coalesce(e.descripcion, '') <> '' then '<br><span style="font-size:13px;color:#6E6E73">' || replace(replace(e.descripcion, '&', '&amp;'), '<', '&lt;') || '</span>' else '' end || '</li>';
  end loop;
  if v_n = 0 then return jsonb_build_object('entregas', 0, 'enviados', 0); end if;
  v_asunto := case when p_prueba_para is not null then '[PRUEBA] ' else '' end ||
    case when v_n = 1 then E'\U0001F3E6 Fondo Emprender: ' || v_unico else E'\U0001F3E6 Fondo Emprender: ' || v_n::text || ' entregas próximas' end;
  v_html := '<div style="font-family:Arial,sans-serif;max-width:560px;margin:auto;color:#45454A;line-height:1.5"><h2 style="color:#E74E96">Entregas del Fondo Emprender</h2>' ||
    '<ul style="padding-left:18px">' || v_filas || '</ul><p style="font-size:13px;color:#6E6E73">Cuando la entregues, márcala como entregada en la portada del ERP (LAROVA) y no volverá a avisar. ' ||
    'Los PDF van sin caracteres especiales en el nombre. Lana Rosa Crochet.</p></div>';
  if p_prueba_para is not null then v_dest := array[p_prueba_para];
  else
    select coalesce(array_agg(distinct lower(u.email)), '{}') into v_dest from public.usuarios_roles ur join auth.users u on u.id = ur.user_id
      where ur.activo and ur.rol in ('administrador', 'contador') and u.email ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$';
  end if;
  if not p_simular and v_key is not null and v_cfg.activo and v_cfg.verificado_en is not null then
    foreach v_mail in array v_dest loop
      perform net.http_post(url := 'https://api.resend.com/emails',
        headers := jsonb_build_object('Authorization', 'Bearer ' || v_key, 'Content-Type', 'application/json'),
        body := jsonb_build_object('from', coalesce(v_cfg.remitente_nombre, 'Lana Rosa Crochet') || ' <' || v_cfg.remitente_email || '>', 'to', array[v_mail], 'subject', v_asunto, 'html', v_html));
      v_enviados := v_enviados + 1;
    end loop;
  end if;
  return jsonb_build_object('entregas', v_n, 'enviados', v_enviados, 'destinatarios', coalesce(array_length(v_dest, 1), 0), 'asunto', v_asunto, 'simulado', p_simular);
end $$;
revoke all on function public.fn_avisar_entregas_fondo(date, boolean, text) from public, anon, authenticated;

select cron.schedule('avisos-entregas-fondo', '0 13 * * *', 'select public.fn_avisar_entregas_fondo()');
