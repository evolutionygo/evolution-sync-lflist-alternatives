#!/bin/bash

# Variables para los repositorios y archivos
LFLIST_FILE="lflist.conf"  # Archivo original lflist.conf
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

# Paso 3: Ordenar los ítems y verificar el ítem más reciente
echo "Verificando el ítem más reciente y dando prioridad a 'TCG'..."

SORTED_ITEMS=$(echo "$INITIAL_LISTS" | sort -r -t '.' -k1,1n -k2,2n -k3,3n)

# Dar prioridad a 'TCG'
SORTED_ITEMS=$(echo "$SORTED_ITEMS" | while IFS= read -r line; do
    if [[ $line == *"TCG"* ]]; then
        echo "$line 1"
    else
        echo "$line 0"
    fi
done | sort -k2,2nr -k1,1)

# Obtener el ítem más reciente
MOST_RECENT_ITEM=$(echo "$SORTED_ITEMS" | awk '{$NF=""; print $0}' | sed 's/[[:space:]]*$//' | head -n 1)
echo "El ítem más reciente es: $MOST_RECENT_ITEM"

# Paso 4: Añadir el ítem más reciente en la línea 1 del nuevo archivo lflist.conf
echo "Añadiendo el ítem más reciente en la línea 1 del nuevo archivo lflist.conf..."
sed -i "1s|^|#[$MOST_RECENT_ITEM] |" "$NEW_LFLIST_FILE"

# Paso 5: Añadir la lista correspondiente al ítem más reciente en el nuevo archivo
echo "Añadiendo la lista correspondiente del ítem más reciente..."
grep "^!$MOST_RECENT_ITEM" "$LFLIST_FILE" >> "$NEW_LFLIST_FILE"

# Mostrar el contenido del nuevo archivo para ver los cambios
echo "Contenido del nuevo archivo lflist.conf:"
cat "$NEW_LFLIST_FILE"

# Fin del proceso sin realizar el push al repositorio
echo "Proceso completado sin realizar cambios en el repositorio."





















