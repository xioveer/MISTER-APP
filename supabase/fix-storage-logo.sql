-- ============================================================
-- Habilitar el almacenamiento del LOGO de la escuela
-- (bucket "perfil"). Necesario para que el Mister pueda subir
-- el escudo y que se guarde. Idempotente.
-- Ejecutar en: Supabase -> SQL Editor.
--
-- Si alguna linea de policy falla por permisos, crea el bucket a
-- mano: Supabase -> Storage -> New bucket -> nombre "perfil" -> Public.
-- ============================================================

insert into storage.buckets (id, name, public)
values ('perfil', 'perfil', true)
on conflict (id) do update set public = true;

drop policy if exists "perfil_lectura_publica" on storage.objects;
drop policy if exists "perfil_escritura_anon" on storage.objects;
drop policy if exists "perfil_actualizacion_anon" on storage.objects;
drop policy if exists "perfil_borrado_anon" on storage.objects;

create policy "perfil_lectura_publica"      on storage.objects for select using (bucket_id = 'perfil');
create policy "perfil_escritura_anon"       on storage.objects for insert with check (bucket_id = 'perfil');
create policy "perfil_actualizacion_anon"   on storage.objects for update using (bucket_id = 'perfil');
create policy "perfil_borrado_anon"         on storage.objects for delete using (bucket_id = 'perfil');

select id, name, public from storage.buckets where id = 'perfil';
