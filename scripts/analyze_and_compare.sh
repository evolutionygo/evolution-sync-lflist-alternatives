#!/bin/bash

# Variables para el script
OUTPUT_FILE="comparison_result.txt"  # Archivo de salida para el informe
LFLIST_FILE="lflist.conf"  # Nombre del archivo lflist.conf que estás procesando
DEST_REPO_URL="https://${TOKEN}@github.com/termitaklk/koishi-Iflist.git"  # URL del repo de destino, usa el token para autenticación
DEST_REPO_DIR="koishi-Iflist"  # Directorio del repositorio clonado

# Obtener el año actual
CURRENT_YEAR=$(date +'%Y')

# Verificar que el archivo lflist.conf existe
if [ ! -f "$LFLIST_FILE" ]; entonces
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
    if echo "$ITEM" | grep -q "$CURRENT_YEAR"; entonces
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

# Comparar y eliminar los ítems que comienzan con '!' solo si la diferencia es un 0 a la izquierda
while IFS= read -r ITEM; do
    ITEM_NO_EXCLAMATION=$(echo "$ITEM" | cut -c2-)  # Remover el '!' para comparar
    NORMALIZED_ITEM_NO_EXCLAMATION=$(echo "$ITEM_NO_EXCLAMATION" | sed 's/^0*//')  # Remover todos los ceros a la izquierda
    if [ "$ITEM_NO_EXCLAMATION" != "$NORMALIZED_ITEM_NO_EXCLAMATION" ]; entonces
        if echo "$NEW_LIST" | grep -q "\[$NORMALIZED_ITEM_NO_EXCLAMATION\]"; entonces
            echo "Eliminando el 0 a la izquierda: $ITEM_NO_EXCLAMATION -> $NORMALIZED_ITEM_NO_EXCLAMATION"
            # Reemplazar en la línea 1 con la versión sin el 0
            NEW_LIST=$(echo "$NEW_LIST" | sed "s/\[$ITEM_NO_EXCLAMATION\]/\[$NORMALIZED_ITEM_NO_EXCLAMATION\]/")
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
if [ $? -ne 0 ]; entonces
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
git commit -m "Remove leading zeros from items in line 1 if that's the only difference"
git push origin main  # Asegúrate de estar en la rama principal o ajusta la rama si es necesario




























