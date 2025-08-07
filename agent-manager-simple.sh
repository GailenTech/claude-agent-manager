#!/bin/bash

# Simple Agent Manager - Works in any terminal
set -e

# Colors (simplified)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Paths
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AGENTS_COLLECTION="$SCRIPT_DIR/agents-collection"
USER_AGENTS="$HOME/.claude/agents"
PROJECT_AGENTS=""
PROJECT_ROOT=""

# Detect project
detect_project() {
    local dir=$(pwd)
    while [[ "$dir" != "/" ]]; do
        if [[ -d "$dir/.git" ]]; then
            PROJECT_ROOT="$dir"
            PROJECT_AGENTS="$dir/.claude/agents"
            return 0
        fi
        dir=$(dirname "$dir")
    done
    return 1
}

# Show menu
show_menu() {
    clear
    echo -e "${BOLD}${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║              Claude Agent Manager - Simple Version                ║${NC}"
    echo -e "${BOLD}${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [[ -n "$PROJECT_ROOT" ]]; then
        echo -e "${GREEN}📁 Proyecto detectado: $(basename "$PROJECT_ROOT")${NC}"
    else
        echo -e "${YELLOW}⚠ Sin proyecto detectado (solo modo usuario)${NC}"
    fi
    echo ""
    
    echo -e "${BOLD}Opciones:${NC}"
    echo -e "  ${CYAN}1)${NC} Ver agentes instalados"
    echo -e "  ${CYAN}2)${NC} Instalar todos los agentes (usuario)"
    echo -e "  ${CYAN}3)${NC} Instalar todos los agentes (proyecto)"
    echo -e "  ${CYAN}4)${NC} Usar instalador interactivo legacy"
    echo -e "  ${CYAN}5)${NC} Usar CLI avanzado"
    echo -e "  ${CYAN}6)${NC} Limpiar agentes (usuario)"
    echo -e "  ${CYAN}7)${NC} Limpiar agentes (proyecto)"
    echo -e "  ${CYAN}q)${NC} Salir"
    echo ""
}

# List installed agents
list_installed() {
    echo -e "\n${BOLD}${CYAN}Agentes instalados:${NC}\n"
    
    # User level
    if [[ -d "$USER_AGENTS" ]]; then
        local user_count=$(find "$USER_AGENTS" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
        echo -e "${GREEN}Nivel Usuario (~/.claude/agents/): $user_count agentes${NC}"
        if [[ $user_count -gt 0 ]]; then
            for file in "$USER_AGENTS"/*.md; do
                [[ -f "$file" ]] && echo "  • $(basename "$file" .md)"
            done
        fi
    else
        echo -e "${DIM}Nivel Usuario: No configurado${NC}"
    fi
    
    echo ""
    
    # Project level
    if [[ -n "$PROJECT_ROOT" ]] && [[ -d "$PROJECT_AGENTS" ]]; then
        local project_count=$(find "$PROJECT_AGENTS" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
        echo -e "${YELLOW}Nivel Proyecto (.claude/agents/): $project_count agentes${NC}"
        if [[ $project_count -gt 0 ]]; then
            for file in "$PROJECT_AGENTS"/*.md; do
                [[ -f "$file" ]] && echo "  • $(basename "$file" .md)"
            done
        fi
    else
        echo -e "${DIM}Nivel Proyecto: No disponible${NC}"
    fi
    
    echo -e "\nPresiona ENTER para continuar..."
    read
}

# Install all agents
install_all() {
    local level=$1
    local dest_dir=""
    
    if [[ "$level" == "user" ]]; then
        dest_dir="$USER_AGENTS"
        echo -e "\n${CYAN}Instalando todos los agentes a nivel usuario...${NC}"
    elif [[ "$level" == "project" ]]; then
        if [[ -z "$PROJECT_ROOT" ]]; then
            echo -e "\n${RED}Error: No se detectó un proyecto${NC}"
            echo "Presiona ENTER para continuar..."
            read
            return
        fi
        dest_dir="$PROJECT_AGENTS"
        echo -e "\n${CYAN}Instalando todos los agentes a nivel proyecto...${NC}"
    fi
    
    mkdir -p "$dest_dir"
    local count=0
    
    for category in platform frontend backend infrastructure; do
        if [[ -d "$AGENTS_COLLECTION/$category" ]]; then
            for agent in "$AGENTS_COLLECTION/$category"/*.md; do
                if [[ -f "$agent" ]]; then
                    local name=$(basename "$agent" .md)
                    cp "$agent" "$dest_dir/${name}.md"
                    echo -e "  ${GREEN}✓${NC} $name"
                    ((count++))
                fi
            done
        fi
    done
    
    echo -e "\n${GREEN}$count agentes instalados${NC}"
    echo "Presiona ENTER para continuar..."
    read
}

# Clean agents
clean_agents() {
    local level=$1
    local dest_dir=""
    
    if [[ "$level" == "user" ]]; then
        dest_dir="$USER_AGENTS"
        echo -e "\n${YELLOW}¿Eliminar todos los agentes de nivel usuario?${NC}"
    elif [[ "$level" == "project" ]]; then
        if [[ -z "$PROJECT_ROOT" ]]; then
            echo -e "\n${RED}Error: No se detectó un proyecto${NC}"
            echo "Presiona ENTER para continuar..."
            read
            return
        fi
        dest_dir="$PROJECT_AGENTS"
        echo -e "\n${YELLOW}¿Eliminar todos los agentes de nivel proyecto?${NC}"
    fi
    
    echo -e "Directorio: $dest_dir"
    echo -ne "Confirmar (s/n): "
    read confirm
    
    if [[ "$confirm" == "s" ]] || [[ "$confirm" == "S" ]]; then
        if [[ -d "$dest_dir" ]]; then
            rm -f "$dest_dir"/*.md
            echo -e "${GREEN}Agentes eliminados${NC}"
        fi
    else
        echo -e "${CYAN}Operación cancelada${NC}"
    fi
    
    echo "Presiona ENTER para continuar..."
    read
}

# Main loop
main() {
    detect_project
    
    while true; do
        show_menu
        echo -ne "Selección: "
        read -n1 choice
        echo ""
        
        case "$choice" in
            1)
                list_installed
                ;;
            2)
                install_all "user"
                ;;
            3)
                install_all "project"
                ;;
            4)
                echo -e "\n${CYAN}Lanzando instalador interactivo legacy...${NC}"
                exec "$SCRIPT_DIR/copy-agents-interactive.sh"
                ;;
            5)
                echo -e "\n${CYAN}Mostrando ayuda del CLI avanzado...${NC}"
                "$SCRIPT_DIR/agent-manager-cli.sh" help
                echo -e "\nPresiona ENTER para continuar..."
                read
                ;;
            6)
                clean_agents "user"
                ;;
            7)
                clean_agents "project"
                ;;
            q|Q)
                clear
                echo -e "${CYAN}¡Hasta luego!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Opción inválida${NC}"
                sleep 1
                ;;
        esac
    done
}

# Run
main