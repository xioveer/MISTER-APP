# Míster App - Reglas del Proyecto

## Stack Tecnológico
- HTML5 semántico
- Tailwind CSS (CDN)
- JavaScript vanilla (ES6+)
- Supabase (backend y auth)
- n8n (automatizaciones y flujos)

## Reglas de Negocio Estrictas

### Categorías por Año de Nacimiento
- **Categoría 2011-2013**: Corresponde a Sub-12/Sub-14
- **Categoría 2014-2015**: Corresponde a Sub-10/Sub-11
- **Categoría 2016-2018**: Corresponde a Sub-7/Sub-9

### Lógica Financiera
- Valor de mensualidad: **$80.000 COP**
- Fecha de corte: **15 de cada mes**
- Estados de pago: `pagado` | `pendiente`
- Los recibos digitales deben poder compartirse por **WhatsApp**
- Formato de moneda: Pesos colombianos con separador de miles (punto)

### Inventario de Uniformes
- Tallas disponibles: XS, S, M, L, XL
- Tipos de uniforme:
  - **Local** (Titular/Verde)
  - **Visitante** (Suplente/Blanca)
  - **Alterno** (Edición especial)
- Variable de torneos: Kit especial por temporada de campeonato
- Control de stock por categoría y talla

## Convenciones de Código
- Idioma de la interfaz: Español latinoamericano
- Diseño mobile-first optimizado para 360x800px
- Touch targets mínimos de 48px
- Font principal: Inter (Google Fonts)
- Paleta de colores: Material Design 3 con verde cancha como primario
