#!/bin/bash

# Variables para el script
LFLIST_FILE="lflist.conf"  # Nombre del archivo lflist.conf que estás procesando
DEST_REPO_URL="https://${TOKEN}@github.com/termitaklk/koishi-Iflist.git"  # URL del repo de destino, usa el token para autenticación
DEST_REPO_DIR="koishi-Iflist"  # Directorio del repositorio clonado
COMPARISON_REPO_URL="https://github.com/termitaklk/lflist"  # URL del repositorio con archivos .conf

# Obtener el año actual
CURRENT_YEAR=$(date +'%Y')

# Verificar que el archivo lflist.conf existe
if [ ! -f "$LFLIST_FILE" ]; then
    echo "Error: No se encontró el archivo $LFLIST_FILE"
    exit 1
fi

# Eliminar el directorio comparison-repo si ya existe
if [ -d "comparison-repo" ]; then
    rm -rf comparison-repo
fi

# Clonar el repositorio de comparación
git clone "$COMPARISON_REPO_URL" comparison-repo
if [ $? -ne 0 ]; then
    echo "Error: No se pudo clonar el repositorio de comparación."
    exit 1
fi

# Extraer la primera línea del archivo que contiene las listas y guardar en INITIAL_LISTS
INITIAL_LISTS=$(sed -n '1p' "$LFLIST_FILE" | grep -oP '\[[^\]]+\]')

# Filtrar y mantener solo los ítems que contienen el año actual
NEW_LIST="#"
MATCHED_ITEMS=""
while IFS= read -r ITEM; do
    if echo "$ITEM" | grep -q "$CURRENT_YEAR"; then
        NEW_LIST="${NEW_LIST}${ITEM}"
        MATCHED_ITEMS="${MATCHED_ITEMS}${ITEM} "
    fi
done <<< "$INITIAL_LISTS"

# Mostrar todos los ítems que comienzan con '!'
ITEMS_WITH_EXCLAMATION=$(grep '^!' "$LFLIST_FILE")

# Filtrar y mantener solo los ítems que corresponden al año actual
while IFS= read -r ITEM; do
    ITEM_NO_EXCLAMATION=$(echo "$ITEM" | cut -c2-)  # Remover el '!' para obtener el nombre del ítem
    if echo "$ITEM_NO_EXCLAMATION" | grep -q "$CURRENT_YEAR"; then
        echo "Manteniendo $ITEM"
    else
        sed -i "/^$ITEM/,/^$/d" "$LFLIST_FILE"
    fi
done <<< "$ITEMS_WITH_EXCLAMATION"

# Recopilar y organizar alfabéticamente los ítems de los archivos .conf
ADDITIONAL_ITEMS=""
for conf_file in comparison-repo/*.conf; do
    if [ -f "$conf_file" ]; then
        ITEM=$(grep -oP '^!\K.*' "$conf_file")
        
        if [ -z "$ITEM" ]; then
            continue
        fi

        if echo "$ITEM" | grep -q "KS"; then
            continue
        fi

        if ! echo "$ITEMS_WITH_EXCLAMATION" | grep -q "$ITEM"; then
            cat "$conf_file" >> "$LFLIST_FILE"
            echo "" >> "$LFLIST_FILE"
            ADDITIONAL_ITEMS="${ADDITIONAL_ITEMS} [${ITEM}]"
        fi
    fi
done

# Organizar alfabéticamente los ítems adicionales
SORTED_ADDITIONAL_ITEMS=$(echo "$ADDITIONAL_ITEMS" | tr ' ' '\n' | sort | tr '\n' ' ')

# Añadir los ítems organizados alfabéticamente al principio de la lista
NEW_LIST="${NEW_LIST}${SORTED_ADDITIONAL_ITEMS}"

# Ordenar los ítems en la lista inicial (línea 1) y en el archivo lflist.conf
SORTED_LIST=$(echo "$NEW_LIST" | grep 'TCG' | sort -V)
SORTED_LIST+=$(echo "$NEW_LIST" | grep -v 'TCG' | sort -V)

# Añadir prefijos numéricos al nombre dentro de los corchetes en la misma línea
SORTED_LIST_WITH_PREFIX="#"
COUNTER=0
while IFS= read -r ITEM; do
    ITEM_NAME=$(echo "$ITEM" | grep -oP '\[\K[^\]]+')
    SORTED_LIST_WITH_PREFIX="${SORTED_LIST_WITH_PREFIX} [${COUNTER}.${ITEM_NAME}]"
    COUNTER=$((COUNTER + 1))
done <<< "$SORTED_LIST"

# Reemplazar la línea 1 con la lista ordenada y numerada
sed -i "1s|.*|${SORTED_LIST_WITH_PREFIX}|" "$LFLIST_FILE"

# Mostrar el contenido final del archivo lflist.conf
cat "$LFLIST_FILE"

# Clonar el repositorio de destino
git clone "$DEST_REPO_URL" "$DEST_REPO_DIR"
if [ $? -ne 0 ]; then
    echo "Error: No se pudo clonar el repositorio de destino."
    exit 1
fi

# Mover el archivo modificado al repositorio clonado
mv "$LFLIST_FILE" "$DEST_REPO_DIR/"
cd "$DEST_REPO_DIR"

# Configurar Git
git config user.name "GitHub Action"
git config user.email "action@github.com"

# Añadir, hacer commit y push
git add "$LFLIST_FILE"
git commit -m "Sorted items numerically and alphabetically, prioritized TCG items, and added numerical prefixes in the same line"
git push origin main













