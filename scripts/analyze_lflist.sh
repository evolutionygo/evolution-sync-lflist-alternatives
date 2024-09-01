#!/bin/bash

# Archivo de salida
OUTPUT_FILE="lflist_result.txt"

# Inicializar el archivo de salida
echo "Analizando lflist.conf..." > $OUTPUT_FILE

# Contar y listar las listas en el archivo
LISTS=$(grep -oP '\[\K[^\]]+' lflist.conf)

# Contar el número de listas
LIST_COUNT=$(echo "$LISTS" | wc -l)

# Guardar los resultados en el archivo de salida
echo "Total de listas: $LIST_COUNT" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE
echo "Listas encontradas:" >> $OUTPUT_FILE
echo "$LISTS" >> $OUTPUT_FILE

echo "Análisis completado. Resultados guardados en $OUTPUT_FILE."
