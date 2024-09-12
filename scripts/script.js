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
}

// Función para leer los ítems de lflist.conf
function readLflistItems(filePath) {
  const data = fs.readFileSync(filePath, 'utf8');
  return data.match(/^!\S+/gm) || [];
}

// Función para leer los ítems de los archivos .conf
function readConfItems(confRepoPath) {
  const confFiles = fs.readdirSync(confRepoPath).filter(file => file.endsWith('.conf'));
  let items = [];
  confFiles.forEach(file => {
    const filePath = path.join(confRepoPath, file);
    const fileData = fs.readFileSync(filePath, 'utf8');
    const fileItems = fileData.match(/^!\S+/gm);
    if (fileItems) {
      items = items.concat(fileItems.map(item => item.replace(/^!/, '')));
    }
  });
  return items;
}

// Función para ordenar y filtrar ítems en función del objeto banlistsOrder
function filterAndSortItems(items) {
  return Object.values(banlistsOrder).filter(orderItem => items.includes(orderItem));
}

// Función para escribir el archivo final lflist.conf con las listas filtradas y ordenadas
function writeFinalLflist(sortedItems) {
  const filePath = path.join('scripts', LFLIST_FILE);
  const header = "# Listas Generadas según el orden establecido\n";
  const content = sortedItems.map(item => `!${item}`).join('\n');
  fs.writeFileSync(filePath, `${header}${content}`);
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

  // Filtrar y ordenar ítems según el objeto banlistsOrder
  const sortedItems = filterAndSortItems(combinedItems);

  // Escribir el archivo final lflist.conf
  writeFinalLflist(sortedItems);
}

main(); // Ejecutar el proceso






























