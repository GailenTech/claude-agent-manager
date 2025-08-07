#!/bin/bash

# Script mejorado con soporte para instalación a nivel usuario y proyecto
set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Directorio base
AGENTS_DIR="$(cd "$(dirname "$0")/agents-collection" && pwd)"

echo -e "${BOLD}${BLUE}╔════════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${BLUE}║                       Claude Code Agent Manager - Multi-Level                   ║${NC}"
echo -e "${BOLD}${BLUE}╚════════════════════════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${BOLD}${CYAN}Selecciona el nivel de instalación:${NC}\n"

echo -e "  ${BOLD}1)${NC} ${GREEN}Nivel Usuario${NC} (~/.claude/agents/)"
echo -e "     ${DIM}• Disponible en todos tus proyectos"
echo -e "     ${DIM}• Instalación global personal${NC}\n"

echo -e "  ${BOLD}2)${NC} ${YELLOW}Nivel Proyecto${NC} (.claude/agents/)"
echo -e "     ${DIM}• Específico para este proyecto"
echo -e "     ${DIM}• Se puede compartir con el equipo vía Git${NC}\n"

echo -e "  ${BOLD}3)${NC} ${CYAN}Directorio Personalizado${NC}"
echo -e "     ${DIM}• Especifica tu propia ruta${NC}\n"

read -p "Selección (1-3): " level_choice

case $level_choice in
    1)
        DEST_DIR="$HOME/.claude/agents"
        echo -e "\n${GREEN}✓ Instalación a nivel usuario seleccionada${NC}"
        ;;
    2)
        # Buscar el directorio del proyecto actual
        CURRENT_DIR=$(pwd)
        
        # Buscar hacia arriba hasta encontrar un .git o llegar a root
        while [[ "$CURRENT_DIR" != "/" ]]; do
            if [[ -d "$CURRENT_DIR/.git" ]]; then
                PROJECT_ROOT="$CURRENT_DIR"
                break
            fi
            CURRENT_DIR=$(dirname "$CURRENT_DIR")
        done
        
        if [[ -z "$PROJECT_ROOT" ]]; then
            # Si no hay .git, usar el directorio actual
            PROJECT_ROOT=$(pwd)
            echo -e "\n${YELLOW}⚠ No se encontró un repositorio Git${NC}"
            echo -e "Usando directorio actual: $PROJECT_ROOT"
        else
            echo -e "\n${GREEN}✓ Proyecto detectado: $PROJECT_ROOT${NC}"
        fi
        
        DEST_DIR="$PROJECT_ROOT/.claude/agents"
        
        # Preguntar si crear .gitignore para .claude si no existe
        if [[ ! -f "$PROJECT_ROOT/.claude/.gitignore" ]]; then
            echo -e "\n${YELLOW}¿Deseas crear un .gitignore para excluir archivos temporales de .claude?${NC}"
            echo -e "${DIM}(Recomendado si vas a commitear los agentes)${NC}"
            read -p "[s/n]: " create_gitignore
            
            if [[ "$create_gitignore" == "s" ]]; then
                mkdir -p "$PROJECT_ROOT/.claude"
                cat > "$PROJECT_ROOT/.claude/.gitignore" << 'EOF'
# Claude Code temporary files
projects/
sessions/
shell-snapshots/
statsig/
todos/
*.jsonl
.DS_Store
settings.json
mcp_settings.json
EOF
                echo -e "${GREEN}✓ .gitignore creado${NC}"
            fi
        fi
        ;;
    3)
        echo -e "\n${CYAN}Ingresa la ruta completa:${NC}"
        read -e -p "> " DEST_DIR
        DEST_DIR="${DEST_DIR/#\~/$HOME}"
        echo -e "${GREEN}✓ Usando: $DEST_DIR${NC}"
        ;;
    *)
        echo -e "${RED}Opción inválida${NC}"
        exit 1
        ;;
esac

# Crear directorio si no existe
if [[ ! -d "$DEST_DIR" ]]; then
    echo -e "\n${YELLOW}El directorio no existe. Creando...${NC}"
    mkdir -p "$DEST_DIR"
    echo -e "${GREEN}✓ Directorio creado${NC}"
fi

# Mostrar resumen
echo -e "\n${BOLD}${BLUE}════════════════════════════════════════${NC}"
echo -e "${BOLD}Destino de instalación:${NC} $DEST_DIR"
echo -e "${BOLD}${BLUE}════════════════════════════════════════${NC}\n"

# Contar agentes disponibles
AGENT_COUNT=$(find "$AGENTS_DIR" -name "*.md" -type f | wc -l | tr -d ' ')
echo -e "${CYAN}Se encontraron $AGENT_COUNT agentes disponibles${NC}"

# Opciones de copia
echo -e "\n${BOLD}Opciones:${NC}"
echo -e "  1) Instalar todos los agentes"
echo -e "  2) Usar instalador interactivo"
echo -e "  3) Cancelar"

read -p "Selección (1-3): " copy_choice

case $copy_choice in
    1)
        echo -e "\n${CYAN}Copiando todos los agentes...${NC}"
        
        # Copiar manteniendo estructura
        for category in platform frontend backend infrastructure; do
            if [[ -d "$AGENTS_DIR/$category" ]]; then
                for agent in "$AGENTS_DIR/$category"/*.md; do
                    if [[ -f "$agent" ]]; then
                        agent_name=$(basename "$agent" .md)
                        cp "$agent" "$DEST_DIR/${agent_name}.md"
                        echo -e "  ${GREEN}✓${NC} ${agent_name}"
                    fi
                done
            fi
        done
        
        echo -e "\n${BOLD}${GREEN}¡Instalación completada!${NC}"
        ;;
    2)
        echo -e "\n${CYAN}Lanzando instalador interactivo...${NC}\n"
        # Modificar temporalmente la variable para el script interactivo
        export CLAUDE_AGENTS_DEST="$DEST_DIR"
        exec "$(dirname "$0")/copy-agents-interactive.sh"
        ;;
    3)
        echo -e "${YELLOW}Operación cancelada${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}Opción inválida${NC}"
        exit 1
        ;;
esac

# Mostrar información adicional según el nivel
echo ""
if [[ "$level_choice" == "1" ]]; then
    echo -e "${DIM}Los agentes están disponibles globalmente en todos tus proyectos${NC}"
elif [[ "$level_choice" == "2" ]]; then
    echo -e "${DIM}Los agentes están disponibles solo en este proyecto${NC}"
    echo -e "${DIM}Puedes commitearlos con: git add .claude/agents${NC}"
fi

echo -e "\n${BOLD}${CYAN}Para verificar los agentes instalados:${NC}"
echo -e "ls -la $DEST_DIR"