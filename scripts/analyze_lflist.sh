#!/bin/bash

# Archivo de salida
OUTPUT_FILE="lflist_result.txt"

# Ruta al archivo lflist.conf en el repositorio clonado
LFLIST_FILE="repo-koishi/lflist.conf"

# Verificar que el archivo existe
if [ ! -f "$LFLIST_FILE" ]; then
    echo "Error: No se encontró el archivo $LFLIST_FILE" > $OUTPUT_FILE
    exit 1
fi

# Inicializar el archivo de salida
echo "Analizando $LFLIST_FILE..." > $OUTPUT_FILE

# Contar y listar las listas en el archivo
LISTS=$(grep -oP '\[\K[^\]]+' "$LFLIST_FILE")

# Contar el número de listas
LIST_COUNT=$(echo "$LISTS" | wc -l)

# Guardar los resultados en el archivo de salida
echo "Total de listas: $LIST_COUNT" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE
echo "Listas encontradas:" >> $OUTPUT_FILE
echo "$LISTS" >> $OUTPUT_FILE

echo "Análisis completado. Resultados guardados en $OUTPUT_FILE."
