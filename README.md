# Claude Agent Manager

Una herramienta profesional para gestionar agentes especializados de Claude Code con una interfaz intuitiva basada en curses.

## 🚀 Instalación Rápida

### Requisitos
- Python 3.6+
- Terminal con soporte para curses
- Git (para clonar el repositorio)

### Instalación

```bash
# Clonar el repositorio
git clone https://github.com/GailenTech/single-spa-platform-agents.git claude-agent-manager
cd claude-agent-manager

# Ejecutar el instalador
chmod +x install.sh
./install.sh
```

El instalador te ofrecerá tres opciones:
1. **Instalación sistema** (`/usr/local/bin`) - Recomendado
2. **Instalación usuario** (`~/.local/bin`) - Sin sudo
3. **Ubicación personalizada**

### Uso

Una vez instalado, simplemente ejecuta:

```bash
agent-manager
```

## 🎮 Controles

### Navegación
- `↑/↓` - Navegar por la lista de agentes
- `SPACE` - Seleccionar/deseleccionar agente
- `1` - Vista General (agentes de usuario)
- `2` - Vista Proyecto (agentes del proyecto actual)

### Acciones
- `v` - Ver contenido del agente (solo lectura)
- `s` - Guardar cambios (con confirmación)
- `r` - Recargar y descartar cambios
- `ESC` - Cancelar cambios pendientes
- `q` - Salir

### Indicadores Visuales
- `[✓]` - Agente instalado/seleccionado
- `[ ]` - Agente no instalado/no seleccionado
- `+` (verde) - Agente será añadido
- `-` (rojo) - Agente será eliminado
- `*` - Agente nuevo (< 48 horas)

## 📂 Estructura de Agentes

Los agentes están organizados por categorías:

```
═══ PLATFORM ═══
  Agentes para gestión de productos y plataformas

═══ FRONTEND ═══
  Desarrolladores especializados en interfaces de usuario

═══ BACKEND ═══
  Expertos en servicios y APIs backend

═══ INFRASTRUCTURE ═══
  Especialistas en DevOps, testing y arquitectura
```

## 🔧 Niveles de Instalación

### 🌍 Vista General (Usuario)
- **Ubicación**: `~/.claude/agents/`
- **Alcance**: Disponibles en todos tus proyectos
- **Uso**: Agentes que usas frecuentemente

### 📁 Vista Proyecto
- **Ubicación**: `[proyecto]/.claude/agents/`
- **Alcance**: Específicos del proyecto actual
- **Uso**: Agentes especializados para el proyecto

## 🎯 Flujo de Trabajo Típico

1. **Primera vez**:
   ```bash
   agent-manager
   # Presiona '1' para Vista General
   # Selecciona agentes con SPACE
   # Guarda con 's'
   ```

2. **En un proyecto específico**:
   ```bash
   cd mi-proyecto
   agent-manager
   # Presiona '2' para Vista Proyecto
   # Selecciona agentes específicos del proyecto
   # Guarda con 's'
   ```

3. **Ver qué hace un agente**:
   ```bash
   agent-manager
   # Navega al agente
   # Presiona 'v' para ver su contenido
   ```

## 🗑️ Desinstalación

Si necesitas desinstalar la herramienta:

```bash
chmod +x uninstall.sh
./uninstall.sh
```

**Nota**: La desinstalación preserva tus agentes instalados en `~/.claude/agents/`

## 📝 Características

- ✅ **Interfaz intuitiva** con navegación natural (ESC, flechas)
- ✅ **Vista dual** para gestión usuario/proyecto
- ✅ **Confirmación visual** antes de aplicar cambios
- ✅ **Código de colores** para cambios pendientes
- ✅ **Visor integrado** para examinar agentes
- ✅ **Detección automática** de proyectos Git
- ✅ **Instalación global** disponible desde cualquier directorio

## 🤝 Contribuir

Para añadir nuevos agentes:

1. Crea el archivo `.md` en la carpeta apropiada dentro de `agents-collection/`
2. Usa el formato estándar con frontmatter YAML:
   ```markdown
   ---
   name: nombre-del-agente
   description: Descripción breve del agente
   color: blue
   model: claude-3-5-sonnet-20241022
   ---
   
   # Instrucciones del agente
   
   Tu contenido aquí...
   ```

## 📄 Licencia

Proyecto privado. Todos los derechos reservados.