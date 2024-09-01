#!/bin/bash

# Archivo de salida
OUTPUT_FILE="comparison_result.txt"

# Ruta al archivo lflist.conf en el repositorio clonado
LFLIST_FILE="lflist.conf"

# Verificar que el archivo lflist.conf existe
if [ ! -f "$LFLIST_FILE" ]; then
    echo "Error: No se encontró el archivo $LFLIST_FILE"
    exit 1
fi

# Extraer listas de lflist.conf
LFLIST_CONTENT=$(grep -oP '\[\K[^\]]+' "$LFLIST_FILE")

# Inicializar el archivo de salida
echo "Resultado de la comparación:" > $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

# Iterar sobre todos los archivos .conf en el repositorio de comparación
for conf_file in comparison-repo/*.conf; do
    if [ -f "$conf_file" ]; then
        # Extraer la lista del archivo .conf actual
        ITEM=$(grep -oP '\[\K[^\]]+' "$conf_file")
        
        if [ -z "$ITEM" ]; then
            echo "No se encontró una lista válida en $conf_file" >> $OUTPUT_FILE
            continue
        fi

        # Comparar con las listas en lflist.conf
        if echo "$LFLIST_CONTENT" | grep -q "$ITEM"; then
            echo "$ITEM de $conf_file se encuentra en lflist.conf" >> $OUTPUT_FILE
        else
            echo "$ITEM de $conf_file NO se encuentra en lflist.conf" >> $OUTPUT_FILE
        fi
    fi
done

# Mostrar el resultado en los logs
cat $OUTPUT_FILE
