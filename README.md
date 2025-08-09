# Claude Code Agent Manager

Una herramienta unificada y avanzada para gestionar agentes especializados de Claude Code a múltiples niveles.

## Descripción

Este proyecto proporciona una herramienta completa para organizar, instalar y gestionar agentes especializados de Claude Code. Incluye una interfaz unificada con visualización de tres columnas, gestión multi-nivel (usuario/proyecto), y operaciones CRUD completas.

## Estructura del Proyecto

```
.
├── agent-manager.sh              # 🌟 Script unificado principal
├── copy-agents.sh                # Script básico de copia (legacy)
├── copy-agents-interactive.sh    # Interfaz interactiva (legacy)
├── copy-agents-multilevel.sh     # Script multi-nivel (legacy)
├── agents-collection/            # Colección de agentes disponibles
│   ├── platform/                 # Agentes de gestión de plataforma
│   ├── frontend/                 # Agentes de desarrollo frontend
│   ├── backend/                  # Agentes de desarrollo backend
│   └── infrastructure/           # Agentes de infraestructura
└── examples/                     # Ejemplos de proyectos específicos
```

## Uso

### 🐍 Gestor Python con Curses (RECOMENDADO)

```bash
./agent-manager.py
```

**Ventajas**:
- ✅ ESC y flechas funcionan perfectamente
- ✅ Interfaz más robusta y fluida
- ✅ Sin problemas de detección de teclas
- ✅ Mejor manejo de errores

### 🌟 Gestor Bash Interactivo

```bash
./agent-manager.sh
```

**Nota**: Usa 'b' para volver (ESC no es compatible con flechas en bash).

Características principales:
- 📊 **Vista de tres columnas**: Usuario | Proyecto | Disponibles
- 🔄 **Múltiples modos**: Vista, Edición Usuario, Edición Proyecto, Instalación
- ✅ **Operaciones CRUD completas**: Create, Read, Update, Delete
- 🎯 **Panel de detalles**: Información completa del agente seleccionado
- 🔀 **Sincronización**: Entre niveles usuario y proyecto
- 🎨 **Interfaz visual avanzada**: Con colores y símbolos intuitivos

### Modos de Operación

#### 🔍 Modo Vista (Predeterminado)
- Ver todos los agentes organizados por nivel de instalación
- Navegar con flechas arriba/abajo
- Acceder a otros modos con teclas numéricas

#### ✏️ Modo Edición Usuario/Proyecto
- Gestionar agentes instalados en cada nivel
- Seleccionar/deseleccionar con ESPACIO
- Guardar cambios con 's'
- Eliminar seleccionados con 'd'

#### 📦 Modo Instalación
- Instalar nuevos agentes desde la colección
- Elegir destino: Usuario (1) o Proyecto (2)
- Selección múltiple con checkboxes

### Controles de Navegación

#### Modo Vista:
- `↑/↓`: Navegar entre agentes
- `1`: Editar agentes de usuario
- `2`: Editar agentes de proyecto
- `3`: Instalar nuevos agentes
- `4`: Sincronizar entre niveles
- `q`: Salir

#### Modos de Edición/Instalación:
- `↑/↓`: Navegar entre agentes
- `ESPACIO`: Seleccionar/deseleccionar
- `a`: Seleccionar todos
- `n`: Deseleccionar todos
- `d`: Eliminar seleccionado (solo edición)
- `s`: Guardar cambios (solo edición)
- `1/2`: Instalar en Usuario/Proyecto (solo instalación)
- `ESC`: Volver al modo vista

### 🖥️ Gestor CLI (Para automatización)

```bash
./agent-manager-cli.sh [comando] [opciones]
```

Comandos disponibles:
- `list`: Lista todos los agentes y su estado de instalación
- `status`: Muestra resumen de instalación
- `install --user --agent NAME`: Instala agente específico
- `install-all --project`: Instala todos los agentes en proyecto

Ejemplos:
```bash
./agent-manager-cli.sh list
./agent-manager-cli.sh install --user --agent openapi-expert
./agent-manager-cli.sh install-all --project
./agent-manager-cli.sh status
```

### Scripts Legacy

Para compatibilidad, se mantienen los scripts anteriores:

```bash
./copy-agents-interactive.sh     # Instalador interactivo original
./copy-agents-multilevel.sh      # Selector de nivel
./copy-agents.sh                  # Script básico
```

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

## Niveles de Instalación

Claude Code soporta agentes en dos niveles:

### 🌍 Nivel Usuario (`~/.claude/agents/`)
- **Alcance**: Disponibles en todos tus proyectos
- **Uso**: Agentes de uso general que usas frecuentemente
- **Persistencia**: Personal, no se comparten

### 📁 Nivel Proyecto (`.claude/agents/`)
- **Alcance**: Específicos del proyecto actual
- **Uso**: Agentes especializados para el proyecto
- **Persistencia**: Se pueden versionar con Git y compartir con el equipo

### 🎯 Script Multi-Nivel

```bash
./copy-agents-multilevel.sh
```

Este script detecta automáticamente:
- El nivel de instalación deseado
- La raíz del proyecto (si existe)
- Crea `.gitignore` apropiado para proyectos

### Ejemplo de uso en equipo:
```bash
# En el proyecto, instalar agentes específicos
./copy-agents-multilevel.sh  # Seleccionar opción 2 (Proyecto)

# Commitear para compartir con el equipo
git add .claude/agents/
git commit -m "Add project-specific Claude agents"
git push
```

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