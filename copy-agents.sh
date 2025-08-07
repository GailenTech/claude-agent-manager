#!/bin/bash

# Script para copiar selectivamente agentes a un directorio destino
# con preview de cambios antes de copiar

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directorio base de agentes
AGENTS_DIR="$(cd "$(dirname "$0")/agents-collection" && pwd)"

# Arrays para almacenar selecciones
declare -a selected_agents=()
declare -a agent_files=()
declare -a agent_names=()

echo -e "${BLUE}=== Selector de Agentes Single-SPA ===${NC}\n"

# Encontrar todos los agentes
echo "Buscando agentes disponibles..."
while IFS= read -r -d '' file; do
    agent_files+=("$file")
    # Extraer el nombre del agente del archivo
    name=$(grep "^name:" "$file" | sed 's/name: //')
    agent_names+=("$name")
done < <(find "$AGENTS_DIR" -name "*.md" -print0 | sort -z)

# Mostrar menú de selección
echo -e "\n${GREEN}Agentes disponibles:${NC}"
for i in "${!agent_files[@]}"; do
    rel_path="${agent_files[$i]#$AGENTS_DIR/}"
    echo "  $((i+1))) ${agent_names[$i]} (${rel_path})"
done

echo -e "\n${YELLOW}Instrucciones:${NC}"
echo "- Ingresa los números de los agentes que quieres copiar, separados por espacios"
echo "- Ejemplo: 1 3 5"
echo "- Ingresa 'all' para seleccionar todos"
echo "- Ingresa 'q' para salir"

# Leer selección
echo -e "\n${BLUE}Tu selección:${NC} "
read -r selection

# Procesar selección
if [[ "$selection" == "q" ]]; then
    echo "Saliendo..."
    exit 0
elif [[ "$selection" == "all" ]]; then
    selected_agents=("${!agent_files[@]}")
else
    IFS=' ' read -ra selections <<< "$selection"
    for sel in "${selections[@]}"; do
        if [[ "$sel" =~ ^[0-9]+$ ]] && (( sel > 0 && sel <= ${#agent_files[@]} )); then
            selected_agents+=($((sel-1)))
        else
            echo -e "${RED}Selección inválida: $sel${NC}"
        fi
    done
fi

if [[ ${#selected_agents[@]} -eq 0 ]]; then
    echo -e "${RED}No se seleccionaron agentes.${NC}"
    exit 1
fi

# Mostrar agentes seleccionados
echo -e "\n${GREEN}Agentes seleccionados:${NC}"
for idx in "${selected_agents[@]}"; do
    echo "  - ${agent_names[$idx]}"
done

# Solicitar directorio destino
echo -e "\n${BLUE}Ingresa el directorio destino:${NC}"
echo "(Por ejemplo: /Users/tu-usuario/proyecto/.claude/agents)"
read -r dest_dir

# Expandir tilde si existe
dest_dir="${dest_dir/#\~/$HOME}"

# Verificar si el directorio existe
if [[ ! -d "$dest_dir" ]]; then
    echo -e "${YELLOW}El directorio no existe. ¿Crearlo? (s/n):${NC}"
    read -r create_dir
    if [[ "$create_dir" == "s" ]]; then
        mkdir -p "$dest_dir"
        echo -e "${GREEN}Directorio creado.${NC}"
    else
        echo -e "${RED}Operación cancelada.${NC}"
        exit 1
    fi
fi

# Verificar conflictos y mostrar diffs
echo -e "\n${BLUE}Verificando conflictos...${NC}"
conflicts=()
for idx in "${selected_agents[@]}"; do
    source_file="${agent_files[$idx]}"
    agent_name="${agent_names[$idx]}"
    dest_file="$dest_dir/${agent_name}.md"
    
    if [[ -f "$dest_file" ]]; then
        conflicts+=("$idx")
        echo -e "\n${YELLOW}CONFLICTO: ${agent_name}.md ya existe${NC}"
        echo -e "${BLUE}Mostrando diferencias:${NC}"
        
        # Mostrar diff con colores
        if command -v colordiff &> /dev/null; then
            colordiff -u "$dest_file" "$source_file" || true
        else
            diff -u "$dest_file" "$source_file" || true
        fi
        echo -e "${BLUE}---${NC}"
    fi
done

# Si hay conflictos, preguntar cómo proceder
if [[ ${#conflicts[@]} -gt 0 ]]; then
    echo -e "\n${YELLOW}Se encontraron ${#conflicts[@]} conflictos.${NC}"
    echo "¿Cómo proceder?"
    echo "  1) Sobrescribir todos los conflictos"
    echo "  2) Omitir archivos en conflicto"
    echo "  3) Revisar uno por uno"
    echo "  4) Cancelar operación"
    
    read -r conflict_action
    
    case $conflict_action in
        1) action="overwrite" ;;
        2) action="skip" ;;
        3) action="review" ;;
        4|*) 
            echo -e "${RED}Operación cancelada.${NC}"
            exit 1
            ;;
    esac
else
    action="copy"
fi

# Ejecutar copia según la acción elegida
echo -e "\n${BLUE}Copiando agentes...${NC}"
copied=0
skipped=0

for idx in "${selected_agents[@]}"; do
    source_file="${agent_files[$idx]}"
    agent_name="${agent_names[$idx]}"
    dest_file="$dest_dir/${agent_name}.md"
    
    # Verificar si es un conflicto
    is_conflict=false
    for conf_idx in "${conflicts[@]}"; do
        if [[ "$idx" == "$conf_idx" ]]; then
            is_conflict=true
            break
        fi
    done
    
    # Decidir si copiar
    should_copy=true
    
    if [[ "$is_conflict" == true ]]; then
        case $action in
            "skip")
                should_copy=false
                echo -e "${YELLOW}Omitido: ${agent_name}.md${NC}"
                ((skipped++))
                ;;
            "review")
                echo -e "\n${YELLOW}¿Sobrescribir ${agent_name}.md? (s/n):${NC}"
                read -r overwrite
                if [[ "$overwrite" != "s" ]]; then
                    should_copy=false
                    echo -e "${YELLOW}Omitido: ${agent_name}.md${NC}"
                    ((skipped++))
                fi
                ;;
        esac
    fi
    
    # Copiar si se debe
    if [[ "$should_copy" == true ]]; then
        cp "$source_file" "$dest_file"
        echo -e "${GREEN}Copiado: ${agent_name}.md${NC}"
        ((copied++))
    fi
done

# Resumen
echo -e "\n${BLUE}=== Resumen ===${NC}"
echo -e "${GREEN}Archivos copiados: $copied${NC}"
if [[ $skipped -gt 0 ]]; then
    echo -e "${YELLOW}Archivos omitidos: $skipped${NC}"
fi
echo -e "\nDestino: $dest_dir"