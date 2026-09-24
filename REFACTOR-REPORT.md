# Informe de Refactorización — Limpieza de Deuda Técnica

**Fecha:** 2026-09-24
**Alcance:** meta-análisis diagnóstico de todo el repositorio (`index.html` + archivos de soporte) y limpieza de lo que ya no sirve, es redundante, está obsoleto o duplica lógica.

## Resumen

- **Código JS muerto:** se auditaron las 174 funciones y 40 variables globales de `index.html` de forma automatizada (cada función/variable contra todas sus referencias). **No se encontró ninguna huérfana real.** Es consecuencia directa de que, a lo largo de esta sesión, cada cambio ya venía acompañado de su propio cruce de IDs/handlers/funciones antes de commitear — no se había dejado acumular ese tipo de deuda.
- **5 archivos/carpetas eliminados** por ser peligrosos, redundantes u obsoletos (detalle abajo), liberando ~5.700 líneas y ~4.2 MB de contenido sin ninguna relación con la app en producción.
- **2 archivos de documentación sincronizados** (`AGENTS.md` estaba desactualizado frente a `CLAUDE.md`).
- **2 puntos de lógica financiera duplicada centralizados** en una sola función cada uno, para que un cambio futuro no se pueda aplicar en un lugar y olvidar en otro.
- **Regresión completa tras la limpieza: 9 suites, 109 pasos, todos en verde** — cero cambios de comportamiento, solo limpieza y centralización.

---

## Metodología

1. **Código muerto:** script en Python que extrae cada `function nombre(...)` y cada `let`/`const` de nivel superior del bloque `<script>` principal, y cuenta cuántas veces se referencia ese nombre en el resto del archivo (incluyendo `onclick=`/`onchange=`/`onsubmit=` en el HTML). Un conteo de referencias ≤ 1 (solo su propia declaración) marca un candidato a "muerto".
2. **HTML huérfano:** mismo enfoque para atributos `id="..."`: se buscó cada id contra `getElementById`, `querySelector(All)` y selectores `#id`, incluyendo variantes con comillas simples/dobles/backticks y arrays de ids iterados con `.forEach`.
3. **Archivos de soporte:** revisión manual de cada archivo fuera de `index.html` (los 3 `.sql` de `supabase/`, el `.sql` de la raíz, `AGENTS.md`/`CLAUDE.md`, `manifest.json`, `sw.js`, `.claudeignore`/`.claudepignore`, y las carpetas/zip que no son código) para verificar si su contenido sigue siendo necesario, si está duplicado en otro archivo, o si quedó desincronizado.
4. **Lógica duplicada:** búsqueda de patrones de cálculo financiero repetidos textualmente (`... .length * MENSUALIDAD`, sumas de conceptos, etc.) en más de un lugar del código.
5. **Validación:** cada hallazgo se verificó leyendo el código real antes de tocarlo (para descartar falsos positivos — varios candidatos automáticos resultaron ser usos legítimos vía `.forEach`, plantillas con backticks, o handlers inline que reciben el `event` directamente sin necesitar `getElementById`).

---

## Eliminado (con la razón de cada uno)

### 🔴 `supabase-fix-completo.sql` (raíz del repo, 378 líneas)
Era un snapshot **viejo y peligroso** del esquema completo, congelado en un punto anterior de este proyecto. Comparado con `supabase/schema.sql` (la fuente de verdad actual), le faltaban:
- El rename de la columna `mensualidad` → `valor_mensualidad` — **de hecho todavía tenía el nombre incorrecto** que causó el error 400 al guardar configuración y los montos de cobro inconsistentes en una tarea anterior.
- Un `fecha_corte` de valor `29`, marcado en su propio comentario como "TEMP: prueba de ciclo de mora".
- La tabla `sedes` completa (arquitectura multisede).
- El fix de `categoria` nullable en `partidos` y el `unique constraint` de `pagos_mensuales`.

**Riesgo real:** si alguien lo hubiera ejecutado por error en vez de `supabase/schema.sql` (nombre muy parecido, mismo propósito aparente), habría **revivido exactamente el bug ya corregido**. Se eliminó por completo; `supabase/schema.sql` es la única fuente de verdad del esquema.

