#!/bin/bash

# Claude Agent Manager v2.0 - Advanced unified interface

# Ensure we're running in bash
if [ -z "$BASH_VERSION" ]; then
    echo "This script requires bash. Running with bash..."
    exec bash "$0" "$@"
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'
REVERSE='\033[7m'

# Characters
CHECK="✓"
UNCHECK=" "
ARROW="▶"
BOX_CHECK="[✓]"
BOX_UNCHECK="[ ]"

# Paths
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AGENTS_COLLECTION="$SCRIPT_DIR/agents-collection"
USER_AGENTS="$HOME/.claude/agents"
PROJECT_AGENTS=""
PROJECT_ROOT=""

# State
current_mode="view"  # view, edit_user, edit_project, install, sync
current_index=0
current_level=""
sync_direction=""  # for sync mode: user_to_project, project_to_user, bidirectional
declare -a all_agents=()
declare -a agent_names=()
declare -a agent_descriptions=()
declare -a agent_locations=()  # "user", "project", "available", "both"
declare -a selected=()

# Terminal control
clear_screen() { printf "\033[2J\033[H"; }
move_cursor() { printf "\033[%d;%dH" "$1" "$2"; }
save_cursor() { printf "\033[s"; }
restore_cursor() { printf "\033[u"; }
clear_line() { printf "\033[K"; }
clear_to_bottom() { printf "\033[J"; }

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

# Get agent info from file
get_agent_info() {
    local file=$1
    local name=$(basename "$file" .md)
    local desc="No description"
    local location=""
    
    if [[ -f "$file" ]]; then
        desc=$(grep "^description:" "$file" 2>/dev/null | sed 's/description: //' | head -c 60) || desc="No description"
    fi
    
    echo "$name|$desc"
}

