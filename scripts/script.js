const fs = require('fs');
const { execSync } = require('child_process');
const path = require('path');

// Variables
const LFLIST_FILE = 'lflist.conf';
const CURRENT_YEAR = new Date().getFullYear();
const TOKEN = process.env.TOKEN;

// URL del repositorio de destino, usando el token
const DEST_REPO_URL = `https://${TOKEN}@github.com/termitaklk/koishi-Iflist.git`;

// Objeto para especificar las listas que deben permanecer y su orden
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

// Función para listar los ítems que comienzan con '!' de un archivo
function listItems(filePath) {
  const data = fs.readFileSync(filePath, 'utf8');
  const items = data.match(/^!\[.*\]$/gm); // Obtener los ítems que comienzan con '!' y pueden tener espacios
  return items ? items.map(item => item.replace(/^!/, '').trim()) : [];
}

// Función para listar todos los ítems de los dos repositorios
function listAllItems() {
  let allItems = [];

  // Leer el archivo lflist.conf del primer repositorio
  const lflistItems = listItems(path.join('repo-koishi', 'mobile', 'assets', 'data', 'conf', LFLIST_FILE));
  allItems = allItems.concat(lflistItems);

  // Leer los archivos .conf del segundo repositorio
  const confFiles = fs.readdirSync('comparison-repo').filter(file => file.endsWith('.conf'));
  confFiles.forEach(file => {
    const filePath = path.join('comparison-repo', file);
    const confItems = listItems(filePath);
    allItems = allItems.concat(confItems);
  });

  return allItems;
}

// Función para imprimir los ítems en consola
function printItems(items) {
  console.log('Lista de ítems:');
  items.forEach(item => console.log(item));
}

// Función para ordenar los ítems según el objeto banlistsOrder
function sortItemsByBanlistOrder(items) {
  const sortedItems = [];

  Object.keys(banlistsOrder).forEach(key => {
    const banlistName = banlistsOrder[key];
    const matchingItem = items.find(item => item.includes(banlistName));
    if (matchingItem) {
      sortedItems.push(matchingItem);
    }
  });

  return sortedItems;
}

// Función para escribir el archivo lflist.conf final
function writeFinalLflist(sortedItems) {
  const filePath = path.join('scripts', LFLIST_FILE);
  const header = '# Listas Generadas según el orden establecido\n';
  const content = sortedItems.map(item => `!${item}`).join('\n');

  fs.writeFileSync(filePath, `${header}\n${content}`);
  console.log('Archivo lflist.conf generado correctamente con los ítems ordenados.');
}

// Función para mover y hacer push al repositorio de destino
function moveAndPush() {
  execSync(`mv scripts/${LFLIST_FILE} koishi-Iflist/`);
  process.chdir('koishi-Iflist');
  execSync('git config user.name "GitHub Action"');
  execSync('git config user.email "action@github.com"');

  execSync(`git add ${LFLIST_FILE}`);
  execSync('git commit -m "Update lflist.conf with the sorted banlist items"');
  execSync('git push origin main');
  console.log('Cambios subidos al repositorio.');
}

// Main
function main() {
  // Clonar repositorios
  cloneRepo('https://github.com/fallenstardust/YGOMobile-cn-ko-en', 'repo-koishi');
  cloneRepo('https://github.com/termitaklk/lflist', 'comparison-repo');

  // Listar todos los ítems
  const allItems = listAllItems();
  printItems(allItems); // Imprimir los ítems antes de ordenarlos

  // Ordenar los ítems según el objeto banlistsOrder
  const sortedItems = sortItemsByBanlistOrder(allItems);
  console.log('Ítems ordenados según banlistsOrder:');
  printItems(sortedItems);

  // Escribir el archivo final lflist.conf
  writeFinalLflist(sortedItems);

  // Subir los cambios al repositorio de destino
  cloneRepo(DEST_REPO_URL, 'koishi-Iflist');
  moveAndPush();
}

main(); // Inicia el proceso































