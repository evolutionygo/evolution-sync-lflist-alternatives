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
INITIAL_LISTS=$(sed -n '1p' "$LFLIST_FILE")

# Inicializar el archivo de salida
echo "Resultado de la comparación y adiciones:" > $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

# Variable para almacenar las nuevas listas sin el símbolo #
NEW_LISTS=""

# Iterar sobre todos los archivos .conf en el repositorio de comparación
for conf_file in comparison-repo/*.conf; do
    if [ -f "$conf_file" ]; then
        # Extraer la lista del archivo .conf actual que comienza con '!'
        ITEM=$(grep -oP '^!\K[^\s]+' "$conf_file")

        if [ -z "$ITEM" ]; then
            echo "No se encontró una lista válida en $conf_file" >> $OUTPUT_FILE
            continue
        fi

        # Verificar si el item ya está en la lista inicial
        if echo "$INITIAL_LISTS" | grep -q "\[$ITEM\]"; then
            echo "$ITEM de $conf_file ya se encuentra en la lista inicial" >> $OUTPUT_FILE
        else
            echo "$ITEM de $conf_file NO se encuentra en la lista inicial. Añadiendo..." >> $OUTPUT_FILE
            NEW_LISTS="${NEW_LISTS}[$ITEM]"
        fi
    fi
done

# Añadir las nuevas listas al final de la línea inicial
if [ ! -z "$NEW_LISTS" ]; then
    UPDATED_LISTS="${INITIAL_LISTS}${NEW_LISTS}"
    sed -i "1s|.*|${UPDATED_LISTS}|" "$LFLIST_FILE"
fi

# Verificar el contenido de la lista inicial después de la modificación
echo "Lista inicial en lflist.conf después de la modificación:"
sed -n '1p' "$LFLIST_FILE"

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
git commit -m "Add updated lflist.conf"
git push origin main



