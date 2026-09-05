-- ============================================================
-- Míster App — Cancha Directa Barranquilla
-- Esquema Supabase v2 (mora por mes, catálogo con stock,
-- inventario editable, transacciones, perfil personalizable)
-- Ejecutar en: Supabase → SQL Editor
--
-- Si ya corriste una versión anterior de este archivo, puedes
-- correr este de nuevo tal cual: usa "if not exists" / "or replace"
-- en todo, y no borra datos existentes en las tablas que ya creaste.
-- ============================================================

create extension if not exists pgcrypto;

-- ------------------------------------------------------------
-- alumnos (jugador + acudiente)
-- ------------------------------------------------------------
create table if not exists alumnos (
    id uuid primary key default gen_random_uuid(),
    nombre text not null,                -- nombre del jugador
    acudiente text not null,             -- nombre del padre/acudiente
    telefono text not null,              -- formato internacional, ej: 573001234567
    categoria text not null,             -- año de nacimiento: '2011'..'2018'
    talla text not null default '10',
    activo boolean not null default true,
    uniforme_local boolean not null default false,
    uniforme_visitante boolean not null default false,
    uniforme_torneo boolean not null default false,
    created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- pagos_mensuales (ledger de mora — un registro por alumno+mes)
-- ------------------------------------------------------------
create table if not exists pagos_mensuales (
    id uuid primary key default gen_random_uuid(),
    alumno_id uuid not null references alumnos(id) on delete cascade,
    mes_key text not null,               -- 'YYYY-MM'
    pagado boolean not null default false,
    fecha_pago timestamptz,
    metodo_pago text,
    monto numeric not null default 80000,
    created_at timestamptz not null default now(),
    unique (alumno_id, mes_key)
);

-- ------------------------------------------------------------
-- conceptos (catálogo de cobros: inscripción, uniformes, torneos...)
-- stock_total / stock_vendido: inventario propio del artículo,
-- editable por el Míster, se actualiza solo al vender.
-- ------------------------------------------------------------
create table if not exists conceptos (
    id uuid primary key default gen_random_uuid(),
    nombre text not null,
    precio numeric not null default 0,
    tipo text not null default 'otro' check (tipo in ('inscripcion', 'uniforme', 'evento', 'otro')),
    plazo date,                          -- fecha límite de pago (opcional)
    stock_total int,                     -- null = sin control de stock
    stock_vendido int not null default 0,
    activo boolean not null default true,
    created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- concepto_compras (quién compró/pagó cada artículo — se borra
-- en cascada si se elimina el concepto o el alumno, pero la
-- transacción financiera en `transacciones` queda intacta)
-- ------------------------------------------------------------
create table if not exists concepto_compras (
    id uuid primary key default gen_random_uuid(),
    concepto_id uuid not null references conceptos(id) on delete cascade,
    alumno_id uuid not null references alumnos(id) on delete cascade,
    transaccion_id uuid,
    precio_pagado numeric not null default 0,
    created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- transacciones (historial financiero — nunca se borra al
-- eliminar un concepto del catálogo)
-- ------------------------------------------------------------
create table if not exists transacciones (
    id uuid primary key default gen_random_uuid(),
    alumno_id uuid references alumnos(id) on delete set null,
    alumno_nombre text not null,
    acudiente text,
    categoria text,
    fecha date not null default current_date,
    metodo text not null,
    meses jsonb not null default '[]',       -- ["2026-08", "2026-09"]
    conceptos jsonb not null default '[]',   -- [{"nombre":"Inscripción","precio":60000}]
    total numeric not null default 0,
    recibo_numero int not null,
    created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- partidos + convocatorias
-- ------------------------------------------------------------
create table if not exists partidos (
    id uuid primary key default gen_random_uuid(),
    rival text not null,
    fecha date not null,
    hora time not null,
    cancha text not null,
    categoria text not null,
    arbitraje numeric not null default 0,
    completado boolean not null default false,
    created_at timestamptz not null default now()
);

create table if not exists convocatorias (
    id uuid primary key default gen_random_uuid(),
    partido_id uuid not null references partidos(id) on delete cascade,
    alumno_id uuid not null references alumnos(id) on delete cascade,
    created_at timestamptz not null default now(),
    unique (partido_id, alumno_id)
);

-- ------------------------------------------------------------
-- inventario_uniformes (stock editable por categoría + tipo)
-- ------------------------------------------------------------
create table if not exists inventario_uniformes (
    id uuid primary key default gen_random_uuid(),
    categoria text not null,
    tipo text not null check (tipo in ('local', 'visitante', 'torneo')),
    total int not null default 0,
    entregados int not null default 0,
    unique (categoria, tipo)
);

-- ------------------------------------------------------------
-- respuestas_rapidas
-- ------------------------------------------------------------
create table if not exists respuestas_rapidas (
    id uuid primary key default gen_random_uuid(),
    titulo text not null,
    texto text not null,
    orden int not null default 0,
    activo boolean not null default true
);

-- ------------------------------------------------------------
-- activity_log (actividad reciente / notificaciones)
-- ------------------------------------------------------------
create table if not exists activity_log (
    id uuid primary key default gen_random_uuid(),
    icon text not null default 'check_circle',
    title text not null,
    subtitle text,
    read boolean not null default false,
    created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- ajustes (fila única de configuración: mensualidad, corte,
-- plantilla de WhatsApp, webhook de n8n)
-- ------------------------------------------------------------
create table if not exists ajustes (
    id int primary key default 1,
    mensualidad numeric not null default 80000,
    fecha_corte int not null default 29, -- TEMP: prueba de ciclo de mora (regla estricta original: 30)
    reminder_template text,
    webhook_url text,
    constraint ajustes_single_row check (id = 1)
);
insert into ajustes (id) values (1) on conflict (id) do nothing;

-- ------------------------------------------------------------
-- perfil (fila única: datos de la escuela, logo/foto, colores)
-- ------------------------------------------------------------
create table if not exists perfil (
    id int primary key default 1,
    nombre_escuela text not null default 'Cancha Directa',
    ciudad text not null default 'Barranquilla, Colombia',
    foto_url text,
    color_primario text not null default '#0d631b',
    color_primario_container text not null default '#2e7d32',
    constraint perfil_single_row check (id = 1)
);
insert into perfil (id) values (1) on conflict (id) do nothing;

-- ------------------------------------------------------------
-- Auto-reparación: si alguna de estas tablas ya existía en tu
-- Supabase con una estructura antigua/parcial (creada a mano o con
-- una versión anterior de este script), esto agrega cualquier
-- columna que le falte sin tocar las que ya existen ni las filas
-- que ya tengas. "add column if not exists" es un no-op si la
-- columna ya está, así que correr esto de nuevo siempre es seguro.
-- ------------------------------------------------------------
alter table alumnos
    add column if not exists nombre text,
    add column if not exists acudiente text,
    add column if not exists telefono text,
    add column if not exists categoria text,
    add column if not exists talla text default '10',
    add column if not exists activo boolean default true,
    add column if not exists uniforme_local boolean default false,
    add column if not exists uniforme_visitante boolean default false,
    add column if not exists uniforme_torneo boolean default false,
    add column if not exists created_at timestamptz default now();

alter table pagos_mensuales
    add column if not exists alumno_id uuid references alumnos(id) on delete cascade,
    add column if not exists mes_key text,
    add column if not exists pagado boolean default false,
    add column if not exists fecha_pago timestamptz,
    add column if not exists metodo_pago text,
    add column if not exists monto numeric default 80000,
    add column if not exists created_at timestamptz default now();

-- Fix: en instalaciones creadas antes de que esta tabla tuviera el
-- "unique (alumno_id, mes_key)" de arriba, el upsert con onConflict
-- de la app falla con 42P10 ("no unique or exclusion constraint
-- matching"). Se limpia cualquier duplicado (deja el más reciente)
-- y luego se agrega la restricción si todavía no existe.
delete from pagos_mensuales a
using pagos_mensuales b
where a.alumno_id = b.alumno_id
  and a.mes_key = b.mes_key
  and a.ctid < b.ctid;

do $$
begin
    if not exists (
        select 1 from pg_constraint
        where conrelid = 'pagos_mensuales'::regclass
          and contype = 'u'
    ) then
        alter table pagos_mensuales
            add constraint pagos_mensuales_alumno_id_mes_key_key
            unique (alumno_id, mes_key);
    end if;
end $$;

alter table conceptos
    add column if not exists nombre text,
    add column if not exists precio numeric default 0,
    add column if not exists tipo text default 'otro',
    add column if not exists plazo date,
    add column if not exists stock_total int,
    add column if not exists stock_vendido int default 0,
    add column if not exists activo boolean default true,
    add column if not exists created_at timestamptz default now();

alter table concepto_compras
    add column if not exists concepto_id uuid references conceptos(id) on delete cascade,
    add column if not exists alumno_id uuid references alumnos(id) on delete cascade,
    add column if not exists transaccion_id uuid,
    add column if not exists precio_pagado numeric default 0,
    add column if not exists created_at timestamptz default now();

alter table transacciones
    add column if not exists alumno_id uuid references alumnos(id) on delete set null,
    add column if not exists alumno_nombre text,
    add column if not exists acudiente text,
    add column if not exists categoria text,
    add column if not exists fecha date default current_date,
    add column if not exists metodo text,
    add column if not exists meses jsonb default '[]',
    add column if not exists conceptos jsonb default '[]',
    add column if not exists total numeric default 0,
    add column if not exists recibo_numero int,
    add column if not exists created_at timestamptz default now();

alter table partidos
    add column if not exists rival text,
    add column if not exists fecha date,
    add column if not exists hora time,
    add column if not exists cancha text,
    add column if not exists categoria text,
    add column if not exists arbitraje numeric default 0,
    add column if not exists completado boolean default false,
    add column if not exists created_at timestamptz default now();

alter table convocatorias
    add column if not exists partido_id uuid references partidos(id) on delete cascade,
    add column if not exists alumno_id uuid references alumnos(id) on delete cascade,
    add column if not exists created_at timestamptz default now();

alter table inventario_uniformes
    add column if not exists categoria text,
    add column if not exists tipo text,
    add column if not exists total int default 0,
    add column if not exists entregados int default 0;

alter table respuestas_rapidas
    add column if not exists titulo text,
    add column if not exists texto text,
    add column if not exists orden int default 0,
    add column if not exists activo boolean default true;

alter table activity_log
    add column if not exists icon text default 'check_circle',
    add column if not exists title text,
    add column if not exists subtitle text,
    add column if not exists read boolean default false,
    add column if not exists created_at timestamptz default now();

alter table ajustes
    add column if not exists mensualidad numeric default 80000,
    add column if not exists fecha_corte int default 29,
    add column if not exists reminder_template text,
    add column if not exists webhook_url text;

alter table perfil
    add column if not exists nombre_escuela text default 'Cancha Directa',
    add column if not exists ciudad text default 'Barranquilla, Colombia',
    add column if not exists foto_url text,
    add column if not exists color_primario text default '#0d631b',
    add column if not exists color_primario_container text default '#2e7d32';

-- ------------------------------------------------------------
-- Row Level Security: la app no tiene pantalla de login (se abre
-- directo con la anon/publishable key), así que las políticas
-- permiten acceso completo con esa key. La anon key es pública
-- por diseño (viaja en el código del cliente) — esto asume que la
-- app no es de acceso público sin control (ej. solo el Míster y su
-- equipo conocen la URL/instalación).
-- ------------------------------------------------------------
alter table alumnos enable row level security;
alter table pagos_mensuales enable row level security;
alter table conceptos enable row level security;
alter table concepto_compras enable row level security;
alter table transacciones enable row level security;
alter table partidos enable row level security;
alter table convocatorias enable row level security;
alter table inventario_uniformes enable row level security;
alter table respuestas_rapidas enable row level security;
alter table activity_log enable row level security;
alter table ajustes enable row level security;
alter table perfil enable row level security;

do $$
declare
    t text;
begin
    for t in select unnest(array[
        'alumnos','pagos_mensuales','conceptos','concepto_compras','transacciones',
        'partidos','convocatorias','inventario_uniformes','respuestas_rapidas',
        'activity_log','ajustes','perfil'
    ])
    loop
        execute format('drop policy if exists "authenticated_full_access" on %I;', t);
        execute format('drop policy if exists "anon_full_access" on %I;', t);
        execute format(
            'create policy "anon_full_access" on %I for all using (true) with check (true);',
            t
        );
    end loop;
end $$;

-- ------------------------------------------------------------
-- Storage: bucket público para la foto de perfil / logo de la
-- escuela (crea el bucket "perfil" desde Storage si este bloque
-- falla por permisos; luego re-ejecuta las políticas de abajo).
-- ------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('perfil', 'perfil', true)
on conflict (id) do nothing;

drop policy if exists "perfil_escritura_autenticada" on storage.objects;
drop policy if exists "perfil_actualizacion_autenticada" on storage.objects;
drop policy if exists "perfil_borrado_autenticado" on storage.objects;

create policy if not exists "perfil_lectura_publica"
    on storage.objects for select
    using (bucket_id = 'perfil');

create policy if not exists "perfil_escritura_anon"
    on storage.objects for insert
    with check (bucket_id = 'perfil');

create policy if not exists "perfil_actualizacion_anon"
    on storage.objects for update
    using (bucket_id = 'perfil');

create policy if not exists "perfil_borrado_anon"
    on storage.objects for delete
    using (bucket_id = 'perfil');

-- ------------------------------------------------------------
-- Datos semilla (inventario base + respuestas rápidas + catálogo)
-- Ajusta las cantidades reales antes de usar en producción.
-- ------------------------------------------------------------
insert into inventario_uniformes (categoria, tipo, total, entregados) values
    ('2015', 'local', 45, 0), ('2015', 'visitante', 45, 0), ('2015', 'torneo', 20, 0)
on conflict (categoria, tipo) do nothing;

insert into respuestas_rapidas (titulo, texto, orden) values
    ('Información general', '¡Hola! Gracias por tu interés en Cancha Directa. Somos una escuela de fútbol ubicada en Barranquilla con categorías desde los 7 hasta los 14 años. Los entrenamientos son de lunes a viernes.', 1),
    ('Costos y mensualidad', 'La mensualidad es de $80.000 con fecha de corte el 29 de cada mes. Incluye entrenamiento 5 días a la semana, hidratación y seguro deportivo.', 2),
    ('Horarios de entrenamiento', 'Los horarios por categoría son: 2016-2018 (Sub-7/9): 3:00-4:30 PM | 2014-2015 (Sub-10/11): 4:30-6:00 PM | 2011-2013 (Sub-12/14): 6:00-7:30 PM', 3),
    ('Requisitos de inscripción', 'Para inscribir a tu hijo necesitas: documento de identidad del niño, EPS vigente, foto reciente tamaño 3x4 y el formulario de inscripción diligenciado.', 4)
on conflict do nothing;

insert into conceptos (nombre, precio, tipo, plazo, stock_total, stock_vendido) values
    ('Inscripción', 60000, 'inscripcion', null, null, 0),
    ('Uniforme Local (camiseta+pantaloneta)', 90000, 'uniforme', null, 50, 0),
    ('Uniforme Visitante', 90000, 'uniforme', null, 50, 0),
    ('Torneo Sagrado Corazón', 50000, 'evento', '2026-09-15', 30, 0),
    ('Carné deportivo', 15000, 'otro', null, null, 0)
on conflict do nothing;
