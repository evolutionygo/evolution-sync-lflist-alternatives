#!/bin/bash

# Variables para los repositorios y archivos
LFLIST_FILE="lflist.conf"  # Archivo lflist.conf que vamos a trabajar
NEW_LFLIST_FILE="new_lflist.conf"  # Nuevo archivo lflist.conf donde haremos los cambios
CONF_REPO_URL="https://github.com/termitaklk/lflist"  # Repositorio con los archivos .conf
LFLIST_REPO_URL="https://github.com/fallenstardust/YGOMobile-cn-ko-en"  # Repositorio con el archivo lflist.conf
CONF_DIR="comparison-repo"  # Directorio donde se clonará el repositorio de archivos .conf
CURRENT_YEAR=$(date +'%Y')  # Año en curso
PREVIOUS_YEAR=$((CURRENT_YEAR - 1))  # Año anterior

# Paso 1: Clonar los repositorios
echo "Clonando los repositorios..."
if [ -d "$CONF_DIR" ]; then
    rm -rf "$CONF_DIR"
fi
git clone "$CONF_REPO_URL" "$CONF_DIR"

if [ -f "$LFLIST_FILE" ]; then
    rm -f "$LFLIST_FILE"
fi
git clone "$LFLIST_REPO_URL" repo-koishi
cp repo-koishi/mobile/assets/data/conf/lflist.conf "$LFLIST_FILE"

# Crear el nuevo archivo lflist.conf para modificaciones
cp "$LFLIST_FILE" "$NEW_LFLIST_FILE"

# Paso 2: Verificación inicial e impresión de la lista
echo "Contenido de la lista inicial (extraída del archivo original):"
INITIAL_LISTS=$(sed -n '1p' "$LFLIST_FILE" | grep -oP '\[[^\]]+\]')
echo "$INITIAL_LISTS"

# Filtrar solo los ítems del año en curso
echo "Filtrando solo los ítems del año $CURRENT_YEAR..."
CURRENT_YEAR_ITEMS=$(echo "$INITIAL_LISTS" | grep "$CURRENT_YEAR")
COUNT_CURRENT_YEAR_ITEMS=$(echo "$CURRENT_YEAR_ITEMS" | wc -l)

# Si hay 2 o menos ítems del año en curso, añadir los del año anterior
if [ "$COUNT_CURRENT_YEAR_ITEMS" -le 2 ]; then
    echo "Se encontraron $COUNT_CURRENT_YEAR_ITEMS ítems del año en curso. Añadiendo ítems del año anterior ($PREVIOUS_YEAR)..."
    PREVIOUS_YEAR_ITEMS=$(echo "$INITIAL_LISTS" | grep "$PREVIOUS_YEAR")
    CURRENT_YEAR_ITEMS="$CURRENT_YEAR_ITEMS"$'\n'"$PREVIOUS_YEAR_ITEMS"
fi

# Imprimir los ítems del año en curso y (si es necesario) los del año anterior
echo "Ítems del año en curso (y del año anterior si aplica):"
echo "$CURRENT_YEAR_ITEMS"

# Paso 3: Verificar los ítems más recientes y dar prioridad a "TCG"
echo "Verificando el ítem más reciente y dando prioridad a 'TCG'..."

# Organizar los ítems numéricamente por año.mes.día de forma descendente, manteniendo los nombres completos
SORTED_ITEMS=$(echo "$CURRENT_YEAR_ITEMS" | grep -oP '\[[^\]]+\]' | sort -r -t '.' -k1,1n -k2,2n -k3,3n)

# Si dos ítems tienen el mismo año y mes, dar prioridad al que contiene "TCG"
SORTED_ITEMS=$(echo "$SORTED_ITEMS" | awk '{if (match($0, /TCG/)) print $0, 1; else print $0, 0}' | sort -k2,2nr -k1,1)

# Imprimir los ítems ordenados correctamente, eliminando saltos de línea adicionales y preservando los corchetes
echo "Ítems organizados desde el más reciente al más viejo (prioridad a 'TCG'):"
echo "$SORTED_ITEMS"

# Ordenar los ítems de más reciente a más viejo
SORTED_ITEMS=$(echo "$SORTED_ITEMS" | sort -r -k2,2nr -k1,1)

# Obtener el ítem más reciente
MOST_RECENT_ITEM=$(echo "$SORTED_ITEMS" | awk '{$NF=""; print $0}' | sed 's/[[:space:]]*$//' | head -n 1)
echo "El ítem más reciente es: $MOST_RECENT_ITEM"

# Paso 6: Añadir la lista correspondiente al ítem más reciente en el nuevo archivo
echo "Añadiendo la lista correspondiente del ítem más reciente..."

# Buscar la lista que corresponde al ítem más reciente
LIST_ITEM=$(grep "^!$MOST_RECENT_ITEM" "$LFLIST_FILE")

# Verificar si se encontró una lista
if [ -z "$LIST_ITEM" ]; then
    echo "No se encontró una lista para el ítem más reciente: $MOST_RECENT_ITEM"
else
    echo "Lista encontrada: $LIST_ITEM"
    echo "$LIST_ITEM" >> "$NEW_LFLIST_FILE"
fi



















