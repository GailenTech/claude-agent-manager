#!/bin/bash

# Script interactivo para copiar agentes con interfaz mejorada
set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Caracteres especiales
CHECK="✓"
UNCHECK=" "
ARROW="▶"

# Directorio base
AGENTS_DIR="$(cd "$(dirname "$0")/agents-collection" && pwd)"

# Arrays globales
declare -a agent_files=()
declare -a agent_names=()
declare -a agent_descriptions=()
declare -a agent_categories=()
declare -a selected=()
current_index=0
dest_dir=""

# Limpiar pantalla y mover cursor
clear_screen() { printf "\033[2J\033[H"; }
move_cursor() { printf "\033[%d;%dH" "$1" "$2"; }
save_cursor() { printf "\033[s"; }
restore_cursor() { printf "\033[u"; }
clear_line() { printf "\033[K"; }
clear_to_bottom() { printf "\033[J"; }

# Cargar agentes
load_agents() {
    echo "Cargando agentes..."
    while IFS= read -r -d '' file; do
        agent_files+=("$file")
        
        # Extraer metadatos
        name=$(grep "^name:" "$file" | sed 's/name: //')
        desc=$(grep "^description:" "$file" | sed 's/description: //')
        
        # Categoría del path
        category=$(dirname "${file#$AGENTS_DIR/}")
        
        agent_names+=("$name")
        agent_descriptions+=("$desc")
        agent_categories+=("$category")
        selected+=(false)
    done < <(find "$AGENTS_DIR" -name "*.md" -print0 | sort -z)
}

