#!/bin/bash

# Claude Agent Manager - CLI version (non-interactive)
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Paths
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AGENTS_COLLECTION="$SCRIPT_DIR/agents-collection"
USER_AGENTS="$HOME/.claude/agents"
PROJECT_AGENTS=""
PROJECT_ROOT=""

# Detect project root
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

# Show help
show_help() {
    echo -e "${BOLD}${BLUE}╔════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║                      Claude Agent Manager - CLI Version                        ║${NC}"
    echo -e "${BOLD}${BLUE}╚════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BOLD}Uso:${NC}"
    echo -e "  $0 [comando] [opciones]"
    echo ""
    echo -e "${BOLD}Comandos:${NC}"
    echo -e "  ${CYAN}list${NC}              Lista todos los agentes disponibles y su estado"
    echo -e "  ${CYAN}install${NC}           Instala agentes (interactivo)"
    echo -e "  ${CYAN}install-all${NC}       Instala todos los agentes disponibles"
    echo -e "  ${CYAN}status${NC}            Muestra el estado actual de instalación"
    echo -e "  ${CYAN}sync${NC}              Sincroniza agentes entre niveles"
    echo -e "  ${CYAN}help${NC}              Muestra esta ayuda"
    echo ""
    echo -e "${BOLD}Opciones de instalación:${NC}"
    echo -e "  ${CYAN}--user${NC}            Instala a nivel usuario (~/.claude/agents/)"
    echo -e "  ${CYAN}--project${NC}         Instala a nivel proyecto (.claude/agents/)"
    echo -e "  ${CYAN}--agent NAME${NC}      Instala un agente específico"
    echo ""
    echo -e "${BOLD}Ejemplos:${NC}"
    echo -e "  $0 list"
    echo -e "  $0 install --user --agent openapi-expert"
    echo -e "  $0 install-all --project"
    echo -e "  $0 status"
    echo ""
}

