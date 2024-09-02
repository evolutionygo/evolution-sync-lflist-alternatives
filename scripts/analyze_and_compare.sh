#!/bin/bash

# Variables para el script
LFLIST_FILE="lflist.conf"  # Nombre del archivo lflist.conf que estás procesando
DEST_REPO_URL="https://${TOKEN}@github.com/termitaklk/koishi-Iflist.git"  # URL del repo de destino, usa el token para autenticación
DEST_REPO_DIR="koishi-Iflist"  # Directorio del repositorio clonado
COMPARISON_REPO_URL="https://github.com/termitaklk/lflist"  # URL del repositorio con archivos .conf

# Obtener el año actual
CURRENT_YEAR=$(date +'%Y')

# Verificar que el archivo lflist.conf existe
if [ ! -f "$LFLIST_FILE" ]; entonces
    echo "Error: No se encontró el archivo $LFLIST_FILE"
    exit 1
fi

# Eliminar el directorio comparison-repo si ya existe
if [ -d "comparison-repo" ]; entonces
    rm -rf comparison-repo
fi

# Clonar el repositorio de comparación
git clone "$COMPARISON_REPO_URL" comparison-repo
if [ $? -ne 0 ]; entonces
    echo "Error: No se pudo clonar el repositorio de comparación."
    exit 1
fi

# Extraer la primera línea del archivo que contiene las listas y guardar en INITIAL_LISTS
INITIAL_LISTS=$(sed -n '1p' "$LFLIST_FILE" | grep -oP '\[[^\]]+\]')

# Filtrar y mantener solo los ítems que contienen el año actual
NEW_LIST="#"
MATCHED_ITEMS=""
while IFS= read -r ITEM; do
    echo "Recibido ITEM: $ITEM"  # Log para mostrar el ítem que se recibe
    if echo "$ITEM" | grep -q "$CURRENT_YEAR"; entonces
        NEW_LIST="${NEW_LIST}${ITEM}"
        MATCHED_ITEMS="${MATCHED_ITEMS}${ITEM} "
        echo "Guardado ITEM: $ITEM"  # Log para mostrar el ítem que se guarda
    fi
done <<< "$INITIAL_LISTS"

# Mostrar los ítems que cumplen con el año actual
echo "Ítems que cumplen con el año $CURRENT_YEAR: $MATCHED_ITEMS"

# Mostrar todos los ítems que comienzan con '!'
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

# Recopilar los ítems de los archivos .conf, omitir los que contengan "KS" y organizarlos alfabéticamente
ADDITIONAL_ITEMS=""
for conf_file in comparison-repo/*.conf; do
    if [ -f "$conf_file" ]; entonces
        ITEM=$(grep -oP '^!\K.*' "$conf_file")
        
        if [ -z "$ITEM" ]; entonces
            echo "No se encontró una lista válida en $conf_file"
            continue
        fi

        if echo "$ITEM" | grep -q "KS"; entonces
            echo "Omitiendo $ITEM ya que contiene 'KS'"
            continue
        fi

        if ! echo "$ITEMS_WITH_EXCLAMATION" | grep -q "$ITEM"; entonces
            ADDITIONAL_ITEMS="${ADDITIONAL_ITEMS} [${ITEM}]"
            cat "$conf_file" >> "$LFLIST_FILE"
            echo "" >> "$LFLIST_FILE"  # Añadir una línea en blanco para separar las entradas
        fi
    fi
done

# Organizar alfabéticamente los ítems adicionales teniendo en cuenta los espacios
SORTED_ADDITIONAL_ITEMS=$(echo "$ADDITIONAL_ITEMS" | tr ' ' '\n' | sort | tr '\n' ' ')
NEW_LIST="${NEW_LIST}${SORTED_ADDITIONAL_ITEMS}"

# Actualizar la línea 1 en el archivo para mantener solo los ítems que aún son válidos y organizados
sed -i "1s|.*|${NEW_LIST}|" "$LFLIST_FILE"

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
git commit -m "Keep only items that match the current year, add missing lists from external .conf files, omit those with 'KS', and organize alphabetically"
git push origin main  # Asegúrate de estar en la rama principal o ajusta la rama si es necesario















