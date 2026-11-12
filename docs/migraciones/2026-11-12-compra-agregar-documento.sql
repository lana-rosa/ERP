-- Compras SENA (nuevo modelo de pagos 2026): agregar después el comprobante de pago o el extracto a una compra del Fondo.
create or replace function public.fn_compra_agregar_documento(p_id uuid, p_clave text, p_ruta text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'Debes iniciar sesión.'; end if;
  if coalesce(public.fn_rol_actual()::text, '') <> 'administrador' then raise exception 'Solo la administradora puede agregar soportes.' using errcode = '42501'; end if;
  if p_clave not in ('comprobante_pago', 'extracto_bancario') then raise exception 'Documento no permitido.'; end if;
  if coalesce(p_ruta, '') = '' or p_ruta like '%..%' then raise exception 'Ruta no válida.'; end if;
  update public.compras_requisitos_sena set documentos = coalesce(documentos, '{}'::jsonb) || jsonb_build_object(p_clave, p_ruta) where id = p_id;
  if not found then raise exception 'No se encontró la compra.'; end if;
end $$;
revoke all on function public.fn_compra_agregar_documento(uuid, text, text) from public, anon;
grant execute on function public.fn_compra_agregar_documento(uuid, text, text) to authenticated;
