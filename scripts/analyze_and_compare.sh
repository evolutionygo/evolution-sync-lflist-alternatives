#!/bin/bash

# Variables para el script
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

# Mostrar todos los ítems que comienzan con '!'
echo "Ítems que comienzan con '!':"
ITEMS_WITH_EXCLAMATION=$(grep '^!' "$LFLIST_FILE")
echo "$ITEMS_WITH_EXCLAMATION"

# Filtrar y mantener solo los ítems que corresponden al año actual
while IFS= read -r ITEM; do
    ITEM_NO_EXCLAMATION=$(echo "$ITEM" | cut -c2-)  # Remover el '!' para obtener el nombre del ítem
    if echo "$ITEM_NO_EXCLAMATION" | grep -q "$CURRENT_YEAR"; entonces
        echo "Manteniendo $ITEM"  # Log para mostrar los ítems que se mantienen
    else
        echo "Eliminando $ITEM del archivo lflist.conf"
        sed -i "/^$ITEM/,/^$/d" "$LFLIST_FILE"
    fi
done <<< "$ITEMS_WITH_EXCLAMATION"

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
git commit -m "Keep only items that match the current year"
git push origin main  # Asegúrate de estar en la rama principal o ajusta la rama si es necesario





























