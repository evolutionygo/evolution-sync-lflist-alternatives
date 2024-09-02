#!/bin/bash

# Variables para el script
LFLIST_FILE="lflist.conf"
CURRENT_YEAR=$(date +'%Y')

# Verificar que el archivo lflist.conf existe
if [ ! -f "$LFLIST_FILE" ]; then
    echo "Error: No se encontró el archivo $LFLIST_FILE"
    exit 1
fi

# Extraer la primera línea del archivo que contiene las listas
INITIAL_LISTS=$(sed -n '1p' "$LFLIST_FILE" | grep -oP '\[\K[^\]]+\]')

# Filtrar y mantener solo los ítems que contienen el año actual
NEW_LIST="#"
for ITEM in $INITIAL_LISTS; do
    FULL_ITEM=$(echo "$ITEM" | tr -d ']')  # Remover el corchete final para buscar el año
    if echo "$FULL_ITEM" | grep -q "$CURRENT_YEAR"; then
        NEW_LIST="${NEW_LIST}[${FULL_ITEM}]"
    fi
done

# Actualizar la línea 1 en el archivo para mantener solo los ítems con el año actual
sed -i "1s|.*|${NEW_LIST}|" "$LFLIST_FILE"

# Eliminar todas las listas desplegadas que no correspondan a los ítems con el año actual
for ITEM in $(grep -oP '^!\K[^\s]+' "$LFLIST_FILE"); do
    if ! echo "$NEW_LIST" | grep -q "$ITEM"; then
        echo "Eliminando contenido de la lista $ITEM del archivo lflist.conf"
        sed -i "/^!$ITEM/,/^$/d" "$LFLIST_FILE"
    fi
done

# Verificar el contenido de la lista inicial después de la modificación
echo "Lista inicial en lflist.conf después de la modificación:"
sed -n '1p' "$LFLIST_FILE"

# Verificar el contenido añadido al final del archivo
echo "Contenido final en lflist.conf:"
tail -n 20 "$LFLIST_FILE"  # Mostrar las últimas 20 líneas para verificar el contenido añadido




