# Load all agents with their locations
load_all_agents() {
    all_agents=()
    agent_names=()
    agent_descriptions=()
    agent_locations=()
    selected=()
    
    # Temporary files for tracking
    local temp_dir="/tmp/agent_manager_$$"
    mkdir -p "$temp_dir"
    trap "rm -rf $temp_dir" RETURN
    
    # Load all available agents first
    while IFS= read -r file; do
        [[ -f "$file" ]] || continue
        local info=$(get_agent_info "$file")
        local name="${info%%|*}"
        local desc="${info#*|}"
        echo "$name|available|$desc" > "$temp_dir/$name.info"
    done < <(find "$AGENTS_COLLECTION" -name "*.md" -type f 2>/dev/null | sort)
    
    # Check user level agents
    if [[ -d "$USER_AGENTS" ]]; then
        while IFS= read -r file; do
            [[ -f "$file" ]] || continue
            local name=$(basename "$file" .md)
            local desc=$(grep "^description:" "$file" 2>/dev/null | sed 's/description: //' | head -c 60) || desc=""
            
            if [[ -f "$temp_dir/$name.info" ]]; then
                # Update existing entry
                local current=$(cat "$temp_dir/$name.info")
                local current_loc="${current#*|}"
                current_loc="${current_loc%%|*}"
                if [[ "$current_loc" == "available" ]]; then
                    echo "$name|user|$desc" > "$temp_dir/$name.info"
                elif [[ "$current_loc" == "project" ]]; then
                    echo "$name|both|$desc" > "$temp_dir/$name.info"
                fi
            else
                echo "$name|user|$desc" > "$temp_dir/$name.info"
            fi
        done < <(find "$USER_AGENTS" -maxdepth 1 -name "*.md" -type f 2>/dev/null | sort)
    fi
    
    # Check project level agents
    if [[ -n "$PROJECT_ROOT" ]] && [[ -d "$PROJECT_AGENTS" ]]; then
        while IFS= read -r file; do
            [[ -f "$file" ]] || continue
            local name=$(basename "$file" .md)
            local desc=$(grep "^description:" "$file" 2>/dev/null | sed 's/description: //' | head -c 60) || desc=""
            
            if [[ -f "$temp_dir/$name.info" ]]; then
                # Update existing entry
                local current=$(cat "$temp_dir/$name.info")
                local current_loc="${current#*|}"
                current_loc="${current_loc%%|*}"
                if [[ "$current_loc" == "available" ]]; then
                    echo "$name|project|$desc" > "$temp_dir/$name.info"
                elif [[ "$current_loc" == "user" ]]; then
                    echo "$name|both|$desc" > "$temp_dir/$name.info"
                fi
            else
                echo "$name|project|$desc" > "$temp_dir/$name.info"
            fi
        done < <(find "$PROJECT_AGENTS" -maxdepth 1 -name "*.md" -type f 2>/dev/null | sort)
    fi
    
    # Build arrays from temp files
    for info_file in $(ls "$temp_dir"/*.info 2>/dev/null | sort); do
        [[ -f "$info_file" ]] || continue
        local content=$(cat "$info_file")
        local name="${content%%|*}"
        local rest="${content#*|}"
        local location="${rest%%|*}"
        local desc="${rest#*|}"
        
        agent_names+=("$name")
        agent_descriptions+=("$desc")
        agent_locations+=("$location")
        selected+=(false)
    done
}

# Draw main interface
draw_interface() {
    clear_screen
    
    # Header
    echo -e "${BOLD}${BLUE}╔═══════════════════════════════════════════════════════════════════════════════════╗${NC}"
    
    case "$current_mode" in
        "view")
            echo -e "${BOLD}${BLUE}║                    Claude Agent Manager - Vista General                           ║${NC}"
            ;;
        "edit_user")
            echo -e "${BOLD}${BLUE}║                  Editando Agentes - Nivel Usuario 🌍                             ║${NC}"
            ;;
        "edit_project")
            echo -e "${BOLD}${BLUE}║                  Editando Agentes - Nivel Proyecto 📁                            ║${NC}"
            ;;
        "install")
            echo -e "${BOLD}${BLUE}║                       Instalar Nuevos Agentes                                     ║${NC}"
            ;;
        "sync")
            echo -e "${BOLD}${BLUE}║                      Sincronizar Agentes 🔄                                      ║${NC}"
            ;;
    esac
    
    echo -e "${BOLD}${BLUE}╚═══════════════════════════════════════════════════════════════════════════════════╝${NC}"
    
    # Project info
    if [[ -n "$PROJECT_ROOT" ]]; then
        move_cursor 4 2
        echo -e "${GREEN}📁 Proyecto: $(basename "$PROJECT_ROOT")${NC}"
    else
        move_cursor 4 2
        echo -e "${YELLOW}⚠ Sin proyecto (solo modo usuario)${NC}"
    fi
    
    # Draw three columns for agent list
    draw_agent_columns
    
    # Draw details panel
    draw_details_panel
    
    # Draw bottom instructions
    draw_instructions
    
    # Draw status bar
    draw_status_bar
}

# Draw agent columns (User | Project | Available)
draw_agent_columns() {
    local start_line=6
    local col1_x=2    # User column
    local col2_x=30   # Project column  
    local col3_x=58   # Available column
    
    # Column headers
    move_cursor $start_line $col1_x
    echo -e "${BOLD}${GREEN}🌍 Usuario${NC}"
    
    if [[ -n "$PROJECT_ROOT" ]]; then
        move_cursor $start_line $col2_x
        echo -e "${BOLD}${YELLOW}📁 Proyecto${NC}"
    fi
    
    move_cursor $start_line $col3_x
    echo -e "${BOLD}${CYAN}📦 Disponibles${NC}"
    
    # Draw separators
    move_cursor $((start_line + 1)) 1
    printf "${DIM}"
    for ((i=1; i<=85; i++)); do printf "─"; done
    printf "${NC}\n"
    
    # List agents by location
    local line=$((start_line + 2))
    local max_lines=12
    local scroll_offset=0
    
    # Calculate scroll offset
    if [[ $current_index -ge $((scroll_offset + max_lines)) ]]; then
        scroll_offset=$((current_index - max_lines + 1))
    elif [[ $current_index -lt $scroll_offset ]]; then
        scroll_offset=$current_index
    fi
    
    # Draw agents
    for ((i=scroll_offset; i<${#agent_names[@]} && i<$((scroll_offset + max_lines)); i++)); do
        local name="${agent_names[$i]}"
        local location="${agent_locations[$i]}"
        local y=$((line + i - scroll_offset))
        
        # Selection indicator
        local marker=" "
        local highlight=""
        if [[ $i -eq $current_index ]]; then
            marker="$ARROW"
            highlight="${BOLD}"
        fi
        
        # Selection checkbox (only in edit modes)
        local checkbox=""
        if [[ "$current_mode" == "edit_"* ]] || [[ "$current_mode" == "install" ]]; then
            if [[ "${selected[$i]}" == "true" ]]; then
                checkbox="[${GREEN}$CHECK${NC}]"
            else
                checkbox="[$UNCHECK]"
            fi
        fi
        
        # Draw based on location
        case "$location" in
            "user")
                move_cursor $y $col1_x
                echo -ne "$marker $checkbox $highlight${name:0:22}${NC}"
                ;;
            "project")
                move_cursor $y $col2_x
                echo -ne "$marker $checkbox $highlight${name:0:22}${NC}"
                ;;
            "available")
                move_cursor $y $col3_x
                echo -ne "$marker $checkbox $highlight${name:0:22}${NC}"
                ;;
            "both")
                move_cursor $y $col1_x
                echo -ne "$marker $checkbox $highlight${name:0:22}${NC}"
                move_cursor $y $col2_x
                echo -ne "  $checkbox $highlight${name:0:22}${NC}"
                ;;
        esac
    done
    
    # Scroll indicator
    if [[ ${#agent_names[@]} -gt $max_lines ]]; then
        move_cursor $((line + max_lines)) 2
        echo -e "${DIM}... $((${#agent_names[@]} - scroll_offset - max_lines)) más ...${NC}"
    fi
}

# Draw details panel
draw_details_panel() {
    local panel_x=88
    local panel_y=6
    
    # Panel border
    for ((i=0; i<=14; i++)); do
        move_cursor $((panel_y + i)) $((panel_x - 1))
        echo -e "${DIM}│${NC}"
    done
    
    move_cursor $panel_y $panel_x
    echo -e "${BOLD}${CYAN}Detalles del Agente${NC}"
    
    if [[ $current_index -lt ${#agent_names[@]} ]]; then
        local name="${agent_names[$current_index]}"
        local desc="${agent_descriptions[$current_index]}"
        local location="${agent_locations[$current_index]}"
        
        move_cursor $((panel_y + 2)) $panel_x
        printf "${BOLD}Nombre:${NC} %.30s" "$name"
        
        move_cursor $((panel_y + 4)) $panel_x
        echo -e "${BOLD}Estado:${NC}"
        
        move_cursor $((panel_y + 5)) $panel_x
        case "$location" in
            "user")
                echo -e "  ${GREEN}✓ Instalado (Usuario)${NC}"
                ;;
            "project")
                echo -e "  ${YELLOW}✓ Instalado (Proyecto)${NC}"
                ;;
            "both")
                echo -e "  ${GREEN}✓ Usuario${NC}"
                move_cursor $((panel_y + 6)) $panel_x
                echo -e "  ${YELLOW}✓ Proyecto${NC}"
                ;;
            "available")
                echo -e "  ${CYAN}○ No instalado${NC}"
                ;;
        esac
        
        move_cursor $((panel_y + 8)) $panel_x
        echo -e "${BOLD}Descripción:${NC}"
        
        # Word wrap description
        local width=35
        local line=9
        while [[ ${#desc} -gt 0 ]] && [[ $line -lt 14 ]]; do
            move_cursor $((panel_y + line)) $panel_x
            if [[ ${#desc} -le $width ]]; then
                printf "%.35s" "$desc"
                break
            else
                local cut_at=$width
                while [[ $cut_at -gt 0 ]] && [[ "${desc:$cut_at:1}" != " " ]]; do
                    ((cut_at--))
                done
                if [[ $cut_at -eq 0 ]]; then cut_at=$width; fi
                
                printf "%.35s" "${desc:0:$cut_at}"
                desc="${desc:$((cut_at+1))}"
                ((line++))
            fi
        done
    fi
}

# Draw instructions
draw_instructions() {
    move_cursor 21 1
    printf "${DIM}"
    for ((i=1; i<=85; i++)); do printf "─"; done
    printf "${NC}\n"
    
    move_cursor 22 2
    
    case "$current_mode" in
        "view")
            echo -e "${DIM}[↑/↓] Navegar  [1] Editar Usuario  [2] Editar Proyecto  [3] Instalar  [4] Sincronizar  [q] Salir${NC}"
            ;;
        "edit_user"|"edit_project")
            echo -e "${DIM}[↑/↓] Navegar  [ESPACIO] Seleccionar  [a] Todos  [n] Ninguno  [d] Eliminar  [s] Guardar  [ESC] Volver${NC}"
            ;;
        "install")
            echo -e "${DIM}[↑/↓] Navegar  [ESPACIO] Seleccionar  [a] Todos  [n] Ninguno  [1] →Usuario  [2] →Proyecto  [ESC] Volver${NC}"
            ;;
        "sync")
            echo -e "${DIM}[1] 📁→🌍 Proyecto a Usuario  [2] 🌍→📁 Usuario a Proyecto  [3] 🔄 Bidireccional  [ESC] Volver${NC}"
            ;;
    esac
}

# Draw status bar
draw_status_bar() {
    move_cursor 24 2
    
    local user_count=0
    local project_count=0
    local available_count=0
    
    for loc in "${agent_locations[@]}"; do
        case "$loc" in
            "user") ((user_count++)) ;;
            "project") ((project_count++)) ;;
            "available") ((available_count++)) ;;
            "both") ((user_count++)); ((project_count++)) ;;
        esac
    done
    
    echo -e "${BOLD}Estado:${NC} Usuario: $user_count | Proyecto: $project_count | Disponibles: $available_count | Total: ${#agent_names[@]}"
}

# Handle edit mode
handle_edit_mode() {
    local level=$1  # "user" or "project"
    
    # Pre-select installed agents
    for i in "${!agent_locations[@]}"; do
        local loc="${agent_locations[$i]}"
        if [[ "$level" == "user" ]]; then
            if [[ "$loc" == "user" ]] || [[ "$loc" == "both" ]]; then
                selected[$i]=true
            else
                selected[$i]=false
            fi
        elif [[ "$level" == "project" ]]; then
            if [[ "$loc" == "project" ]] || [[ "$loc" == "both" ]]; then
                selected[$i]=true
            else
                selected[$i]=false
            fi
        fi
    done
}

# Save changes
save_changes() {
    local level=$1
    local dest_dir=""
    
    if [[ "$level" == "user" ]]; then
        dest_dir="$USER_AGENTS"
    elif [[ "$level" == "project" ]]; then
        dest_dir="$PROJECT_AGENTS"
    else
        return 1
    fi
    
    mkdir -p "$dest_dir"
    
    # Process each agent
    for i in "${!agent_names[@]}"; do
        local name="${agent_names[$i]}"
        local is_selected="${selected[$i]}"
        local location="${agent_locations[$i]}"
        local dest_file="$dest_dir/${name}.md"
        
        if [[ "$is_selected" == "true" ]]; then
            # Should be installed
            if [[ ! -f "$dest_file" ]]; then
                # Find source and copy
                local source=""
                if [[ -f "$AGENTS_COLLECTION/platform/${name}.md" ]]; then
                    source="$AGENTS_COLLECTION/platform/${name}.md"
                elif [[ -f "$AGENTS_COLLECTION/frontend/${name}.md" ]]; then
                    source="$AGENTS_COLLECTION/frontend/${name}.md"
                elif [[ -f "$AGENTS_COLLECTION/backend/${name}.md" ]]; then
                    source="$AGENTS_COLLECTION/backend/${name}.md"
                elif [[ -f "$AGENTS_COLLECTION/infrastructure/${name}.md" ]]; then
                    source="$AGENTS_COLLECTION/infrastructure/${name}.md"
                fi
                
                if [[ -n "$source" ]]; then
                    cp "$source" "$dest_file"
                    echo -e "${GREEN}✓${NC} Instalado: $name"
                fi
            fi
        else
            # Should not be installed
            if [[ -f "$dest_file" ]]; then
                rm "$dest_file"
                echo -e "${RED}✗${NC} Eliminado: $name"
            fi
        fi
    done
    
    sleep 2
}

# Install selected agents
install_selected() {
    local level=$1
    local dest_dir=""
    
    if [[ "$level" == "user" ]]; then
        dest_dir="$USER_AGENTS"
    elif [[ "$level" == "project" ]]; then
        dest_dir="$PROJECT_AGENTS"
    else
        return 1
    fi
    
    mkdir -p "$dest_dir"
    
    local installed=0
    for i in "${!agent_names[@]}"; do
        if [[ "${selected[$i]}" == "true" ]] && [[ "${agent_locations[$i]}" == "available" ]]; then
            local name="${agent_names[$i]}"
            local source=""
            
            # Find source file
            for category in platform frontend backend infrastructure; do
                if [[ -f "$AGENTS_COLLECTION/$category/${name}.md" ]]; then
                    source="$AGENTS_COLLECTION/$category/${name}.md"
                    break
                fi
            done
            
            if [[ -n "$source" ]]; then
                cp "$source" "$dest_dir/${name}.md"
                echo -e "${GREEN}✓${NC} Instalado en $level: $name"
                ((installed++))
            fi
        fi
    done
    
    if [[ $installed -gt 0 ]]; then
        echo -e "\n${GREEN}$installed agentes instalados${NC}"
    else
        echo -e "\n${YELLOW}No se seleccionaron agentes para instalar${NC}"
    fi
    
    sleep 2
}

# Execute sync operation
execute_sync() {
    local direction=$1
    clear_screen
    echo -e "${BOLD}${BLUE}Sincronizando Agentes...${NC}\n"
    
    case "$direction" in
        'project_to_user')
            # Project to User
            if [[ -d "$PROJECT_AGENTS" ]]; then
                mkdir -p "$USER_AGENTS"
                local count=0
                for file in "$PROJECT_AGENTS"/*.md; do
                    if [[ -f "$file" ]]; then
                        cp "$file" "$USER_AGENTS/"
                        echo -e "${GREEN}✓${NC} 📁→🌍 Copiado a usuario: $(basename "$file" .md)"
                        ((count++))
                    fi
                done
                echo -e "\n${GREEN}$count agentes copiados de proyecto a usuario${NC}"
            else
                echo -e "${YELLOW}No hay agentes en el proyecto${NC}"
            fi
            ;;
        'user_to_project')
            # User to Project
            if [[ -d "$USER_AGENTS" ]] && [[ -n "$PROJECT_ROOT" ]]; then
                mkdir -p "$PROJECT_AGENTS"
                local count=0
                for file in "$USER_AGENTS"/*.md; do
                    if [[ -f "$file" ]]; then
                        cp "$file" "$PROJECT_AGENTS/"
                        echo -e "${GREEN}✓${NC} 🌍→📁 Copiado a proyecto: $(basename "$file" .md)"
                        ((count++))
                    fi
                done
                echo -e "\n${GREEN}$count agentes copiados de usuario a proyecto${NC}"
            else
                echo -e "${YELLOW}No hay agentes de usuario o no hay proyecto${NC}"
            fi
            ;;
        'bidirectional')
            # Bidirectional
            if [[ -d "$USER_AGENTS" ]] && [[ -d "$PROJECT_AGENTS" ]]; then
                local count_up=0
                local count_pu=0
                # User to Project
                for file in "$USER_AGENTS"/*.md; do
                    if [[ -f "$file" ]]; then
                        cp "$file" "$PROJECT_AGENTS/"
                        echo -e "${GREEN}✓${NC} 🌍→📁 $(basename "$file" .md)"
                        ((count_up++))
                    fi
                done
                # Project to User
                for file in "$PROJECT_AGENTS"/*.md; do
                    if [[ -f "$file" ]]; then
                        cp "$file" "$USER_AGENTS/"
                        echo -e "${GREEN}✓${NC} 📁→🌍 $(basename "$file" .md)"
                        ((count_pu++))
                    fi
                done
                echo -e "\n${GREEN}Sincronización completa:${NC}"
                echo -e "  • $count_up agentes: usuario → proyecto"
                echo -e "  • $count_pu agentes: proyecto → usuario"
            else
                echo -e "${YELLOW}Faltan directorios para sincronización bidireccional${NC}"
            fi
            ;;
    esac
    
    echo -e "\nPresiona cualquier tecla para continuar..."
    read -n1
}

# Clean exit function
cleanup_and_exit() {
    stty sane 2>/dev/null
    tput cnorm 2>/dev/null
    clear_screen
    echo -e "${CYAN}¡Hasta luego!${NC}"
    exit 0
}

# Main loop
main() {
    # Setup terminal - same as copy-agents-interactive.sh
    stty -echo -icanon min 1 time 0 2>/dev/null || true
    tput civis 2>/dev/null || true  # Hide cursor
    
    # Trap for clean exit - allow Ctrl-C to work
    trap 'cleanup_and_exit' EXIT
    trap 'echo ""; cleanup_and_exit' INT TERM
    
    # Detect project
    detect_project
    
    # Load agents
    load_all_agents
    
    # Main loop
    while true; do
        draw_interface
        
        # Read input
        IFS= read -r -n1 key
        
        case "$key" in
            $'\x1b')  # ESC sequence
                # Try to read next 2 chars with timeout
                rest=""
                if IFS= read -r -t 0.05 -n1 char1 2>/dev/null; then
                    rest="$char1"
                    if IFS= read -r -t 0.05 -n1 char2 2>/dev/null; then
                        rest="${rest}${char2}"
                    fi
                fi
                
                case "$rest" in
                    '[A'|'OA')  # Up arrow
                        ((current_index--))
                        if [[ $current_index -lt 0 ]]; then
                            current_index=$((${#agent_names[@]} - 1))
                        fi
                        ;;
                    '[B'|'OB')  # Down arrow
                        ((current_index++))
                        if [[ $current_index -ge ${#agent_names[@]} ]]; then
                            current_index=0
                        fi
                        ;;
                    '[C'|'OC')  # Right arrow (ignore)
                        ;;
                    '[D'|'OD')  # Left arrow (ignore) 
                        ;;
                    '')  # Just ESC pressed
                        if [[ "$current_mode" != "view" ]]; then
                            current_mode="view"
                            # Clear selections
                            for i in "${!selected[@]}"; do
                                selected[$i]=false
                            done
                            load_all_agents
                        fi
                        ;;
                    *)  # Other escape sequences (ignore)
                        ;;
                esac
                ;;
            
            ' '|$' ')  # Space - select/deselect
                if [[ "$current_mode" == "edit_"* ]] || [[ "$current_mode" == "install" ]]; then
                    if [[ "${selected[$current_index]}" == "true" ]]; then
                        selected[$current_index]=false
                    else
                        selected[$current_index]=true
                    fi
                fi
                ;;
            
            'a'|'A')  # Select all
                if [[ "$current_mode" == "edit_"* ]] || [[ "$current_mode" == "install" ]]; then
                    for i in "${!selected[@]}"; do
                        selected[$i]=true
                    done
                fi
                ;;
            
            'n'|'N')  # Select none
                if [[ "$current_mode" == "edit_"* ]] || [[ "$current_mode" == "install" ]]; then
                    for i in "${!selected[@]}"; do
                        selected[$i]=false
                    done
                fi
                ;;
            
            '1')  # Mode specific action
                case "$current_mode" in
                    "view")
                        current_mode="edit_user"
                        handle_edit_mode "user"
                        ;;
                    "install")
                        install_selected "user"
                        current_mode="view"
                        load_all_agents
                        ;;
                    "sync")
                        execute_sync "project_to_user"
                        current_mode="view"
                        load_all_agents
                        ;;
                esac
                ;;
            
            '2')  # Mode specific action
                case "$current_mode" in
                    "view")
                        if [[ -n "$PROJECT_ROOT" ]]; then
                            current_mode="edit_project"
                            handle_edit_mode "project"
                        fi
                        ;;
                    "install")
                        if [[ -n "$PROJECT_ROOT" ]]; then
                            install_selected "project"
                            current_mode="view"
                            load_all_agents
                        fi
                        ;;
                    "sync")
                        execute_sync "user_to_project"
                        current_mode="view"
                        load_all_agents
                        ;;
                esac
                ;;
            
            '3')  # Install mode or bidirectional sync
                case "$current_mode" in
                    "view")
                        current_mode="install"
                        # Clear all selections
                        for i in "${!selected[@]}"; do
                            selected[$i]=false
                        done
                        ;;
                    "sync")
                        execute_sync "bidirectional"
                        current_mode="view"
                        load_all_agents
                        ;;
                esac
                ;;
            
            '4')  # Sync mode or execute sync
                case "$current_mode" in
                    "view")
                        current_mode="sync"
                        ;;
                    "sync")
                        # In sync mode, 4 doesn't do anything
                        ;;
                esac
                ;;
            
            's'|'S')  # Save
                case "$current_mode" in
                    "edit_user")
                        save_changes "user"
                        current_mode="view"
                        load_all_agents
                        ;;
                    "edit_project")
                        save_changes "project"
                        current_mode="view"
                        load_all_agents
                        ;;
                esac
                ;;
            
            'd'|'D')  # Delete current
                if [[ "$current_mode" == "edit_"* ]]; then
                    selected[$current_index]=false
                fi
                ;;
            
            'q'|'Q')  # Quit
                if [[ "$current_mode" == "view" ]]; then
                    clear_screen
                    echo -e "${CYAN}¡Hasta luego!${NC}"
                    exit 0
                fi
                ;;
        esac
    done
}

# Run
main "$@"