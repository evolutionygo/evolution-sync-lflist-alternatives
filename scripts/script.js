const fs = require('fs');
const { execSync } = require('child_process');
const path = require('path');

// Variables
const LFLIST_FILE = 'lflist.conf';
const NEW_LFLIST_FILE = 'new_lflist.conf';
const CURRENT_YEAR = new Date().getFullYear();
const PREVIOUS_YEAR = CURRENT_YEAR - 1;

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

// Función para escribir el nuevo archivo lflist.conf
function writeNewLflist(mostRecentItem, listItem) {
  const header = `#[${mostRecentItem}]`;
  const filePath = path.join('scripts', 'new_lflist.conf');

  fs.writeFileSync(filePath, `${header}\n${listItem || ''}`);
  console.log(`Nuevo archivo lflist.conf creado con el ítem más reciente: ${header}`);

  // Confirmar que el archivo ha sido creado
  if (fs.existsSync(filePath)) {
    console.log(`Archivo generado correctamente en ${filePath}`);
  } else {
    console.error(`Error: No se pudo generar el archivo ${filePath}`);
  }
}

// Función para encontrar la lista correspondiente al ítem más reciente
function findListForItem(item, lflistData) {
  const lines = lflistData.split('\n');
  return lines.find(line => line.startsWith(`!${item}`));
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

  // Escribir el nuevo archivo lflist.conf
  writeNewLflist(mostRecentItem, listItem);
}

main();




















