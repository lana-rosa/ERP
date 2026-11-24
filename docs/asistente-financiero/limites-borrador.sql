-- BORRADOR, NO APLICADO. Límite de consultas del Asistente financiero (entrega 2).
create table if not exists public.asistente_financiero_consultas (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);
alter table public.asistente_financiero_consultas enable row level security; -- sin políticas: solo la función de abajo

create or replace function public.fn_asistente_financiero_registrar_consulta(p_max_dia int default 20, p_max_mes int default 400)
returns jsonb language plpgsql security definer set search_path to 'public' as $f$
declare v_dia int; v_mes int;
begin
  if coalesce(public.fn_rol_actual()::text, '') <> 'administrador' then
    raise exception 'Solo la administradora puede usar el asistente financiero';
  end if;
  select count(*) into v_dia from public.asistente_financiero_consultas where user_id = auth.uid() and created_at >= date_trunc('day', now());
  select count(*) into v_mes from public.asistente_financiero_consultas where created_at >= date_trunc('month', now());
  if v_dia >= p_max_dia then raise exception 'Llegaste al límite de consultas de hoy. Vuelve mañana.'; end if;
  if v_mes >= p_max_mes then raise exception 'Se alcanzó el límite mensual de consultas del asistente.'; end if;
  insert into public.asistente_financiero_consultas(user_id) values (auth.uid());
  return jsonb_build_object('consultas_hoy', v_dia + 1, 'quedan_hoy', p_max_dia - v_dia - 1);
end $f$;
revoke all on function public.fn_asistente_financiero_registrar_consulta(int, int) from public, anon;
grant execute on function public.fn_asistente_financiero_registrar_consulta(int, int) to authenticated;
