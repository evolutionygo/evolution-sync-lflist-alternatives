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

// Función para leer el archivo lflist.conf y devolver las listas con su contenido
function readLflistWithContent(filePath) {
  const data = fs.readFileSync(filePath, 'utf8');
  const lines = data.split('\n');
  const listsWithContent = {};
  let currentList = null;

  lines.forEach((line) => {
    if (line.startsWith('!')) {
      currentList = line; // Iniciar una nueva lista
      listsWithContent[currentList] = []; // Crear un array para su contenido
    } else if (currentList && line.trim() !== '') {
      // Añadir contenido a la lista actual
      listsWithContent[currentList].push(line);
    }
  });

  return listsWithContent;
}

// Función para recorrer los archivos .conf en el repositorio de comparación y devolver las listas con su contenido
function readConfFilesWithContent(confRepoPath) {
  const confFiles = fs.readdirSync(confRepoPath).filter(file => file.endsWith('.conf'));
  let listsWithContent = {};

  confFiles.forEach(file => {
    const filePath = path.join(confRepoPath, file);
    const fileData = fs.readFileSync(filePath, 'utf8');
    const lines = fileData.split('\n');
    let currentList = null;

    lines.forEach((line) => {
      if (line.startsWith('!')) {
        currentList = line; // Iniciar una nueva lista
        listsWithContent[currentList] = []; // Crear un array para su contenido
      } else if (currentList && line.trim() !== '') {
        // Añadir contenido a la lista actual
        listsWithContent[currentList].push(line);
      }
    });
  });

  return listsWithContent;
}

// Función para combinar y ordenar listas según el orden establecido en banlistsOrder
function combineAndOrderLists(lflistContent, confContent, banlistsOrder) {
  let finalLists = [];

  // Recorrer el orden especificado en banlistsOrder y añadir las listas que existan
  Object.values(banlistsOrder).forEach(listName => {
    const listKey = `!${listName}`;
    if (lflistContent[listKey]) {
      finalLists.push({ name: listKey, content: filterListContent(lflistContent[listKey]) });
    } else if (confContent[listKey]) {
      finalLists.push({ name: listKey, content: filterListContent(confContent[listKey]) });
    }
  });

  return finalLists;
}

// Función para filtrar los ítems que contienen solo " 0", " 1" o " 2" y eliminar los demás
// Además, eliminar los ítems que contienen " 3" seguido de cualquier texto adicional
function filterListContent(items) {
  return items.filter(item => {
    // Coincidir con un espacio seguido de "0", "1" o "2" (permitidos)
    // Y eliminar los que contienen un " 3" seguido de cualquier otro texto
    const match = item.match(/\s[012]\b/);
    const hasThree = item.match(/\s3\b/); // Identificar ítems con " 3"
    
    return match && !hasThree; // Incluir solo si es " 0", " 1" o " 2" y no tiene " 3"
  });
}


// Función para generar la segunda línea con los ítems del objeto `banlistsOrder`
function generateSecondLineFromBanlistsOrder() {
  const items = Object.values(banlistsOrder).map(item => `[${item}]`).join('');
  return `#${items}`;
}

// Función para escribir el archivo final lflist.conf con la lista del objeto `banlistsOrder`
function writeFinalLflist(finalLists) {
  const filePath = path.join('scripts', LFLIST_FILE);
  let fileContent = '# Listas Generadas según el orden establecido\n';

  // Generar la segunda línea con los ítems en el orden del objeto
  const secondLine = generateSecondLineFromBanlistsOrder();
  fileContent += secondLine + '\n';

  // Añadir las listas en el mismo orden del objeto
  finalLists.forEach(list => {
    fileContent += `${list.name}\n`;
    list.content.forEach(line => {
      fileContent += `${line}\n`;
    });
  });

  fs.writeFileSync(filePath, fileContent);
  console.log(`Archivo final lflist.conf creado con las listas ordenadas y segunda línea generada: ${secondLine}`);
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

  // Leer el archivo lflist.conf con su contenido
  const lflistContent = readLflistWithContent(path.join('repo-koishi', 'mobile', 'assets', 'data', 'conf', LFLIST_FILE));

  // Leer los archivos .conf con su contenido
  const confContent = readConfFilesWithContent('comparison-repo');

  // Combinar y ordenar las listas
  const finalLists = combineAndOrderLists(lflistContent, confContent, banlistsOrder);

  // Escribir el archivo final lflist.conf
  writeFinalLflist(finalLists);

  // Clonar el repositorio de destino, mover el archivo y hacer push
  cloneRepo(DEST_REPO_URL, 'koishi-Iflist');
  moveAndPush();
}

main(); // Inicia el proceso



































