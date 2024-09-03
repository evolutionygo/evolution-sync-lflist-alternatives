#!/bin/bash

# Variables para el script
LFLIST_FILE="lflist.conf"  # Nombre del archivo lflist.conf que estás procesando
DEST_REPO_URL="https://${TOKEN}@github.com/termitaklk/koishi-Iflist.git"  # URL del repo de destino, usa el token para autenticación
DEST_REPO_DIR="koishi-Iflist"  # Directorio del repositorio clonado
COMPARISON_REPO_URL="https://github.com/termitaklk/lflist"  # URL del repositorio con archivos .conf

# Obtener el año actual y el año anterior
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

# Filtrar y mantener solo los ítems que contienen el año actual
NEW_LIST="#"
MATCHED_ITEMS=""
COUNT_CURRENT_YEAR=0

while IFS= read -r ITEM; do
    echo "Recibido ITEM: $ITEM"  # Log para mostrar el ítem que se recibe
    if echo "$ITEM" | grep -q "$CURRENT_YEAR"; then
        NEW_LIST="${NEW_LIST}${ITEM}"
        MATCHED_ITEMS="${MATCHED_ITEMS}${ITEM} "
        COUNT_CURRENT_YEAR=$((COUNT_CURRENT_YEAR + 1))
        echo "Guardado ITEM: $ITEM"  # Log para mostrar el ítem que se guarda
    fi
done <<< "$INITIAL_LISTS"

# Si la cantidad de ítems del año actual es 2 o menos, incluir los del año anterior
if [ "$COUNT_CURRENT_YEAR" -le 2 ]; then
    while IFS= read -r ITEM; do
        if echo "$ITEM" | grep -q "$PREVIOUS_YEAR"; then
            NEW_LIST="${NEW_LIST}${ITEM}"
            MATCHED_ITEMS="${MATCHED_ITEMS}${ITEM} "
            echo "Añadiendo ITEM del año anterior: $ITEM"
        fi
    done <<< "$INITIAL_LISTS"
fi

# Mostrar los ítems que cumplen con el año actual y el año anterior si aplica
echo "Ítems que cumplen con el año $CURRENT_YEAR y $PREVIOUS_YEAR: $MATCHED_ITEMS"

# Mostrar todos los ítems que comienzan con '!'
ITEMS_WITH_EXCLAMATION=$(grep '^!' "$LFLIST_FILE")
echo "$ITEMS_WITH_EXCLAMATION"

# Filtrar y mantener solo los ítems que corresponden al año actual
while IFS= read -r ITEM; do
    ITEM_NO_EXCLAMATION=$(echo "$ITEM" | cut -c2-)  # Remover el '!' para obtener el nombre del ítem
    if echo "$ITEM_NO_EXCLAMATION" | grep -q "$CURRENT_YEAR" || [ "$COUNT_CURRENT_YEAR" -le 2 ] && echo "$ITEM_NO_EXCLAMATION" | grep -q "$PREVIOUS_YEAR"; then
        echo "Manteniendo $ITEM"  # Log para mostrar los ítems que se mantienen
    else
        echo "Eliminando $ITEM del archivo lflist.conf"
        sed -i "/^$ITEM/,/^$/d" "$LFLIST_FILE"
    fi
done <<< "$ITEMS_WITH_EXCLAMATION"

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

# Actualizar la línea 1 en el archivo para mantener solo los ítems que aún son válidos
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
git commit -m "Keep only items that match the current year, add missing lists from external .conf files, omit those with 'KS', and include previous year items if current year has 2 or fewer."
git push origin main  # Asegúrate de estar en la rama principal o ajusta la rama si es necesario

















