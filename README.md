# Claude Code Agent Manager

Una herramienta interactiva para gestionar e instalar agentes especializados de Claude Code.

## Descripción

Este proyecto proporciona herramientas para organizar, seleccionar e instalar agentes especializados de Claude Code en tu entorno local. Incluye una interfaz interactiva con checkboxes, previsualización de agentes, y gestión de conflictos.

## Estructura del Proyecto

```
.
├── copy-agents.sh                # Script básico de copia
├── copy-agents-interactive.sh    # Interfaz interactiva completa
├── agents-collection/            # Colección de agentes disponibles
│   ├── platform/                 # Agentes de gestión de plataforma
│   ├── frontend/                 # Agentes de desarrollo frontend
│   ├── backend/                  # Agentes de desarrollo backend
│   └── infrastructure/           # Agentes de infraestructura
└── examples/                     # Ejemplos de proyectos específicos
```

## Uso

### Instalador Interactivo (Recomendado)

```bash
./copy-agents-interactive.sh
```

Características:
- ✅ Interfaz visual con checkboxes
- 📋 Vista previa de descripción de cada agente
- 📊 Panel de seleccionados en múltiples columnas
- 🔄 Navegación completa (adelante/atrás)
- 🔍 Detección y gestión de conflictos con diff
- 📁 Creación automática de directorios

### Controles de navegación:
- `↑/↓`: Navegar entre agentes
- `ESPACIO`: Seleccionar/deseleccionar agente
- `a`: Seleccionar todos
- `n`: Deseleccionar todos
- `ENTER`: Continuar al siguiente paso
- `b`: Volver al paso anterior
- `q`: Salir

### Script Básico

```bash
./copy-agents.sh
```

Script con línea de comandos tradicional para casos simples.

## Agentes Disponibles

La colección incluye agentes especializados para diferentes roles y tecnologías:

### 🏛️ Platform
- **Platform Product Owner**: Gestión de producto de plataforma
- **Single-SPA Developer**: Desarrollo de shells y micro-frontends
- **Platform Tester**: Testing de integraciones y plataformas
- **Service Product Owner**: Gestión de servicios individuales

### 🎨 Frontend
- **VanillaJS Developer**: Desarrollo sin frameworks
- **Vue3 Developer**: Desarrollo reactivo con Vue 3
- **React Developer**: Desarrollo moderno con React

### ⚙️ Backend
- **Spring Developer**: Microservicios con Spring Boot
- **Python Developer**: APIs con FastAPI/Flask
- **Node.js Developer**: Servicios con Express/Fastify
- **Temporal Developer**: Workflows con Temporal.io
- **OpenAPI Expert**: Especificaciones y generación de código

### 🔧 Infrastructure
- **Tech Architect**: Arquitectura cloud y decisiones técnicas
- **Platform Developer**: DevOps y sistemas de desarrollo
- **E2E Tester**: Testing end-to-end y automatización

## Instalación

1. Clona este repositorio
2. Haz los scripts ejecutables:
   ```bash
   chmod +x copy-agents.sh copy-agents-interactive.sh
   ```
3. Ejecuta el instalador interactivo:
   ```bash
   ./copy-agents-interactive.sh
   ```

## Directorio de Destino

Los agentes se instalan típicamente en:
```
~/.claude/agents/
```

Aunque puedes especificar cualquier directorio personalizado.

## Ejemplos de Proyectos

La carpeta `examples/` contiene configuraciones y documentación específica para diferentes tipos de proyectos, incluyendo guías de arquitectura y patrones de desarrollo.

## Contribuir

Para añadir nuevos agentes:

1. Crea el archivo `.md` en la carpeta apropiada dentro de `agents-collection/`
2. Usa el formato estándar:
   ```markdown
   ---
   name: nombre-del-agente
   description: Descripción breve del agente
   color: color-para-ui
   ---
   
   # Nombre del Agente
   
   Descripción detallada y instrucciones...
   ```
3. Testa con el script interactivo

## Licencia

Proyecto privado. Todos los derechos reservados.