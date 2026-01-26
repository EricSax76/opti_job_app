# OptiJob Landing Page

Landing page construida con Astro para la plataforma OptiJob de matching laboral con inteligencia artificial.

## Características

- 🎨 **Diseño radical**: Paleta oscura con acentos vibrantes que se diferencia de portales tradicionales de empleo
- 🚀 **Astro estático**: Rendimiento óptimo y SEO mejorado
- 📱 **Responsive**: Diseño adaptado a móvil, tablet y desktop
- ⚡ **CSS moderno**: Variables CSS, grid, flexbox y animaciones fluidas
- 🇪🇸 **Cumplimiento legal español**: Footer con todos los enlaces legales requeridos

## Estructura del proyecto

```
landing/
├── src/
│   ├── pages/
│   │   └── index.astro          # Página principal
│   ├── layouts/
│   │   └── Layout.astro         # Layout base con meta tags
│   ├── components/
│   │   ├── Hero.astro           # Sección hero con título y CTAs
│   │   ├── Features.astro       # Características del producto
│   │   ├── HowItWorks.astro     # Proceso para candidatos y empresas
│   │   ├── CTA.astro            # Call to action final
│   │   └── Footer.astro         # Footer con links legales
│   └── styles/
│       └── global.css           # Estilos globales y variables CSS
├── public/
│   └── favicon.svg              # Icono del sitio
├── astro.config.mjs             # Configuración de Astro
├── package.json
└── tsconfig.json
```

## Desarrollo

Para ejecutar la landing page localmente:

```bash
cd landing

# Instalar dependencias (requiere conexión a internet)
npm install

# Iniciar servidor de desarrollo
npm run dev

# La página estará disponible en http://localhost:4321
```

## Compilación para producción

```bash
npm run build
```

Los archivos estáticos se generarán en el directorio `dist/`.

## Diseño

### Paleta de colores

- **Primary (Electric Blue)**: #0066FF - Energía, innovación
- **Secondary (Neon Green)**: #00FF88 - Éxito, crecimiento
- **Background**: #0A0A0F - Fondo principal oscuro
- **Surface**: #1A1A24 - Tarjetas y secciones
- **Text**: #F5F5F7 - Texto principal

### Tipografía

- Sistema de fuentes nativas para rendimiento óptimo
- Escala fluida de tamaños usando `clamp()`
- Peso 800 para títulos principales (bold)

### Componentes

#### Hero

- Título impactante con gradiente
- Dual CTA (candidatos/empresas)
- Estadísticas de valor
- Elementos visuales animados (orbes flotantes, grid de fondo)

#### Features

- 6 características principales en grid
- Iconos SVG personalizados
- Efectos hover con glow y transformación

#### How It Works

- Procesos separados para candidatos y empresas
- Sistema de pasos numerados
- Layout en columnas con separador visual

#### Footer (Legal)

Incluye todos los enlaces legales requeridos en España:

- ✅ Aviso legal
- ✅ Política de privacidad
- ✅ Política de cookies
- ✅ Condiciones de uso
- Información de registro mercantil
- Enlaces a redes sociales

## Diferenciación

Este diseño se aleja radicalmente de portales de empleo tradicionales:

- **No tradicional**: Evita el azul corporativo genérico y layouts convencionales
- **IA-first**: Enfoca el mensaje en tecnología de matching inteligente
- **Directo**: Sin intermediarios ni procesos complicados
- **Transparente**: Comunicación clara de costes y proceso
- **Moderno**: Uso de glassmorphism, gradientes y micro-animaciones

## Notas

- Esta landing es independiente de la aplicación Flutter principal
- Requiere instalación de dependencias via npm (Astro)
- Optimizada para SEO con meta tags en español
- Accesible con estados de foco visibles y estructura semántica
