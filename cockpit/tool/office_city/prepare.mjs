import {readdir,readFile,mkdir,cp,writeFile} from 'node:fs/promises';
import {resolve,relative,extname} from 'node:path';
import {createHash} from 'node:crypto';
import {fileURLToPath} from 'node:url';
const root=fileURLToPath(new URL('.',import.meta.url));
const source=resolve(process.argv[2]||resolve(root,'../../../../city-copy'));
const output=resolve(root,'generated');
const files=[];
async function walk(dir){for(const item of await readdir(dir,{withFileTypes:true})){if(['node_modules','.git'].includes(item.name))continue;const path=resolve(dir,item.name);if(item.isDirectory())await walk(path);else if(item.isFile()){const data=await readFile(path);files.push({path:relative(source,path),bytes:data.length,sha256:createHash('sha256').update(data).digest('hex'),kind:classify(relative(source,path))});}}}
function classify(path){if(path.startsWith('study/vendor/'))return 'capturado: licença não determinada';if(path.startsWith('study/'))return 'laboratório e procedência';if(path.startsWith('src/'))return 'implementação própria';if(path.startsWith('reference/'))return 'evidência, não modelo';if(path.startsWith('third-party/'))return 'licença';return 'documentação ou ferramenta';}
await walk(source);await mkdir(output,{recursive:true});
for(const name of ['src','study','third-party'])await cp(resolve(source,name),resolve(output,name),{recursive:true});
await mkdir(resolve(output,'three'),{recursive:true});
for(const name of ['build','examples/jsm','LICENSE'])await cp(resolve(source,'node_modules/three',name),resolve(output,'three',name),{recursive:true});
const manifest={source,generatedAt:new Date().toISOString(),files:files.sort((a,b)=>a.path.localeCompare(b.path)),notes:['third-party contém licença, não modelos','reference e evidências JSON não são malhas prontas','Três poses não equivalem a animações de escritório','Pacotes binários de veículos e prédios remotos continuam ausentes']};
await writeFile(resolve(output,'inventory.json'),JSON.stringify(manifest,null,2));
console.log(`Preparado: ${files.length} arquivos inventariados; fontes preservadas em ${source}`);

await cp(resolve(root,'../../assets/panel/lib/orkest.css'),resolve(output,'orkest.css'));