# Mostrar descripción del agente actual
show_agent_details() {
    local idx=$1
    local file="${agent_files[$idx]}"
    
    # Limpiar área de detalles
    for ((i=5; i<=16; i++)); do
        move_cursor $i 61
        printf "%-40s" " "
    done
    
    move_cursor 5 61
    echo -e "${BOLD}${CYAN}Detalles del Agente${NC}"
    
    move_cursor 7 61
    printf "${BOLD}%-10s${NC} %s" "Nombre:" "${agent_names[$idx]:0:30}"
    
    move_cursor 8 61
    printf "${BOLD}%-10s${NC} %s" "Categoría:" "${agent_categories[$idx]}"
    
    move_cursor 10 61
    echo -e "${BOLD}Descripción:${NC}"
    
    # Mostrar descripción con wrap
    local desc="${agent_descriptions[$idx]}"
    local width=38
    local line=11
    
    # Dividir descripción en líneas
    while [[ ${#desc} -gt 0 ]] && [[ $line -lt 16 ]]; do
        move_cursor $line 61
        if [[ ${#desc} -le $width ]]; then
            printf "%-38s" "$desc"
            break
        else
            # Buscar espacio para cortar
            local cut_at=$width
            while [[ $cut_at -gt 0 ]] && [[ "${desc:$cut_at:1}" != " " ]]; do
                ((cut_at--))
            done
            if [[ $cut_at -eq 0 ]]; then cut_at=$width; fi
            
            printf "%-38s" "${desc:0:$cut_at}"
            desc="${desc:$((cut_at+1))}"
            ((line++))
        fi
    done
}

# Mostrar lista de agentes
show_agent_list() {
    clear_screen
    
    # Header
    echo -e "${BOLD}${BLUE}╔════════════════════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║                                   Selector de Agentes Single-SPA                                   ║${NC}"
    echo -e "${BOLD}${BLUE}╚════════════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
    
    # Línea divisoria vertical
    for ((i=4; i<=17; i++)); do
        move_cursor $i 58
        echo -e "${DIM}│${NC}"
    done
    
    # Línea horizontal divisoria
    move_cursor 18 1
    printf "${DIM}"
    for ((i=1; i<=100; i++)); do
        printf "─"
    done
    printf "${NC}\n"
    
    # Instrucciones
    move_cursor 19 1
    echo -e "${DIM}[↑/↓] Navegar  [ESPACIO] Seleccionar  [a] Todos  [n] Ninguno  [ENTER] Siguiente  [q] Salir${NC}"
    
    # Lista de agentes
    local start_line=5
    local visible_items=12
    local scroll_offset=0
    
    # Calcular scroll
    if [[ $current_index -ge $((scroll_offset + visible_items)) ]]; then
        scroll_offset=$((current_index - visible_items + 1))
    elif [[ $current_index -lt $scroll_offset ]]; then
        scroll_offset=$current_index
    fi
    
    # Mostrar agentes
    for ((i = 0; i < visible_items && i + scroll_offset < ${#agent_files[@]}; i++)); do
        local idx=$((i + scroll_offset))
        move_cursor $((start_line + i)) 2
        
        # Indicador de selección
        local marker=" "
        if [[ $idx -eq $current_index ]]; then
            marker="$ARROW"
            echo -ne "${BOLD}${GREEN}"
        fi
        
        # Checkbox
        local check="[$UNCHECK]"
        local check_color=""
        if [[ "${selected[$idx]}" == "true" ]]; then
            check="[$CHECK]"
            check_color="${GREEN}"
        fi
        
        # Mostrar línea
        echo -ne "$marker "
        echo -ne "${check_color}$check${NC} "
        printf "%-35s ${DIM}(%s)${NC}" "${agent_names[$idx]:0:35}" "${agent_categories[$idx]}"
        echo -ne "${NC}"
    done
    
    # Indicador de scroll
    if [[ ${#agent_files[@]} -gt $visible_items ]]; then
        move_cursor $((start_line + visible_items)) 2
        echo -e "${DIM}... $((${#agent_files[@]} - scroll_offset - visible_items)) más ...${NC}"
    fi
    
    # Mostrar detalles del agente actual
    show_agent_details $current_index
    
    # Mostrar seleccionados
    show_selected_summary
}

# Mostrar resumen de seleccionados
show_selected_summary() {
    # Limpiar área de resumen
    for ((i=21; i<=27; i++)); do
        move_cursor $i 1
        printf "%-100s" " "
    done
    
    move_cursor 21 1
    echo -e "${BOLD}${YELLOW}Seleccionados:${NC}"
    
    local count=0
    local column=0
    local row=0
    local max_rows=5
    local col_width=30
    local cols_per_line=3
    
    for i in "${!selected[@]}"; do
        if [[ "${selected[$i]}" == "true" ]]; then
            if [[ $row -lt $max_rows ]]; then
                local x=$((2 + column * col_width))
                local y=$((22 + row))
                move_cursor $y $x
                printf "${GREEN}• %-28s${NC}" "${agent_names[$i]:0:26}"
                
                ((column++))
                if [[ $column -ge $cols_per_line ]]; then
                    column=0
                    ((row++))
                fi
            fi
            ((count++))
        fi
    done
    
    if [[ $count -gt $((max_rows * cols_per_line)) ]]; then
        move_cursor 27 2
        echo -e "${DIM}... y $((count - max_rows * cols_per_line)) más${NC}"
    fi
    
    move_cursor 28 1
    echo -e "${BOLD}Total: $count agentes${NC}"
}

# Pantalla de confirmación
show_confirmation() {
    clear_screen
    
    echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║                         Confirmar Selección                                  ║${NC}"
    echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${BOLD}${GREEN}Agentes seleccionados:${NC}\n"
    
    local count=0
    for i in "${!selected[@]}"; do
        if [[ "${selected[$i]}" == "true" ]]; then
            ((count++))
            printf "  %2d. %-30s ${DIM}(%s)${NC}\n" \
                "$count" "${agent_names[$i]}" "${agent_categories[$i]}"
        fi
    done
    
    echo -e "\n${BOLD}Total: $count agentes${NC}"
    echo -e "\n${YELLOW}¿Continuar con la copia? ${NC}"
    echo -e "${DIM}[ENTER] Continuar  [b] Volver  [q] Cancelar${NC}"
}

# Solicitar directorio destino
get_destination() {
    while true; do
        clear_screen
        
        echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${BOLD}${BLUE}║                         Directorio Destino                                   ║${NC}"
        echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
        
        echo -e "\n${BOLD}Ingresa el directorio destino:${NC}"
        echo -e "${DIM}(Ejemplo: ~/proyecto/.claude/agents)${NC}\n"
        
        # Restaurar terminal para entrada de texto
        stty echo icanon
        
        read -e -p "> " dest_dir
        
        # Volver a configurar terminal para navegación
        stty -echo -icanon min 1 time 0
        
        if [[ -z "$dest_dir" ]]; then
            echo -e "\n${RED}Directorio no puede estar vacío${NC}"
            echo -e "\n${DIM}[ENTER] Reintentar  [b] Volver${NC}"
            IFS= read -r -n1 key
            if [[ "$key" == "b" || "$key" == "B" ]]; then
                return 1
            fi
            continue
        fi
        
        dest_dir="${dest_dir/#\~/$HOME}"
        
        if [[ ! -d "$dest_dir" ]]; then
            echo -e "\n${YELLOW}El directorio no existe: $dest_dir${NC}"
            echo -e "\n${BOLD}Opciones:${NC}"
            echo -e "  [c] Crear directorio"
            echo -e "  [r] Reintentar con otro path"
            echo -e "  [b] Volver a selección"
            
            IFS= read -r -n1 choice
            case "$choice" in
                'c'|'C')
                    mkdir -p "$dest_dir"
                    echo -e "\n${GREEN}Directorio creado exitosamente.${NC}"
                    sleep 1
                    return 0
                    ;;
                'r'|'R')
                    continue
                    ;;
                'b'|'B')
                    return 1
                    ;;
            esac
        else
            echo -e "\n${GREEN}Directorio válido: $dest_dir${NC}"
            echo -e "\n${DIM}[ENTER] Continuar  [b] Volver${NC}"
            IFS= read -r -n1 key
            if [[ "$key" == "b" || "$key" == "B" ]]; then
                return 1
            elif [[ "$key" == "" ]]; then
                return 0
            fi
        fi
    done
}

# Verificar conflictos
check_conflicts() {
    clear_screen
    
    echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║                         Verificando Conflictos                               ║${NC}"
    echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    
    local conflicts=()
    
    for i in "${!selected[@]}"; do
        if [[ "${selected[$i]}" == "true" ]]; then
            local dest_file="$dest_dir/${agent_names[$i]}.md"
            if [[ -f "$dest_file" ]]; then
                conflicts+=("$i")
            fi
        fi
    done
    
    if [[ ${#conflicts[@]} -eq 0 ]]; then
        echo -e "\n${GREEN}No hay conflictos. Procediendo con la copia...${NC}"
        sleep 1
        return 0
    fi
    
    echo -e "\n${YELLOW}Se encontraron ${#conflicts[@]} conflictos:${NC}\n"
    
    for idx in "${conflicts[@]}"; do
        echo -e "  ${RED}✗${NC} ${agent_names[$idx]}.md ya existe"
    done
    
    echo -e "\n${BOLD}Opciones:${NC}"
    echo -e "  [1] Ver diferencias"
    echo -e "  [2] Sobrescribir todos"
    echo -e "  [3] Omitir conflictos"
    echo -e "  [b] Volver a selección de directorio"
    echo -e "  [q] Cancelar todo"
    
    IFS= read -r -n1 choice
    
    case $choice in
        '1') 
            show_diffs "${conflicts[@]}"
            return $?
            ;;
        '2') return 0 ;;
        '3') 
            for idx in "${conflicts[@]}"; do
                selected[$idx]=false
            done
            return 0
            ;;
        'b'|'B') return 1 ;;
        'q'|'Q') return 2 ;;
        *) check_conflicts ;;
    esac
}

# Mostrar diffs
show_diffs() {
    local conflicts=("$@")
    
    for idx in "${conflicts[@]}"; do
        clear_screen
        echo -e "${BOLD}${YELLOW}Diferencias para: ${agent_names[$idx]}.md${NC}\n"
        
        local source="${agent_files[$idx]}"
        local dest="$dest_dir/${agent_names[$idx]}.md"
        
        if command -v colordiff &> /dev/null; then
            colordiff -u "$dest" "$source" | head -30 || true
        else
            diff -u "$dest" "$source" | head -30 || true
        fi
        
        echo -e "\n${DIM}[ENTER] Siguiente  [s] Sobrescribir  [o] Omitir  [b] Volver  [q] Cancelar${NC}"
        IFS= read -r -n1 choice
        
        case $choice in
            's'|'S') ;; # Mantener seleccionado
            'o'|'O') selected[$idx]=false ;;
            'b'|'B') return 1 ;;
            'q'|'Q') return 2 ;;
        esac
    done
    
    # Después de revisar todos los diffs, volver a mostrar opciones
    check_conflicts
}

# Copiar archivos
copy_files() {
    clear_screen
    
    echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║                           Copiando Archivos                                  ║${NC}"
    echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    
    echo ""
    
    local copied=0
    for i in "${!selected[@]}"; do
        if [[ "${selected[$i]}" == "true" ]]; then
            local source="${agent_files[$i]}"
            local dest="$dest_dir/${agent_names[$i]}.md"
            
            cp "$source" "$dest"
            echo -e "  ${GREEN}✓${NC} Copiado: ${agent_names[$i]}.md"
            ((copied++))
        fi
    done
    
    echo -e "\n${BOLD}${GREEN}Operación completada${NC}"
    echo -e "Archivos copiados: $copied"
    echo -e "Destino: $dest_dir"
    
    echo -e "\n${DIM}Presiona cualquier tecla para salir...${NC}"
    read -n 1 -s
}

# Main loop
main() {
    # Configurar terminal
    stty -echo -icanon min 1 time 0
    tput civis # Ocultar cursor
    trap 'stty sane; tput cnorm; clear_screen' EXIT
    
    load_agents
    
    while true; do
        show_agent_list
        
        # Leer input
        IFS= read -r -n1 key
        
        case "$key" in
            $'\x1b') # ESC sequence
                IFS= read -r -n2 rest
                case "$rest" in
                    '[A'|'OA') # Arriba
                        ((current_index--))
                        if [[ $current_index -lt 0 ]]; then
                            current_index=$((${#agent_files[@]} - 1))
                        fi
                        ;;
                    '[B'|'OB') # Abajo
                        ((current_index++))
                        if [[ $current_index -ge ${#agent_files[@]} ]]; then
                            current_index=0
                        fi
                        ;;
                esac
                ;;
            ' '|$' ') # Espacio - toggle selection
                if [[ "${selected[$current_index]}" == "true" ]]; then
                    selected[$current_index]=false
                else
                    selected[$current_index]=true
                fi
                ;;
            'a'|'A') # Seleccionar todos
                for i in "${!selected[@]}"; do
                    selected[$i]=true
                done
                ;;
            'n'|'N') # Deseleccionar todos
                for i in "${!selected[@]}"; do
                    selected[$i]=false
                done
                ;;
            'q'|'Q') # Salir
                exit 0
                ;;
            '') # Enter - siguiente paso
                # Verificar que hay selección
                local has_selection=false
                for s in "${selected[@]}"; do
                    if [[ "$s" == "true" ]]; then
                        has_selection=true
                        break
                    fi
                done
                
                if [[ "$has_selection" == "false" ]]; then
                    continue
                fi
                
                # Mostrar confirmación
                show_confirmation
                IFS= read -r -n1 confirm_key
                
                case $confirm_key in
                    'b'|'B') continue ;;
                    'q'|'Q') exit 0 ;;
                    '') # Enter
                        while true; do
                            if get_destination; then
                                local conflict_result
                                check_conflicts
                                conflict_result=$?
                                
                                if [[ $conflict_result -eq 0 ]]; then
                                    copy_files
                                    exit 0
                                elif [[ $conflict_result -eq 1 ]]; then
                                    # Volver a pedir directorio
                                    continue
                                elif [[ $conflict_result -eq 2 ]]; then
                                    # Cancelar todo
                                    exit 0
                                fi
                            else
                                # Volver a selección
                                break
                            fi
                        done
                        ;;
                esac
                ;;
        esac
    done
}

# Ejecutar
main