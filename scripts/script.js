const fs = require('fs');
const { execSync } = require('child_process');
const path = require('path');

// Variables
const LFLIST_FILE = 'lflist.conf';
const banlistsOrder = {
  1: "2024.09 TCG",
  2: "Edison(PreErrata)",
  3: "2014.4 HAT",
  4: "2011.09 Tengu Plant",
  5: "MD 08.2024",
  6: "JTP (Original)",
  7: "GXS-Marzo-2008",
  8: "2024.05 TDG",
  9: "2019.10 Eterno",
  10: "2015.4 Duel Terminal",
  11: "2008.03 DAD Return",
  12: "MDC - Evolution S6",
};

// Función para clonar un repositorio
function cloneRepo(repoUrl, targetDir) {
  if (fs.existsSync(targetDir)) {
    fs.rmSync(targetDir, { recursive: true, force: true });
  }
  execSync(`git clone ${repoUrl} ${targetDir}`);
  console.log(`Clonado el repositorio ${repoUrl} en ${targetDir}`);
}

// Función para leer los ítems de lflist.conf
function readLflistItems(filePath) {
  const data = fs.readFileSync(filePath, 'utf8');
  console.log('Contenido de lflist.conf:', data); // Mostrar contenido de lflist.conf para depuración
  const lists = data.match(/^!\[[^\]]+\]/gm); // Capturar ítems con espacios entre corchetes []
  console.log('Ítems encontrados en lflist.conf:', lists); // Log para depuración
  return lists || [];
}

// Función para leer los ítems de los archivos .conf
function readConfItems(confRepoPath) {
  const confFiles = fs.readdirSync(confRepoPath).filter(file => file.endsWith('.conf'));
  console.log('Archivos .conf encontrados:', confFiles); // Mostrar archivos .conf encontrados para depuración
  let items = [];
  confFiles.forEach(file => {
    const filePath = path.join(confRepoPath, file);
    const fileData = fs.readFileSync(filePath, 'utf8');
    console.log(`Contenido del archivo ${file}:`, fileData); // Mostrar contenido de cada archivo .conf para depuración
    const fileItems = fileData.match(/^!\[[^\]]+\]/gm); // Capturar ítems completos, incluso con espacios
    if (fileItems) {
      items = items.concat(fileItems.map(item => item.replace(/^!/, ''))); // Eliminar el "!" y mantener el nombre completo
    }
  });
  console.log('Ítems encontrados en archivos .conf:', items); // Log para depuración
  return items;
}

// Función para ordenar y filtrar ítems en función del objeto banlistsOrder
function filterAndSortItems(items) {
  const sortedItems = Object.values(banlistsOrder).filter(orderItem => items.includes(orderItem));
  console.log('Ítems después de filtrar y ordenar:', sortedItems); // Log para depuración
  return sortedItems;
}

// Función para escribir el archivo final lflist.conf con las listas filtradas y ordenadas
function writeFinalLflist(sortedItems) {
  const filePath = path.join('scripts', LFLIST_FILE);
  const header = "# Listas Generadas según el orden establecido\n";
  const content = sortedItems.map(item => `!${item}`).join('\n');
  fs.writeFileSync(filePath, `${header}${content}`);
  console.log(`Archivo final lflist.conf creado con los ítems ordenados.`);
}

// Main
function main() {
  // Clonar repositorios
  cloneRepo('https://github.com/fallenstardust/YGOMobile-cn-ko-en', 'repo-koishi');
  cloneRepo('https://github.com/termitaklk/lflist', 'comparison-repo');

  // Leer los ítems de lflist.conf y archivos .conf
  const lflistItems = readLflistItems(path.join('repo-koishi', 'mobile', 'assets', 'data', 'conf', LFLIST_FILE));
  const confItems = readConfItems('comparison-repo');

  // Combinar ítems de lflist.conf y .conf
  const combinedItems = [...new Set([...lflistItems, ...confItems])];

  // Mostrar la lista de ítems antes de ordenarlas
  console.log('Lista de ítems antes de ordenar:');
  console.log(combinedItems);

  // Filtrar y ordenar ítems según el objeto banlistsOrder
  const sortedItems = filterAndSortItems(combinedItems);

  // Mostrar cómo se compara cada ítem con el objeto banlistsOrder
  sortedItems.forEach(item => {
    const order = Object.keys(banlistsOrder).find(key => banlistsOrder[key] === item);
    console.log(`Ítem: ${item} | Posición en banlistsOrder: ${order}`);
  });

  // Escribir el archivo final lflist.conf
  writeFinalLflist(sortedItems);
}

main(); // Ejecutar el proceso






























