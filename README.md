# Claude Agent Manager

Gestor de agentes especializados para Claude Code.

![Claude Agent Manager Interface](docs/images/screenshot.png)

## Instalación

### Opción 1: Script de instalación (recomendado)
```bash
git clone https://github.com/GailenTech/claude-agent-manager.git
cd claude-agent-manager
./install.sh
```

El instalador:
- Añade `agent-manager` al PATH del sistema
- Instala en `/usr/local/bin` (sistema) o `~/.local/bin` (usuario)
- Copia la colección de agentes a una ubicación centralizada
- Configura todo automáticamente

### Opción 2: Binario standalone
Si prefieres un ejecutable único que no requiera Python instalado:

```bash
# Generar binario con PyInstaller
./build-binary.sh

# O generar binario optimizado con Nuitka (más rápido, más pequeño)
./build-binary-nuitka.sh

# Instalar el binario
sudo cp dist/agent-manager-* /usr/local/bin/agent-manager
```

## Uso

```bash
agent-manager
```

### Controles
- `↑/↓` Navegar
- `→/←` Expandir/Colapsar carpetas
- `SPACE` Seleccionar agente o expandir/colapsar carpeta
- `1` Vista Proyecto
- `2` Vista Usuario
- `v` Ver contenido del agente
- `s` Guardar cambios
- `q` Salir

### Características
- **Estructura de árbol**: Navega por categorías y subcarpetas de agentes
- **Dos niveles de instalación**: Usuario (`~/.claude/agents`) o Proyecto (`.claude/agents`)
- **Seguimiento de cambios**: Visualiza qué se añadirá (+) o eliminará (-) antes de guardar
- **Códigos de color**: Azul para vista Usuario, Verde para vista Proyecto
- **Vista previa**: Lee el contenido de los agentes antes de instalarlos

## Desinstalar

```bash
./uninstall.sh
```

## Desarrollo

### Estructura del proyecto
```
claude-agent-manager/
├── agent-manager           # Script principal
├── agents-collection/      # Colección de agentes organizados por categoría
│   ├── platform/
│   ├── frontend/
│   ├── backend/
│   └── infrastructure/
├── install.sh             # Instalador
├── uninstall.sh          # Desinstalador
├── build-binary.sh       # Generador de binario con PyInstaller
└── build-binary-nuitka.sh # Generador de binario optimizado con Nuitka
```

## Licencia

© GailenTech - Todos los derechos reservados