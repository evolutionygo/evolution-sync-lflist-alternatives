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

# Ordenar los ítems por fecha y tomar los 4 más recientes
TOP_4_ITEMS=$(echo "$INITIAL_LISTS" | sort -r | head -n 4)

# Crear una nueva lista para la línea 1 con los 4 ítems más recientes
NEW_LIST="#"
for ITEM in $TOP_4_ITEMS; do
    NEW_LIST="${NEW_LIST}[$ITEM]"
done

# Actualizar la línea 1 en el archivo con los 4 ítems más recientes
sed -i "1s|.*|${NEW_LIST}|" "$LFLIST_FILE"

# Eliminar todas las listas desplegadas que no correspondan a los 4 ítems más recientes
for ITEM in $(grep -oP '^!\K[^\s]+' "$LFLIST_FILE"); do
    if ! echo "$TOP_4_ITEMS" | grep -q "$ITEM"; then
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
git commit -m "Keep only the 4 most recent lists"
git push origin main