### 🟡 `supabase/fix-partidos-categorias.sql` y `supabase/fix-storage-logo.sql`
Parches puntuales de una sola vez. Se verificó que **el 100% de su contenido ya está incorporado** dentro de `supabase/schema.sql` (columna `categorias` jsonb con backfill, bucket de Storage `perfil` + sus 4 políticas). Mantenerlos aparte no aportaba nada y sí arriesgaba que alguien los editara pensando que hacía falta, dejando la misma información en dos lugares con posibilidad de divergir. Se eliminó también el comentario en `schema.sql` que apuntaba al archivo de `categorias` ya borrado.

### 🟡 `stitch_gesti_n_escuela_de_f_tbol/` + `stitch_gesti_n_escuela_de_f_tbol.zip` (4.2 MB)
Maquetas estáticas exportadas de la herramienta de diseño (Google Stitch) usada como referencia visual antes de escribir la app real en `index.html`. No las referencia nada del código ni de la documentación — de hecho, ya estaban marcadas en `.claudeignore`/`.claudepignore` como "no es código" desde antes de esta limpieza, lo que confirma que ya se consideraban descartables. El `.zip` era, además, una copia redundante del propio directorio.

### 🟡 `sistemas_informacion_gerencial_uatlantico.html`
Un trabajo universitario ("Clasificación de los Sistemas de Información — Universidad del Atlántico") sin ninguna relación con Cancha Directa, aparentemente copiado por error a este repositorio. Se eliminó del repo de la app; sigue disponible en el historial de git si hace falta recuperarlo.

---

## Sincronizado (no eliminado, pero estaba desactualizado)

### `AGENTS.md` vs `CLAUDE.md`
Ambos archivos cumplen el mismo rol — reglas del proyecto para asistentes de IA — pero para convenciones distintas (`CLAUDE.md` es la de Claude Code; `AGENTS.md` es una convención más nueva que usan otras herramientas). Habían divergido: `AGENTS.md` todavía decía categorías "2011, 2012...2018" (sin la ampliación a 2022) y no mencionaba que la mensualidad/fecha de corte son editables desde la app. Se igualó el contenido de los dos para que ninguna herramienta reciba reglas de negocio distintas según cuál archivo lea. Se aprovechó para agregar en ambos una nota explícita sobre el nombre real de la columna (`valor_mensualidad`), justamente para que ese bug en particular no se repita.

### `.claudeignore` / `.claudepignore`
Se quitó la entrada de la carpeta de Stitch, ya que esa carpeta ya no existe.

---

## Centralizado (misma lógica, un solo lugar cada una)

### `getDeudaTotal()` — deuda de un alumno
Antes: la fórmula `getPendingMonths(alumno).length * MENSUALIDAD` estaba repetida manualmente en el banner del modal de cobro y en la exportación a Excel, en vez de llamar a la función que ya existía para eso.

**Cambio:** `getDeudaTotal(alumno, ledgerAlumno)` ahora acepta un `ledgerAlumno` opcional, igual que `getPendingMonths` (de la que depende) — así la exportación a Excel, que necesita usar un snapshot de ledger propio en vez del `ledgerMap` global, también puede llamar a la misma función centralizada. Los dos puntos que repetían la fórmula ahora llaman a `getDeudaTotal(...)`.

### `calcularTotalCobro()` — total del modal de registrar pago
Antes: `updateCobroTotal()` (la vista previa en vivo mientras el Míster marca meses/conceptos) y `confirmarCobro()` (el cobro que efectivamente se guarda) calculaban el total — meses de mensualidad seleccionados + conceptos seleccionados — con la **misma fórmula escrita dos veces**. Un cambio futuro a esa fórmula (por ejemplo, un descuento por pago anticipado) se podía aplicar en una función y olvidar en la otra, generando que la vista previa mostrara un monto distinto al que realmente se cobra.

**Cambio:** nueva función `calcularTotalCobro()` que ambas funciones llaman por igual.

---

## Falsos positivos descartados (para que quede constancia de que se investigaron)

