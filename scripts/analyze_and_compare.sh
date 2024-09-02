#!/bin/bash

# Variables para el script
OUTPUT_FILE="comparison_result.txt"  # Archivo de salida para el informe
LFLIST_FILE="lflist.conf"  # Nombre del archivo lflist.conf que estás procesando
DEST_REPO_URL="https://${TOKEN}@github.com/termitaklk/koishi-Iflist.git"  # URL del repo de destino, usa el token para autenticación
DEST_REPO_DIR="koishi-Iflist"  # Directorio del repositorio clonado

# Obtener el año actual
CURRENT_YEAR=$(date +'%Y')

# Verificar que el archivo lflist.conf existe
if [ ! -f "$LFLIST_FILE" ]; then
    echo "Error: No se encontró el archivo $LFLIST_FILE"
    exit 1
fi

# Extraer la primera línea del archivo que contiene las listas
INITIAL_LISTS=$(sed -n '1p' "$LFLIST_FILE" | grep -oP '\[[^\]]+\]')

echo "Guardado ITEM: $INITIAL_LISTS"  # Log para mostrar el ítem que se guarda

# Filtrar y mantener solo los ítems que contienen el año actual
NEW_LIST="#"
MATCHED_ITEMS=""
for ITEM in $INITIAL_LISTS; do
    echo "Recibido ITEM: $ITEM"  # Log para mostrar el ítem que se recibe
    if echo "$ITEM" | grep -q "$CURRENT_YEAR"; then
        NEW_LIST="${NEW_LIST}${ITEM}"
        MATCHED_ITEMS="${MATCHED_ITEMS}${ITEM} "
        echo "Guardado ITEM: $ITEM"  # Log para mostrar el ítem que se guarda
    fi
done

# Mostrar los ítems que cumplen con el año actual
echo "Ítems que cumplen con el año $CURRENT_YEAR: $MATCHED_ITEMS"

# Actualizar la línea 1 en el archivo para mantener solo los ítems con el año actual
sed -i "1s|.*|${NEW_LIST}|" "$LFLIST_FILE"

# Eliminar todas las listas desplegadas que no correspondan a los ítems con el año actual
for ITEM in $(grep -oP '^!\K[^\s]+' "$LFLIST_FILE"); do
    if ! echo "$NEW_LIST" | grep -q "$ITEM"; then
        echo "Eliminando contenido de la lista $ITEM del archivo lflist.conf"
        sed -i "/^!$ITEM/,/^$/d" "$LFLIST_FILE"
    fi
done

# Mostrar el contenido final del archivo lflist.conf
echo "Contenido final del archivo lflist.conf después de las modificaciones:"
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
git commit -m "Keep only items with the current year"
git push origin main  # Asegúrate de estar en la rama principal o ajusta la rama si es necesario






















