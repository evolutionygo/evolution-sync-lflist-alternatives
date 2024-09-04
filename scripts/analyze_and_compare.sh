#!/bin/bash

# Variables para el script
LFLIST_FILE="lflist.conf"  # Nombre del archivo lflist.conf que estás procesando
DEST_REPO_URL="https://${TOKEN}@github.com/termitaklk/koishi-Iflist.git"  # URL del repo de destino, usa el token para autenticación
DEST_REPO_DIR="koishi-Iflist"  # Directorio del repositorio clonado
COMPARISON_REPO_URL="https://github.com/termitaklk/lflist"  # URL del repositorio con archivos .conf

# Obtener el año actual
CURRENT_YEAR=$(date +'%Y')
PREVIOUS_YEAR=$((CURRENT_YEAR - 1))

# Verificar que el archivo lflist.conf existe
if [ ! -f "$LFLIST_FILE" ]; then
    echo "Error: No se encontró el archivo $LFLIST_FILE"
    exit 1
fi

# Eliminar el directorio comparison-repo si ya existe
if [ -d "comparison-repo" ]; then
    rm -rf comparison-repo
fi

# Clonar el repositorio de comparación
git clone "$COMPARISON_REPO_URL" comparison-repo
if [ $? -ne 0 ]; then
    echo "Error: No se pudo clonar el repositorio de comparación."
    exit 1
fi

# Extraer la primera línea del archivo que contiene las listas y guardar en INITIAL_LISTS
INITIAL_LISTS=$(sed -n '1p' "$LFLIST_FILE" | grep -oP '\[[^\]]+\]')

# Mostrar el contenido almacenado en INITIAL_LISTS
echo "Contenido de INITIAL_LISTS: $INITIAL_LISTS"

# Filtrar y mantener solo los ítems que contienen el año actual o el año anterior
NEW_LIST="#"
COUNT_CURRENT_YEAR=0

# Ordenar los ítems por fecha (año.mes o año.mes.día)
SORTED_ITEMS=$(echo "$INITIAL_LISTS" | tr ' ' '\n' | grep -oP '\[\K[^]]+' | sort -r -t '.' -k1,1n -k2,2n -k3,3n)

# Recorrer los ítems ordenados y agregar solo aquellos que coincidan con el año actual o anterior
for ITEM in $SORTED_ITEMS; do
    ITEM_YEAR=$(echo "$ITEM" | cut -d'.' -f1)
    
    # Incluir solo ítems cuyo año sea el actual o el anterior
    if [ "$ITEM_YEAR" -eq "$CURRENT_YEAR" ] || [ "$ITEM_YEAR" -eq "$PREVIOUS_YEAR" ]; then
        if [ "$COUNT_CURRENT_YEAR" -eq 0 ]; then
            NEW_LIST="#[$ITEM]"
        else
            NEW_LIST="$NEW_LIST [$ITEM]"
        fi
        COUNT_CURRENT_YEAR=$((COUNT_CURRENT_YEAR + 1))
    else
        echo "Excluyendo ITEM: [$ITEM] ya que no coincide con el año actual o anterior"
    fi
done

# Mostrar los ítems ordenados y filtrados
echo "Ítems ordenados por fecha que coinciden con el año actual o anterior: $NEW_LIST"

# Mostrar todos los ítems que comienzan con '!'
echo "Ítems que comienzan con '!':"
ITEMS_WITH_EXCLAMATION=$(grep '^!' "$LFLIST_FILE")
echo "$ITEMS_WITH_EXCLAMATION"

# Comparar con los archivos .conf de otro repositorio y añadir los que no existan en lflist.conf
for conf_file in comparison-repo/*.conf; do
    if [ -f "$conf_file" ]; then
        # Extraer la lista del archivo .conf actual que comienza con '!', manejando nombres con espacios
        ITEM=$(grep -oP '^!\K.*' "$conf_file")
        
        if [ -z "$ITEM" ]; then
            echo "No se encontró una lista válida en $conf_file"
            continue
        fi

        # Omitir ítems que contengan "KS"
        if echo "$ITEM" | grep -q "KS"; then
            echo "Omitiendo $ITEM ya que contiene 'KS'"
            continue
        fi

        # Comparar con las listas en lflist.conf
        if echo "$ITEMS_WITH_EXCLAMATION" | grep -q "$ITEM"; then
            echo "$ITEM de $conf_file ya se encuentra en lflist.conf"
        else
            echo "$ITEM de $conf_file NO se encuentra en lflist.conf. Añadiendo..."
            # Añadir la lista al final de lflist.conf
            cat "$conf_file" >> "$LFLIST_FILE"
            echo "" >> "$LFLIST_FILE"  # Añadir una línea en blanco para separar las entradas

            # Añadir la lista a la sección inicial de listas en la línea 1
            NEW_LIST="${NEW_LIST} [${ITEM}]"
        fi
    fi
done

# Actualizar la línea 1 en el archivo para mantener los ítems ordenados por fecha
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
git commit -m "Ordenar los ítems por fecha, asegurando que el más reciente aparezca primero."
git push origin main  # Asegúrate de estar en la rama principal o ajusta la rama si es necesario

















