#!/bin/bash

# Variables para el script
OUTPUT_FILE="comparison_result.txt"  # Archivo de salida para el informe
LFLIST_FILE="lflist.conf"  # Nombre del archivo lflist.conf que estás procesando
DEST_REPO_URL="https://${TOKEN}@github.com/termitaklk/koishi-Iflist.git"  # URL del repo de destino, usa el token para autenticación
DEST_REPO_DIR="koishi-Iflist"

# Verificar que el archivo lflist.conf existe
if [ ! -f "$LFLIST_FILE" ]; then
    echo "Error: No se encontró el archivo $LFLIST_FILE"
    exit 1
fi

# Extraer listas de lflist.conf, considerando listas que comienzan con '!'
LFLIST_CONTENT=$(grep -oP '^!\K[^\s]+' "$LFLIST_FILE")

# Inicializar el archivo de salida
echo "Resultado de la comparación y adiciones:" > $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

# Identificar la línea con las listas iniciales en el archivo lflist.conf
LIST_LINE=$(grep -nP '^#' "$LFLIST_FILE" | cut -d: -f1)
if [ -z "$LIST_LINE" ]; then
    echo "Error: No se encontró una línea de listas en el archivo lflist.conf"
    exit 1
fi

# Variable para almacenar las nuevas listas
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

        # Comparar con las listas en lflist.conf
        if echo "$LFLIST_CONTENT" | grep -q "$ITEM"; then
            echo "$ITEM de $conf_file ya se encuentra en lflist.conf" >> $OUTPUT_FILE
        else
            echo "$ITEM de $conf_file NO se encuentra en lflist.conf. Añadiendo..." >> $OUTPUT_FILE
            # Añadir la lista al final de lflist.conf
            cat "$conf_file" >> "$LFLIST_FILE"
            echo "" >> "$LFLIST_FILE"  # Añadir una línea en blanco para separar las entradas

            # Añadir la lista a la sección inicial de listas
            NEW_LISTS="${NEW_LISTS} [${ITEM}]"
        fi
    fi
done

# Si hay nuevas listas, añadirlas a la línea de listas
if [ ! -z "$NEW_LISTS" ]; then
    sed -i -e "${LIST_LINE}s/$/${NEW_LISTS}/" "$LFLIST_FILE"
fi

# Clonar el repositorio de destino directamente en la raíz
git clone "$DEST_REPO_URL" "$DEST_REPO_DIR"
if [ $? -ne 0 ]; then
    echo "Error: No se pudo clonar el repositorio de destino."
    exit 1
fi

# Mover el archivo finalizado al repositorio clonado y hacer push
mv "$LFLIST_FILE" "$DEST_REPO_DIR/"
cd "$DEST_REPO_DIR"

# Configurar Git
git config user.name "GitHub Action"
git config user.email "action@github.com"

# Añadir, hacer commit y push
git add "$LFLIST_FILE"
git commit -m "Add updated lflist.conf"
git push origin main  # Ajusta la rama si es necesario

