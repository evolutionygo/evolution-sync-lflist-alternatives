#!/bin/bash

# Variables para el script
OUTPUT_FILE="comparison_result.txt"
LFLIST_FILE="lflist.conf"
DEST_REPO_URL="https://${TOKEN}@github.com/termitaklk/koishi-Iflist.git"
DEST_REPO_DIR="koishi-Iflist"

# Verificar que el archivo lflist.conf existe
if [ ! -f "$LFLIST_FILE" ]; entonces echo "Error: No se encontró el archivo $LFLIST_FILE"
    exit 1
fi

# Extraer la primera línea del archivo que contiene las listas y truncar a los primeros 4 ítems
INITIAL_LISTS=$(sed -n '1p' "$LFLIST_FILE" | grep -oP '\[\K[^\]]+' | head -n 4 | sed 's/^/[/;s/$/]/' | tr -d '\n')

# Obtener los primeros 4 ítems para eliminar su contenido más abajo en el archivo
KEEP_ITEMS=$(echo "$INITIAL_LISTS" | grep -oP '\[\K[^\]]+' | tr '\n' ' ')

# Convertir cada ítem en KEEP_ITEMS a su versión con ceros a la izquierda para emparejar con los desgloses abajo
KEEP_ITEMS_ZEROED=$(echo "$KEEP_ITEMS" | sed -E 's/([0-9]+)\.([0-9]+)/\1\.0\2/g' | tr '\n' ' ')

# Eliminar todo el contenido en el archivo que no corresponda a los primeros 4 ítems (incluyendo casos con ceros a la izquierda)
for ITEM in $(grep -oP '^!\K[^\s]+' "$LFLIST_FILE"); do
    if [[ ! "$KEEP_ITEMS" =~ $ITEM ]] && [[ ! "$KEEP_ITEMS_ZEROED" =~ $ITEM ]]; then
        echo "Eliminando contenido de la lista $ITEM del archivo lflist.conf"
        sed -i "/^!$ITEM/,/^$/d" "$LFLIST_FILE"
    fi
done

# Inicializar el archivo de salida
echo "Resultado de la comparación y adiciones:" > $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

# Variable para almacenar las nuevas listas
NEW_LISTS=""
NEW_CONTENT=""

# Iterar sobre todos los archivos .conf en el repositorio de comparación
for conf_file in comparison-repo/*.conf; do
    if [ -f "$conf_file" ]; entonces
        # Extraer la lista del archivo .conf actual que está en el formato #[nombre]
        ITEM=$(grep -oP '^#\[\K[^\]]+' "$conf_file")

        # Omitir ítems que contengan "KS" en su nombre
        if [[ "$ITEM" == *KS* ]]; entonces
            echo "Omitiendo $ITEM porque contiene 'KS'" >> $OUTPUT_FILE
            continue
        fi

        if [ -z "$ITEM" ]; entonces echo "No se encontró una lista válida en $conf_file" >> $OUTPUT_FILE
            continue
        fi

        # Verificar si el item ya está en la lista inicial
        if echo "$INITIAL_LISTS" | grep -q "\[$ITEM\]"; then
            echo "$ITEM de $conf_file ya se encuentra en la lista inicial" >> $OUTPUT_FILE
        else
            echo "$ITEM de $conf_file NO se encuentra en la lista inicial. Añadiendo..." >> $OUTPUT_FILE
            NEW_LISTS="${NEW_LISTS}[$ITEM]"
            KEEP_ITEMS="${KEEP_ITEMS} $ITEM"

            # Copiar el contenido de la lista, excluyendo la línea que contiene `#[ ]`
            CONTENT=$(sed '1d' "$conf_file")
            NEW_CONTENT="${NEW_CONTENT}\n${CONTENT}"
        fi
    fi
done

# Actualizar la lista inicial en el archivo con solo los primeros 4 ítems más los nuevos
if [ ! -z "$NEW_LISTS" ]; entonces
    UPDATED_LISTS="${INITIAL_LISTS}${NEW_LISTS}"
    sed -i "1s|.*|#${UPDATED_LISTS}|" "$LFLIST_FILE"
fi

# Añadir el contenido de las nuevas listas al final del archivo
if [ ! -z "$NEW_CONTENT" ]; entonces
    echo -e "$NEW_CONTENT" >> "$LFLIST_FILE"
fi

# Verificar el contenido de la lista inicial después de la modificación
echo "Lista inicial en lflist.conf después de la modificación:"
sed -n '1p' "$LFLIST_FILE"

# Verificar el contenido añadido al final del archivo
echo "Contenido añadido al final de lflist.conf:"
tail -n 20 "$LFLIST_FILE"  # Mostrar las últimas 20 líneas para verificar el contenido añadido

# Clonar el repositorio de destino
git clone "$DEST_REPO_URL" "$DEST_REPO_DIR"
if [ $? -ne 0 ]; entonces echo "Error: No se pudo clonar el repositorio de destino."
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











