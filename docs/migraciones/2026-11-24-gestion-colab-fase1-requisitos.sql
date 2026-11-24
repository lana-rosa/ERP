-- Gestión Colaboradores · Ampliación Fase 1 · REQUISITOS + CARPETA + ALERTAS (aditiva: no borra ni cambia lo existente).
alter table public.documentos_empleado
  add column if not exists categoria text,
  add column if not exists fecha_vencimiento date,
  add column if not exists estado text not null default 'vigente',
  add column if not exists version int not null default 1,
  add column if not exists confidencialidad text not null default 'normal',
  add column if not exists hash_sha256 text,
  add column if not exists original_fisico_ubicacion text,
  add column if not exists conservar_hasta date;

create table if not exists public.gestion_colab_requisitos (
  id uuid primary key default gen_random_uuid(),
  nombre text not null, categoria text not null,
  periodicidad text not null check (periodicidad in ('unica','mensual','anual','segun_evento')),
  responsable text not null check (responsable in ('administradora','colaboradora','contador')),
  criticidad text not null check (criticidad in ('alta','media','baja')),
  activo boolean not null default true, orden int not null default 0, creado_en timestamptz not null default now());
create table if not exists public.gestion_colab_requisito_estado (
  id uuid primary key default gen_random_uuid(),
  requisito_id uuid not null references public.gestion_colab_requisitos(id),
  empleado_id uuid not null,
  estado text not null default 'pendiente' check (estado in ('pendiente','en_preparacion','pendiente_firma','pendiente_revision','vigente','vencido','no_aplica','archivado')),
  vence_en date, documento_id uuid, actualizado_en timestamptz not null default now(), actualizado_por uuid,
  unique (requisito_id, empleado_id));
create table if not exists public.gestion_colab_auditoria (
  id bigint generated always as identity primary key, user_id uuid, accion text not null, detalle jsonb, creada_en timestamptz not null default now());

alter table public.gestion_colab_requisitos enable row level security;
alter table public.gestion_colab_requisito_estado enable row level security;
alter table public.gestion_colab_auditoria enable row level security;
create policy gc_req_leer on public.gestion_colab_requisitos for select to authenticated using (fn_rol_actual() in ('administrador','contador'));
create policy gc_reqest_leer on public.gestion_colab_requisito_estado for select to authenticated
  using (fn_rol_actual() in ('administrador','contador') or empleado_id = fn_mi_empleado_id());
create policy gc_aud_leer on public.gestion_colab_auditoria for select to authenticated using (fn_rol_actual() = 'administrador');
-- Sin políticas de escritura (nadie escribe directo). La bitácora solo se agrega: no hay función de cambiar ni borrar.

create or replace function public.gestion_colab_requisito_set(p_requisito uuid, p_empleado uuid, p_estado text, p_vence date default null, p_documento uuid default null)
returns void language plpgsql security definer set search_path = public as $$
begin
  if fn_rol_actual() <> 'administrador' then raise exception 'No autorizado' using errcode='P0001'; end if;
  insert into gestion_colab_requisito_estado(requisito_id, empleado_id, estado, vence_en, documento_id, actualizado_por)
  values (p_requisito, p_empleado, p_estado, p_vence, p_documento, auth.uid())
  on conflict (requisito_id, empleado_id) do update set estado = excluded.estado, vence_en = excluded.vence_en,
    documento_id = coalesce(excluded.documento_id, gestion_colab_requisito_estado.documento_id), actualizado_en = now(), actualizado_por = auth.uid();
  insert into gestion_colab_auditoria(user_id, accion, detalle) values (auth.uid(), 'requisito_set', jsonb_build_object('requisito', p_requisito, 'empleado', p_empleado, 'estado', p_estado, 'vence', p_vence));
end $$;

-- Centro de cumplimiento: una fila por (requisito activo × empleado activo) con su alerta, en tono calmado.
create or replace function public.gestion_colab_cumplimiento()
returns table(empleado_id uuid, empleado text, requisito_id uuid, requisito text, categoria text, criticidad text, estado text, vence_en date, alerta text, mensaje text)
language plpgsql stable security definer set search_path = public as $$
begin
  if fn_rol_actual() not in ('administrador','contador') then raise exception 'No autorizado' using errcode='P0001'; end if;
  return query
  select e.id, e.nombre_completo::text, r.id, r.nombre, r.categoria, r.criticidad, coalesce(s.estado,'pendiente'), s.vence_en,
    case when coalesce(s.estado,'pendiente') in ('no_aplica','archivado') then 'cumplida'
         when coalesce(s.estado,'pendiente') = 'vigente' and (s.vence_en is null or s.vence_en > current_date + 30) then 'cumplida'
         when coalesce(s.estado,'pendiente') = 'vencido' or (s.vence_en is not null and s.vence_en < current_date) then case when r.criticidad = 'alta' then 'critica' else 'preventiva' end
         when s.vence_en is not null and s.vence_en <= current_date + 30 then 'preventiva'
         when r.criticidad = 'alta' then 'preventiva' else 'informativa' end,
    case when coalesce(s.estado,'pendiente') in ('no_aplica','archivado','vigente') and (s.vence_en is null or s.vence_en > current_date + 30) then 'Al día'
         when s.vence_en is not null and s.vence_en < current_date then 'Hay que renovarlo (venció el ' || to_char(s.vence_en,'DD/MM/YYYY') || ')'
         when s.vence_en is not null and s.vence_en <= current_date + 30 then 'Se acerca su vencimiento (' || to_char(s.vence_en,'DD/MM/YYYY') || ')'
         else 'Falta completarlo' end
  from empleados e cross join gestion_colab_requisitos r
  left join gestion_colab_requisito_estado s on s.requisito_id = r.id and s.empleado_id = e.id
  where e.activo and r.activo order by e.nombre_completo, r.orden;
end $$;

insert into gestion_colab_requisitos(nombre, categoria, periodicidad, responsable, criticidad, orden)
select * from (values
 ('Contrato firmado','Vinculación','unica','administradora','alta',1),
 ('Documento de identidad','Vinculación','unica','colaboradora','media',2),
 ('Afiliación a salud (EPS)','Seguridad social','unica','administradora','alta',3),
 ('Afiliación a pensión','Seguridad social','unica','administradora','alta',4),
 ('Afiliación a ARL','Seguridad social','unica','administradora','alta',5),
 ('Afiliación a caja de compensación','Seguridad social','unica','administradora','alta',6),
 ('Soporte de pago de seguridad social del mes','Seguridad social','mensual','administradora','alta',7),
 ('Nómina del mes (desprendible)','Nómina y prestaciones','mensual','administradora','media',8),
 ('Entrega de dotación','Dotación','anual','administradora','baja',9),
 ('Inducción','Formación','unica','administradora','media',10),
 ('Certificado de aptitud ocupacional','SG-SST','anual','administradora','alta',11),
 ('Aceptación del Reglamento Interno de Trabajo','Normativa interna','segun_evento','colaboradora','alta',12)
) v(a,b,c,d,e,f) where not exists (select 1 from gestion_colab_requisitos);

revoke all on function public.gestion_colab_requisito_set(uuid,uuid,text,date,uuid), public.gestion_colab_cumplimiento() from public, anon;
grant execute on function public.gestion_colab_requisito_set(uuid,uuid,text,date,uuid), public.gestion_colab_cumplimiento() to authenticated;
