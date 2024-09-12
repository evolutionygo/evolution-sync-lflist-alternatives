const fs = require('fs');
const { execSync } = require('child_process');
const path = require('path');

// Variables
const LFLIST_FILE = 'lflist.conf';
const CURRENT_YEAR = new Date().getFullYear();
const PREVIOUS_YEAR = CURRENT_YEAR - 1;
let combinedItems = [];

// Objeto para especificar las listas que deben permanecer y su orden
const banlistsOrder = {
  1: "2024.9 TCG",
  2: "Edison(PreErrata)",
  3: "HAT",
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

// Función para leer los ítems de lflist.conf y guardarlos
function extractItemsFromLflist(filePath) {
  const data = fs.readFileSync(filePath, 'utf8');
  const items = data.match(/^!\S+/gm); // Extraer los ítems que comienzan con "!"
  if (items) {
    combinedItems = combinedItems.concat(items); // Agregar los ítems al array global
  }
}

// Función para verificar los archivos .conf
function extractItemsFromConfFiles(confRepoPath) {
  const confFiles = fs.readdirSync(confRepoPath).filter(file => file.endsWith('.conf'));

  // Recorrer cada archivo .conf
  confFiles.forEach(file => {
    const filePath = path.join(confRepoPath, file);
    const fileData = fs.readFileSync(filePath, 'utf8');

    // Extraer los ítems que comienzan con "!"
    const fileItems = fileData.match(/^!\S+/gm);
    if (fileItems) {
      combinedItems = combinedItems.concat(fileItems); // Agregar los ítems al array global
    }
  });
}

// Función para ordenar los ítems según el objeto `banlistsOrder`
function filterAndOrderItems() {
  const orderedItems = [];

  // Iterar sobre banlistsOrder para mantener solo los ítems en ese orden
  for (const key in banlistsOrder) {
    const listName = banlistsOrder[key];

    // Buscar el ítem en la lista combinada
    const item = combinedItems.find(i => i.includes(listName));
    if (item) {
      orderedItems.push(item); // Agregar el ítem en el orden correcto
    }
  }

  return orderedItems;
}

// Función para escribir el archivo final lflist.conf
function writeFinalLflist(orderedItems) {
  const header = `# Listas Generadas según el orden establecido\n`;
  const filePath = path.join('scripts', LFLIST_FILE);

  const content = `${header}\n${orderedItems.join('\n')}`;
  fs.writeFileSync(filePath, content);
  console.log(`Archivo final lflist.conf creado y ordenado.`);
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
    execSync('git commit -m "Update lflist.conf with ordered lists"');
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

  // Extraer ítems de lflist.conf
  extractItemsFromLflist(path.join('repo-koishi', 'mobile', 'assets', 'data', 'conf', LFLIST_FILE));

  // Extraer ítems de los archivos .conf
  extractItemsFromConfFiles('comparison-repo');

  // Filtrar y ordenar los ítems
  const orderedItems = filterAndOrderItems();

  // Escribir el archivo final lflist.conf
  writeFinalLflist(orderedItems);

  // Clonar el repositorio de destino, mover el archivo y hacer push
  cloneRepo(DEST_REPO_URL, 'koishi-Iflist');
  moveAndPush();
}

main(); // Inicia el proceso



























