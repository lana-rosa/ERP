-- Gestión Colaboradores · Onboarding (aditiva). Tareas de bienvenida por cuenta (user_id), con plantillas.
create table if not exists public.gestion_colab_onboarding_plantillas (id uuid primary key default gen_random_uuid(), nombre text not null, activo boolean not null default true, creada_en timestamptz not null default now());
create table if not exists public.gestion_colab_onboarding_plantilla_tareas (id uuid primary key default gen_random_uuid(), plantilla_id uuid not null references public.gestion_colab_onboarding_plantillas(id), titulo text not null, descripcion text, responsable text not null check (responsable in ('administradora','colaboradora')), dias_limite int not null default 7, orden int not null default 0);
create table if not exists public.gestion_colab_onboarding_tareas (id uuid primary key default gen_random_uuid(), user_id uuid not null, plantilla_tarea_id uuid, titulo text not null, descripcion text, responsable text not null check (responsable in ('administradora','colaboradora')), vence_en date, estado text not null default 'pendiente' check (estado in ('pendiente','hecha')), hecha_en timestamptz, hecha_por uuid, creada_en timestamptz not null default now(), unique (user_id, plantilla_tarea_id));
alter table public.gestion_colab_onboarding_plantillas enable row level security;
alter table public.gestion_colab_onboarding_plantilla_tareas enable row level security;
alter table public.gestion_colab_onboarding_tareas enable row level security;
create policy gc_obp_leer on public.gestion_colab_onboarding_plantillas for select to authenticated using (fn_rol_actual() = 'administrador');
create policy gc_obpt_leer on public.gestion_colab_onboarding_plantilla_tareas for select to authenticated using (fn_rol_actual() = 'administrador');
create policy gc_obt_leer on public.gestion_colab_onboarding_tareas for select to authenticated using (user_id = auth.uid() or fn_rol_actual() = 'administrador');
-- Nadie escribe directo: solo las funciones.
create or replace function public.gestion_colab_onboarding_asignar(p_user uuid, p_plantilla uuid default null) returns int language plpgsql security definer set search_path = public as $$
declare v_pl uuid := p_plantilla; v_n int;
begin
  if fn_rol_actual() <> 'administrador' then raise exception 'No autorizado' using errcode='P0001'; end if;
  if v_pl is null then select id into v_pl from gestion_colab_onboarding_plantillas where activo order by creada_en limit 1; end if;
  insert into gestion_colab_onboarding_tareas(user_id, plantilla_tarea_id, titulo, descripcion, responsable, vence_en)
  select p_user, t.id, t.titulo, t.descripcion, t.responsable, current_date + t.dias_limite from gestion_colab_onboarding_plantilla_tareas t where t.plantilla_id = v_pl order by t.orden
  on conflict (user_id, plantilla_tarea_id) do nothing;
  get diagnostics v_n = row_count;
  insert into gestion_colab_auditoria(user_id, accion, detalle) values (auth.uid(), 'onboarding_asignar', jsonb_build_object('para', p_user, 'plantilla', v_pl, 'tareas', v_n));
  return v_n;
end $$;
create or replace function public.gestion_colab_onboarding_marcar(p_tarea uuid, p_hecha boolean default true) returns void language plpgsql security definer set search_path = public as $$
declare v gestion_colab_onboarding_tareas%rowtype;
begin
  select * into v from gestion_colab_onboarding_tareas where id = p_tarea;
  if not found then raise exception 'No existe la tarea' using errcode='P0001'; end if;
  if not (fn_rol_actual() = 'administrador' or (v.user_id = auth.uid() and v.responsable = 'colaboradora')) then raise exception 'No autorizado' using errcode='P0001'; end if;
  update gestion_colab_onboarding_tareas set estado = case when p_hecha then 'hecha' else 'pendiente' end, hecha_en = case when p_hecha then now() end, hecha_por = case when p_hecha then auth.uid() end where id = p_tarea;
  insert into gestion_colab_auditoria(user_id, accion, detalle) values (auth.uid(), 'onboarding_marcar', jsonb_build_object('tarea', p_tarea, 'hecha', p_hecha));
end $$;
do $$ declare v uuid; begin
  if not exists (select 1 from gestion_colab_onboarding_plantillas) then
    insert into gestion_colab_onboarding_plantillas(nombre) values ('Bienvenida a Lana Rosa') returning id into v;
    insert into gestion_colab_onboarding_plantilla_tareas(plantilla_id, titulo, descripcion, responsable, dias_limite, orden) values
     (v,'Entregar documento de identidad y datos de contacto','Copia de la cédula, dirección, teléfono y contacto de emergencia.','colaboradora',3,1),
     (v,'Firmar el contrato','Revisar y firmar el contrato de trabajo.','colaboradora',3,2),
     (v,'Afiliar a salud, pensión, ARL y caja','Hacer las afiliaciones y guardar los soportes en la carpeta.','administradora',5,3),
     (v,'Crear su cuenta de acceso y explicarle el ERP','Cuenta con el rol que corresponde y recorrido corto.','administradora',2,4),
     (v,'Leer el Reglamento Interno de Trabajo','Leerlo y quedar enterada (la aceptación formal se agrega con la revisión de la abogada).','colaboradora',7,5),
     (v,'Inducción en seguridad y salud en el trabajo','Charla de inducción SG-SST.','administradora',7,6),
     (v,'Conocer el horario, el muro y cómo pedir permisos','Recorrer Mi perfil, Mi horario y el muro.','colaboradora',7,7),
     (v,'Entregar la dotación','Entrega de dotación y firma de recibido.','administradora',15,8);
  end if; end $$;
revoke all on function public.gestion_colab_onboarding_asignar(uuid,uuid), public.gestion_colab_onboarding_marcar(uuid,boolean) from public, anon;
grant execute on function public.gestion_colab_onboarding_asignar(uuid,uuid), public.gestion_colab_onboarding_marcar(uuid,boolean) to authenticated;