# List all agents
list_agents() {
    echo -e "${BOLD}${CYAN}Agentes Disponibles:${NC}"
    echo ""
    
    for category in platform frontend backend infrastructure; do
        if [[ -d "$AGENTS_COLLECTION/$category" ]]; then
            echo -e "${BOLD}${YELLOW}$category:${NC}"
            for agent in "$AGENTS_COLLECTION/$category"/*.md; do
                if [[ -f "$agent" ]]; then
                    local name=$(basename "$agent" .md)
                    local desc=$(grep "^description:" "$agent" 2>/dev/null | sed 's/description: //' | head -c 60) || desc=""
                    
                    # Check installation status
                    local status="${RED}✗${NC}"
                    local location=""
                    
                    if [[ -f "$USER_AGENTS/${name}.md" ]] && [[ -f "$PROJECT_AGENTS/${name}.md" ]]; then
                        status="${GREEN}✓✓${NC}"
                        location=" (usuario + proyecto)"
                    elif [[ -f "$USER_AGENTS/${name}.md" ]]; then
                        status="${GREEN}✓${NC}"
                        location=" (usuario)"
                    elif [[ -f "$PROJECT_AGENTS/${name}.md" ]]; then
                        status="${YELLOW}✓${NC}"
                        location=" (proyecto)"
                    fi
                    
                    printf "  %b %-25s %s%s\n" "$status" "$name" "$desc" "$location"
                fi
            done
            echo ""
        fi
    done
}

# Show status
show_status() {
    echo -e "${BOLD}${CYAN}Estado de Instalación:${NC}"
    echo ""
    
    # Count agents
    local total=$(find "$AGENTS_COLLECTION" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    local user_count=0
    local project_count=0
    
    if [[ -d "$USER_AGENTS" ]]; then
        user_count=$(find "$USER_AGENTS" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    fi
    
    if [[ -n "$PROJECT_ROOT" ]] && [[ -d "$PROJECT_AGENTS" ]]; then
        project_count=$(find "$PROJECT_AGENTS" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    fi
    
    echo -e "${BOLD}Resumen:${NC}"
    echo -e "  • Total disponibles: $total"
    echo -e "  • Instalados (usuario): $user_count"
    if [[ -n "$PROJECT_ROOT" ]]; then
        echo -e "  • Instalados (proyecto): $project_count"
        echo -e "  • Proyecto: $(basename "$PROJECT_ROOT")"
    else
        echo -e "  • ${DIM}Sin proyecto detectado${NC}"
    fi
    echo ""
}

# Install specific agent
install_agent() {
    local level=$1
    local agent_name=$2
    
    local dest_dir=""
    if [[ "$level" == "user" ]]; then
        dest_dir="$USER_AGENTS"
    elif [[ "$level" == "project" ]]; then
        if [[ -z "$PROJECT_ROOT" ]]; then
            echo -e "${RED}Error: No se detectó un proyecto${NC}"
            exit 1
        fi
        dest_dir="$PROJECT_AGENTS"
    else
        echo -e "${RED}Error: Nivel inválido '$level'${NC}"
        exit 1
    fi
    
    # Find agent file
    local source=""
    for category in platform frontend backend infrastructure; do
        if [[ -f "$AGENTS_COLLECTION/$category/${agent_name}.md" ]]; then
            source="$AGENTS_COLLECTION/$category/${agent_name}.md"
            break
        fi
    done
    
    if [[ -z "$source" ]]; then
        echo -e "${RED}Error: Agente '$agent_name' no encontrado${NC}"
        exit 1
    fi
    
    # Create directory and copy
    mkdir -p "$dest_dir"
    cp "$source" "$dest_dir/${agent_name}.md"
    echo -e "${GREEN}✓${NC} Instalado '$agent_name' en $level"
}

# Install all agents
install_all() {
    local level=$1
    
    local dest_dir=""
    if [[ "$level" == "user" ]]; then
        dest_dir="$USER_AGENTS"
    elif [[ "$level" == "project" ]]; then
        if [[ -z "$PROJECT_ROOT" ]]; then
            echo -e "${RED}Error: No se detectó un proyecto${NC}"
            exit 1
        fi
        dest_dir="$PROJECT_AGENTS"
    else
        echo -e "${RED}Error: Nivel inválido '$level'${NC}"
        exit 1
    fi
    
    mkdir -p "$dest_dir"
    
    echo -e "${CYAN}Instalando todos los agentes en $level...${NC}"
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
    
    echo -e "\n${GREEN}$count agentes instalados en $level${NC}"
}

# Main
detect_project

case "${1:-help}" in
    list)
        list_agents
        ;;
    status)
        show_status
        ;;
    install)
        shift
        level=""
        agent=""
        
        while [[ $# -gt 0 ]]; do
            case $1 in
                --user)
                    level="user"
                    shift
                    ;;
                --project)
                    level="project"
                    shift
                    ;;
                --agent)
                    agent="$2"
                    shift 2
                    ;;
                *)
                    echo -e "${RED}Opción desconocida: $1${NC}"
                    exit 1
                    ;;
            esac
        done
        
        if [[ -z "$level" ]]; then
            echo -e "${RED}Error: Especifica --user o --project${NC}"
            exit 1
        fi
        
        if [[ -n "$agent" ]]; then
            install_agent "$level" "$agent"
        else
            echo -e "${YELLOW}Usa --agent NAME para especificar un agente${NC}"
            echo -e "${YELLOW}O usa 'install-all' para instalar todos${NC}"
        fi
        ;;
    install-all)
        shift
        level=""
        
        while [[ $# -gt 0 ]]; do
            case $1 in
                --user)
                    level="user"
                    shift
                    ;;
                --project)
                    level="project"
                    shift
                    ;;
                *)
                    echo -e "${RED}Opción desconocida: $1${NC}"
                    exit 1
                    ;;
            esac
        done
        
        if [[ -z "$level" ]]; then
            echo -e "${RED}Error: Especifica --user o --project${NC}"
            exit 1
        fi
        
        install_all "$level"
        ;;
    sync)
        echo -e "${CYAN}Sincronización no disponible en modo CLI${NC}"
        echo -e "${YELLOW}Usa el script interactivo: ./agent-manager.sh${NC}"
        ;;
    help|--help|-h|"")
        show_help
        ;;
    *)
        echo -e "${RED}Comando desconocido: $1${NC}"
        show_help
        exit 1
        ;;
esac