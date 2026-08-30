-- ============================================================
-- Míster App — Cancha Directa Barranquilla
-- Esquema Supabase (tablas, vista, función RPC y RLS)
-- Ejecutar en: Supabase → SQL Editor
-- ============================================================

create extension if not exists pgcrypto;

-- ------------------------------------------------------------
-- padres (alumnos + acudientes)
-- ------------------------------------------------------------
create table if not exists padres (
    id uuid primary key default gen_random_uuid(),
    nombre text not null,                -- nombre del acudiente
    nombre_hijo text not null,           -- nombre del alumno
    telefono text not null,              -- formato internacional, ej: 573001234567
    categoria text not null check (categoria in ('2011-2013', '2014-2015', '2016-2018')),
    talla text not null default 'M' check (talla in ('XS', 'S', 'M', 'L', 'XL')),
    activo boolean not null default true,
    created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- pagos (mensualidades)
-- ------------------------------------------------------------
create table if not exists pagos (
    id uuid primary key default gen_random_uuid(),
    padre_id uuid not null references padres(id) on delete cascade,
    mes int not null check (mes between 1 and 12),
    anio int not null,
    monto numeric not null default 80000,
    fecha_pago timestamptz,
    estado text not null default 'pendiente' check (estado in ('pagado', 'pendiente')),
    metodo_pago text,
    created_at timestamptz not null default now(),
    unique (padre_id, mes, anio)
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
    categoria text not null check (categoria in ('2011-2013', '2014-2015', '2016-2018')),
    arbitraje numeric not null default 0,
    completado boolean not null default false,
    created_at timestamptz not null default now()
);

create table if not exists convocatorias (
    id uuid primary key default gen_random_uuid(),
    partido_id uuid not null references partidos(id) on delete cascade,
    padre_id uuid not null references padres(id) on delete cascade,
    confirmado boolean not null default false,
    created_at timestamptz not null default now(),
    unique (partido_id, padre_id)
);

-- ------------------------------------------------------------
-- uniformes (inventario agregado por categoría + tipo)
-- ------------------------------------------------------------
create table if not exists uniformes (
    id uuid primary key default gen_random_uuid(),
    categoria text not null check (categoria in ('2011-2013', '2014-2015', '2016-2018')),
    tipo text not null check (tipo in ('local', 'visitante', 'torneo')),
    total int not null default 0,
    entregados int not null default 0,
    unique (categoria, tipo)
);

-- ------------------------------------------------------------
-- entregas_uniforme (uniformes entregados por alumno)
-- ------------------------------------------------------------
create table if not exists entregas_uniforme (
    id uuid primary key default gen_random_uuid(),
    padre_id uuid not null references padres(id) on delete cascade unique,
    uniforme_local boolean not null default false,
    uniforme_visitante boolean not null default false,
    kit_torneo boolean not null default false,
    updated_at timestamptz not null default now()
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
-- Vista: padres con estado de pago del mes actual (calendario)
-- ------------------------------------------------------------
create or replace view padres_con_pago as
select
    p.*,
    pg.id as pago_id,
    pg.estado as estado_pago,
    pg.fecha_pago,
    pg.metodo_pago,
    pg.monto
from padres p
left join pagos pg
    on pg.padre_id = p.id
    and pg.mes = extract(month from now())::int
    and pg.anio = extract(year from now())::int
where p.activo = true;

-- ------------------------------------------------------------
-- Función RPC: padres activos sin pago 'pagado' en el mes actual
-- ------------------------------------------------------------
create or replace function padres_pendientes_pago()
returns setof padres
language sql
stable
as $$
    select p.*
    from padres p
    where p.activo = true
    and not exists (
        select 1 from pagos pg
        where pg.padre_id = p.id
        and pg.mes = extract(month from now())::int
        and pg.anio = extract(year from now())::int
        and pg.estado = 'pagado'
    );
$$;

-- ------------------------------------------------------------
-- Row Level Security: solo usuarios autenticados (el Míster)
-- pueden leer/escribir. Ajusta esto si más adelante manejas
-- varios roles (ej. varios entrenadores).
-- ------------------------------------------------------------
alter table padres enable row level security;
alter table pagos enable row level security;
alter table partidos enable row level security;
alter table convocatorias enable row level security;
alter table uniformes enable row level security;
alter table entregas_uniforme enable row level security;
alter table respuestas_rapidas enable row level security;

create policy "authenticated_full_access" on padres
    for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "authenticated_full_access" on pagos
    for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "authenticated_full_access" on partidos
    for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "authenticated_full_access" on convocatorias
    for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "authenticated_full_access" on uniformes
    for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "authenticated_full_access" on entregas_uniforme
    for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "authenticated_full_access" on respuestas_rapidas
    for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

-- ------------------------------------------------------------
-- Datos semilla (ajusta las cantidades reales de tu inventario)
-- ------------------------------------------------------------
insert into uniformes (categoria, tipo, total, entregados) values
    ('2011-2013', 'local', 50, 0), ('2011-2013', 'visitante', 50, 0), ('2011-2013', 'torneo', 30, 0),
    ('2014-2015', 'local', 40, 0), ('2014-2015', 'visitante', 40, 0), ('2014-2015', 'torneo', 25, 0),
    ('2016-2018', 'local', 45, 0), ('2016-2018', 'visitante', 45, 0), ('2016-2018', 'torneo', 20, 0)
on conflict (categoria, tipo) do nothing;

insert into respuestas_rapidas (titulo, texto, orden) values
    ('Información general', '¡Hola! Gracias por tu interés en Cancha Directa. Somos una escuela de fútbol ubicada en Barranquilla con categorías desde los 7 hasta los 14 años. Los entrenamientos son de lunes a viernes.', 1),
    ('Costos y mensualidad', 'La mensualidad es de $80.000 con fecha de corte el 15 de cada mes. Incluye entrenamiento 5 días a la semana, hidratación y seguro deportivo.', 2),
    ('Horarios de entrenamiento', 'Los horarios por categoría son: 2016-2018 (Sub-7/9): 3:00-4:30 PM | 2014-2015 (Sub-10/11): 4:30-6:00 PM | 2011-2013 (Sub-12/14): 6:00-7:30 PM', 3),
    ('Requisitos de inscripción', 'Para inscribir a tu hijo necesitas: documento de identidad del niño, EPS vigente, foto reciente tamaño 3x4 y el formulario de inscripción diligenciado.', 4);
