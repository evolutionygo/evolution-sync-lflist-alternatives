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

# Extraer la primera línea del archivo que contiene las listas y guardar en INITIAL_LISTS
INITIAL_LISTS=$(sed -n '1p' "$LFLIST_FILE" | grep -oP '\[[^\]]+\]')

# Mostrar el contenido almacenado en INITIAL_LISTS
echo "Contenido de INITIAL_LISTS: $INITIAL_LISTS"

# Filtrar y mantener solo los ítems que contienen el año actual
NEW_LIST="#"
MATCHED_ITEMS=""
while IFS= read -r ITEM; do
    echo "Recibido ITEM: $ITEM"  # Log para mostrar el ítem que se recibe
    if echo "$ITEM" | grep -q "$CURRENT_YEAR"; then
        NEW_LIST="${NEW_LIST}${ITEM}"
        MATCHED_ITEMS="${MATCHED_ITEMS}${ITEM} "
        echo "Guardado ITEM: $ITEM"  # Log para mostrar el ítem que se guarda
    fi
done <<< "$INITIAL_LISTS"

# Mostrar los ítems que cumplen con el año actual
echo "Ítems que cumplen con el año $CURRENT_YEAR: $MATCHED_ITEMS"

# Mostrar todos los ítems que comienzan con '!'
echo "Ítems que comienzan con '!':"
ITEMS_WITH_EXCLAMATION=$(grep '^!' "$LFLIST_FILE")
echo "$ITEMS_WITH_EXCLAMATION"

# Comparar y eliminar los ítems que comienzan con '!' pero no coinciden con la lista filtrada
while IFS= read -r ITEM; do
    ITEM_NO_EXCLAMATION=$(echo "$ITEM" | cut -c2-)  # Remover el '!' para comparar
    NORMALIZED_ITEM=$(echo "$ITEM_NO_EXCLAMATION" | sed 's/0\([1-9]\)/\1/')  # Remover el cero a la izquierda
    if ! echo "$NEW_LIST" | grep -q "\[$ITEM_NO_EXCLAMATION\]"; then
        if echo "$NEW_LIST" | grep -q "\[$NORMALIZED_ITEM\]"; then
            # Si el ítem normalizado coincide, reemplazamos en la línea 1 con la versión con el 0
            echo "Ajustando $NORMALIZED_ITEM a $ITEM_NO_EXCLAMATION en la línea 1"
            NEW_LIST=$(echo "$NEW_LIST" | sed "s/\[$NORMALIZED_ITEM\]/\[$ITEM_NO_EXCLAMATION\]/")
        else
            # Si no coincide, eliminamos el ítem de la lista y el archivo
            echo "Eliminando contenido de la lista $ITEM del archivo lflist.conf"
            sed -i "/^$ITEM/,/^$/d" "$LFLIST_FILE"
            NEW_LIST=$(echo "$NEW_LIST" | sed "s/\[$ITEM_NO_EXCLAMATION\]//g")
        fi
    fi
done <<< "$ITEMS_WITH_EXCLAMATION"

# Actualizar la línea 1 en el archivo para mantener solo los ítems que aún son válidos
sed -i "1s|.*|${NEW_LIST}|" "$LFLIST_FILE"

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
git commit -m "Adjust items to match those with leading zeros in line 1"
git push origin main  # Asegúrate de estar en la rama principal o ajusta la rama si es necesario



























