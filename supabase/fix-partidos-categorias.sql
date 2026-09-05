-- ============================================================
-- FIX + FEATURE: partidos con VARIAS categorias
-- 1) Agrega la columna categorias (jsonb array) para poder
--    asignar mas de una categoria por partido.
-- 2) Rellena categorias con la categoria unica existente para
--    no perder datos de los partidos ya creados.
-- 3) Reafirma la politica de acceso anon en partidos (por si el
--    "Error al crear partido" es por RLS sin politica).
--
-- Idempotente: se puede correr varias veces sin dano.
-- Ejecutar en: Supabase -> SQL Editor
-- ============================================================

-- 1) Nueva columna para varias categorias
alter table partidos
    add column if not exists categorias jsonb not null default '[]';

-- 2) La columna categoria (unica) deja de ser obligatoria, porque
--    ahora la fuente de verdad es categorias[]. Mantenerla NOT NULL
--    haria fallar los inserts que solo mandan categorias.
alter table partidos
    alter column categoria drop not null;

-- 3) Backfill: para partidos viejos que tengan categoria pero no
--    categorias, copiar la categoria unica dentro del array.
update partidos
set categorias = to_jsonb(array[categoria])
where (categorias is null or categorias = '[]'::jsonb)
  and categoria is not null
  and categoria <> '';

-- 4) Reafirmar RLS + politica anon en partidos
alter table partidos enable row level security;
drop policy if exists "anon_full_access" on partidos;
create policy "anon_full_access" on partidos
    for all using (true) with check (true);

-- 5) Verificacion
select column_name, data_type, is_nullable
from information_schema.columns
where table_name = 'partidos'
order by ordinal_position;