La detección automática de "ids nunca referenciados" marcó 17 candidatos; se revisó cada uno individualmente y **todos resultaron ser usos legítimos**, no código muerto:
- `view-inicio`, `view-alumnos`, `view-cobros`, `view-calendario`, `view-mas`: se acceden con una plantilla dinámica `` `view-${view}` `` dentro de `navigateTo()`, no con un string literal.
- `mas-escuela-nombre`, `recibo-escuela-nombre`, `recibo-logo`, `bolante-logo`: se actualizan iterando un array de ids (`['mas-escuela-nombre', 'recibo-escuela-nombre'].forEach(...)`) o dentro de un `querySelectorAll('#a, #b, #c')` combinado — patrones que el detector automático no cubre.
- `inp-perfil-foto`, `form-editar-alumno`, `btn-search-toggle`: se usan desde su propio atributo `onchange`/`onsubmit`/`onclick` inline, que recibe el `event` directamente sin necesitar `getElementById`.
- `btn-concepto-submit`, `btn-plantilla-submit`, `cobro-metodo-group`, `mi-cuenta-email`, `tailwind-config`: son ids sobre elementos donde solo un hijo (el `-label`) o ningún elemento necesita ser targeteado por JS — atributos inertes pero no "código muerto" (no ejecutan nada, no hay nada que romper al dejarlos).

También se verificó exhaustivamente que **no queda ninguna otra referencia desincronizada** a `mensualidad` (sin el prefijo `valor_`) en todo el repo. Los únicos usos que quedan son el nombre de la variable JS `MENSUALIDAD`, ids de formulario como `inp-config-mensualidad`, el placeholder `{mensualidad}` de las plantillas de mensajes, y la lógica de rename automático en `schema.sql`, que necesita mencionar el nombre viejo a propósito (es la que lo corrige si aparece).

---

## Preparación para próximas features

- La **arquitectura de sedes** (tabla `sedes` + `sede_id` nullable en `alumnos`/`partidos`/`transacciones`/`inventario_uniformes`) y el **catálogo de conceptos** ya tienen sus propias funciones de acceso a datos independientes (`cargarSedes`/`crearSedeDB`, `cargarConceptos`/`crearConceptoDB`/etc.), separadas del resto de la lógica de cobros — listas para que la segmentación por sede y la vista de ingresos sigan creciendo sin tener que tocar `getPendingMonths`, `getDeudaTotal` ni `calcularTotalCobro`.
- Con la deuda financiera ya centralizada en esas dos funciones, cualquier regla nueva (descuentos, recargos por mora, mensualidad distinta por categoría, etc.) tiene un único lugar para implementarse en vez de tener que buscar todos los puntos donde se repetía el cálculo.

---

## Validación

- Sintaxis del script principal: sin errores (`node --check`).
- Cruce automático de IDs (`getElementById` vs `id=`), handlers (`onclick`/`onchange`/`onsubmit` vs funciones declaradas) y funciones duplicadas: sin discrepancias.
- Regresión completa: `full-flow-test.js` (28), `race-fix-test.js` (11), `reminder-round-test.js` (13), `config-cobros-test.js` (7), `perfil-unificado-test.js` (7), `mora-inscripcion-test.js` (9), `qa-sweep-test.js` (17), `inventario-clamp-test.js` (3), `bugfixes-sept24-test.js` (14) — **109/109 pasos en verde**, sin ningún cambio de comportamiento observable.

## Cambios de archivos en esta limpieza

- Eliminados: `supabase-fix-completo.sql`, `supabase/fix-partidos-categorias.sql`, `supabase/fix-storage-logo.sql`, `stitch_gesti_n_escuela_de_f_tbol/` (+ zip), `sistemas_informacion_gerencial_uatlantico.html`.
- Modificados: `index.html` (centralización de `getDeudaTotal`/`calcularTotalCobro`), `supabase/schema.sql` (comentario colgante eliminado), `AGENTS.md` (sincronizado con `CLAUDE.md`), `.claudeignore`/`.claudepignore` (entrada obsoleta eliminada).
