const fs = require('fs');
const { execSync } = require('child_process');
const path = require('path');

// Variables
const LFLIST_FILE = 'lflist.conf';
const CURRENT_YEAR = new Date().getFullYear();
const PREVIOUS_YEAR = CURRENT_YEAR - 1;

// Obtener el token de las variables de entorno
const TOKEN = process.env.TOKEN;

// URL del repositorio de destino, usando el token
const DEST_REPO_URL = `https://${TOKEN}@github.com/termitaklk/koishi-Iflist.git`;

// Función para clonar un repositorio
function cloneRepo(repoUrl, targetDir) {
  if (fs.existsSync(targetDir)) {
    fs.rmSync(targetDir, { recursive: true, force: true });
  }
  execSync(`git clone ${repoUrl} ${targetDir}`);
  console.log(`Clonado el repositorio ${repoUrl} en ${targetDir}`);
}

// Función para leer el archivo lflist.conf y devolver las listas
function readLflist(filePath) {
  const data = fs.readFileSync(filePath, 'utf8');
  const firstLine = data.split('\n')[0]; // Leer la primera línea
  const lists = firstLine.match(/\[[^\]]+\]/g); // Obtener las listas encerradas en []
  return lists || [];
}

// Filtrar por año en curso y año anterior si corresponde
function filterByYear(lists) {
  const currentYearItems = lists.filter(item => item.includes(CURRENT_YEAR));
  if (currentYearItems.length <= 2) {
    const previousYearItems = lists.filter(item => item.includes(PREVIOUS_YEAR));
    return currentYearItems.concat(previousYearItems);
  }
  return currentYearItems;
}

// Función para ordenar las listas
function sortByDate(lists) {
  return lists.sort((a, b) => {
    const dateA = a.match(/\d{4}\.\d+/g)[0]; // Obtener año.mes
    const dateB = b.match(/\d{4}\.\d+/g)[0];
    return dateB.localeCompare(dateA); // Ordenar de más reciente a más viejo
  });
}

// Función para dar prioridad a TCG en caso de empate
function prioritizeTCG(sortedLists) {
  return sortedLists.sort((a, b) => {
    const hasTCG_A = a.includes('TCG');
    const hasTCG_B = b.includes('TCG');
    if (hasTCG_A && !hasTCG_B) return -1;
    if (!hasTCG_A && hasTCG_B) return 1;
    return 0;
  });
}

// Función para escribir el archivo final lflist.conf
function writeFinalLflist(mostRecentItem, listItem) {
  const header = `#[${mostRecentItem}]`;
  const filePath = path.join('scripts', LFLIST_FILE);

  fs.writeFileSync(filePath, `${header}\n${listItem || ''}`);
  console.log(`Archivo final lflist.conf creado con el ítem más reciente: ${header}`);
}

// Función para encontrar la lista correspondiente al ítem más reciente
function findListForItem(item, lflistData) {
  const lines = lflistData.split('\n');
  let startIndex = lines.findIndex(line => line.startsWith(`!${item}`));

  if (startIndex === -1) {
    console.log(`No se encontró una lista para el ítem: ${item}, intentando añadir 0 al mes...`);

    // Si no encuentra el ítem, intenta añadir un 0 en el mes si el formato es año.mes
    const itemWithZero = item.replace(/(\d{4})\.(\d)(\b)/, '$1.0$2');  // Añade el 0 si el mes tiene solo 1 dígito
    startIndex = lines.findIndex(line => line.startsWith(`!${itemWithZero}`));

    if (startIndex === -1) {
      console.log(`No se encontró una lista para el ítem (ni con el 0 añadido): ${item}`);
      return null;
    } else {
      console.log(`Lista encontrada para el ítem (con 0 añadido): ${itemWithZero}`);
    }
  } else {
    console.log(`Lista encontrada para el ítem ${item}`);
  }

  // Capturar todas las líneas de la lista hasta el siguiente ítem que comienza con "!"
  const listItem = [];
  for (let i = startIndex; i < lines.length; i++) {
    if (lines[i].startsWith('!') && i !== startIndex) break; // Si comienza otro ítem, detener
    listItem.push(lines[i]);
  }

  return listItem.join('\n');
}

// Función para recorrer los archivos .conf en el repositorio de comparación y listar ítems en orden alfabético
function listItemsInAlphabeticalOrder(confRepoPath) {
  const confFiles = fs.readdirSync(confRepoPath).filter(file => file.endsWith('.conf'));

  let items = [];

  // Recorrer cada archivo .conf
  confFiles.forEach(file => {
    const filePath = path.join(confRepoPath, file);
    const fileData = fs.readFileSync(filePath, 'utf8');

    // Extraer los ítems que comienzan con "!"
    const fileItems = fileData.match(/^!\S+/gm);
    if (fileItems) {
      items = items.concat(fileItems.map(item => item.replace(/^!/, ''))); // Quitar el "!"
    }
  });

  // Ordenar alfabéticamente
  const sortedItems = items.sort((a, b) => a.localeCompare(b));

  // Imprimir los ítems ordenados
  console.log('Ítems de archivos .conf en orden alfabético:');
  sortedItems.forEach(item => console.log(item));
}

// Función para verificar si hay cambios antes de hacer commit
function hasChanges() {
  const status = execSync('git status --porcelain').toString();
  return status.trim().length > 0;
}

// Función para mover y hacer push al repositorio de destino
function moveAndPush() {
  execSync(`mv scripts/${LFLIST_FILE} koishi-Iflist/`);
  process.chdir('koishi-Iflist');
  execSync('git config user.name "GitHub Action"');
  execSync('git config user.email "action@github.com"');

  if (hasChanges()) {
    execSync(`git add ${LFLIST_FILE}`);
    execSync('git commit -m "Update lflist.conf with the latest changes"');
    execSync('git pull --rebase origin main');  // Asegurarse de que no haya conflictos
    execSync('git push origin main');
    console.log('Cambios subidos al repositorio.');
  } else {
    console.log('No hay cambios para subir.');
  }
}

// Main
function main() {
  // Clonar repositorios
  cloneRepo('https://github.com/fallenstardust/YGOMobile-cn-ko-en', 'repo-koishi');
  cloneRepo('https://github.com/termitaklk/lflist', 'comparison-repo');

  // Leer el archivo lflist.conf
  const lflistData = fs.readFileSync(path.join('repo-koishi', 'mobile', 'assets', 'data', 'conf', LFLIST_FILE), 'utf8');
  const lists = readLflist(path.join('repo-koishi', 'mobile', 'assets', 'data', 'conf', LFLIST_FILE));

  // Filtrar por año en curso y año anterior
  const filteredLists = filterByYear(lists);

  // Ordenar las listas por fecha
  const sortedLists = sortByDate(filteredLists);

  // Priorizar TCG si hay empate
  const prioritizedLists = prioritizeTCG(sortedLists);

  // Obtener el ítem más reciente
  const mostRecentItem = prioritizedLists[0].replace(/[\[\]]/g, ''); // Sin corchetes
  console.log(`El ítem más reciente es: ${mostRecentItem}`);

  // Buscar la lista correspondiente al ítem más reciente
  const listItem = findListForItem(mostRecentItem, lflistData);

  // Escribir el archivo final lflist.conf
  writeFinalLflist(mostRecentItem, listItem);

  // Clonar el repositorio de destino, mover el archivo y hacer push
  cloneRepo(DEST_REPO_URL, 'koishi-Iflist');
  moveAndPush();

  // Listar ítems de los archivos .conf en orden alfabético
  listItemsInAlphabeticalOrder('comparison-repo');
}

main(); // Inicia el proceso


























