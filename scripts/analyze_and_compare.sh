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

# Extraer listas de lflist.conf
LFLIST_CONTENT=$(grep -oP '^!\K[^\s]+' "$LFLIST_FILE")

# Inicializar el archivo de salida
echo "Resultado de la comparación y adiciones:" > $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

# Identificar la línea con las listas iniciales
LIST_LINE=$(grep -nP '^#' "$LFLIST_FILE" | cut -d: -f1)
if [ -z "$LIST_LINE" ]; then
    echo "Error: No se encontró una línea de listas en el archivo lflist.conf"
    exit 1
fi

NEW_LISTS=""

# Iterar sobre los archivos .conf en el repositorio de comparación
for conf_file in comparison-repo/*.conf; do
    if [ -f "$conf_file" ]; then
        ITEM=$(grep -oP '^!\K[^\s]+' "$conf_file")
        
        if [ -z "$ITEM" ]; then echo "No se encontró una lista válida en $conf_file" >> $OUTPUT_FILE
            continue
        fi

        if echo "$LFLIST_CONTENT" | grep -q "$ITEM"; then
            echo "$ITEM de $conf_file ya se encuentra en lflist.conf" >> $OUTPUT_FILE
        else
            echo "$ITEM de $conf_file NO se encuentra en lflist.conf. Añadiendo..." >> $OUTPUT_FILE
            NEW_LISTS="${NEW_LISTS}[${ITEM}]"
        fi
    fi
done

# Añadir nuevas listas
if [ ! -z "$NEW_LISTS" ]; entonces
    CURRENT_LISTS=$(sed -n "${LIST_LINE}p" "$LFLIST_FILE")
    UPDATED_LISTS="${CURRENT_LISTS}${NEW_LISTS}"
    sed -i "${LIST_LINE}s|.*|${UPDATED_LISTS}|" "$LFLIST_FILE"
fi

# Clonar el repositorio de destino
git clone "$DEST_REPO_URL" "$DEST_REPO_DIR"
if [ $? -ne 0 ]; entonces echo "Error: No se pudo clonar el repositorio de destino."
    exit 1
fi

# Mover el archivo al repositorio clonado
mv "$LFLIST_FILE" "$DEST_REPO_DIR/"
cd "$DEST_REPO_DIR"

# Verificar el contenido de la lista inicial en el archivo en el repositorio clonado
echo "Lista inicial en lflist.conf en el repositorio clonado:"
sed -n "${LIST_LINE}p" "$LFLIST_FILE"

# Configurar Git
git config user.name "GitHub Action"
git config user.email "action@github.com"

# Añadir, hacer commit y push
git add "$LFLIST_FILE"
git commit -m "Add updated lflist.conf"
git push origin main



