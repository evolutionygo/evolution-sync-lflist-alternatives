#!/bin/bash

# Variables para el script
OUTPUT_FILE="comparison_result.txt"
LFLIST_FILE="lflist.conf"
DEST_REPO_URL="https://${TOKEN}@github.com/termitaklk/koishi-Iflist.git"
DEST_REPO_DIR="koishi-Iflist"

# Verificar que el archivo lflist.conf existe
if [ ! -f "$LFLIST_FILE" ]; then
    echo "Error: No se encontró el archivo $LFLIST_FILE"
    exit 1
fi

# Extraer la primera línea del archivo que contiene las listas
INITIAL_LISTS=$(sed -n '1p' "$LFLIST_FILE" | grep -oP '\[\K[^\]]+')

# Crear una lista temporal para almacenar las fechas y sus correspondientes nombres
declare -A ITEM_DATE_MAP

for ITEM in $INITIAL_LISTS; do
    # Extraer la fecha usando grep (busca un patrón de fecha en el nombre, e.g., 2024.09, 2024.9 TCG)
    DATE=$(echo "$ITEM" | grep -oP '\b\d{4}\.\d{1,2}\b')
    if [ -n "$DATE" ]; then
        ITEM_DATE_MAP["$ITEM"]=$DATE
    else
        echo "No se encontró una fecha en $ITEM, omitiendo..."
    fi
done

# Ordenar los ítems por fecha (invertido para obtener los más recientes primero)
SORTED_ITEMS=$(for ITEM in "${!ITEM_DATE_MAP[@]}"; do
    echo "${ITEM_DATE_MAP[$ITEM]} $ITEM"
done | sort -r | awk '{print $2}')

# Crear una nueva lista para la línea 1 con los ítems más recientes
NEW_LIST="#"
for ITEM in $SORTED_ITEMS; do
    NEW_LIST="${NEW_LIST}[$ITEM]"
done

# Actualizar la línea 1 en el archivo con los ítems más recientes
sed -i "1s|.*|${NEW_LIST}|" "$LFLIST_FILE"

# Eliminar todas las listas desplegadas que no correspondan a los ítems más recientes
for ITEM in $(grep -oP '^!\K[^\s]+' "$LFLIST_FILE"); do
    if ! echo "$SORTED_ITEMS" | grep -q "$ITEM"; then
        echo "Eliminando contenido de la lista $ITEM del archivo lflist.conf"
        sed -i "/^!$ITEM/,/^$/d" "$LFLIST_FILE"
    fi
done

# Verificar el contenido de la lista inicial después de la modificación
echo "Lista inicial en lflist.conf después de la modificación:"
sed -n '1p' "$LFLIST_FILE"

# Verificar el contenido añadido al final del archivo
echo "Contenido final en lflist.conf:"
tail -n 20 "$LFLIST_FILE"  # Mostrar las últimas 20 líneas para verificar el contenido

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
git commit -m "Keep all recent lists"
git push origin main

















