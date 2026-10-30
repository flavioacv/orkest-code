import {createServer} from 'node:http';
import {readFile,realpath,stat} from 'node:fs/promises';
import {resolve,extname,sep} from 'node:path';
import {fileURLToPath} from 'node:url';
const root=await realpath(fileURLToPath(new URL('.',import.meta.url)));
const allowed=new Set(['/index.html','/main.js','/catalog-assets.js','/walk-cycle.js','/style.css','/generated/inventory.json','/generated/orkest.css']);
const types={'.html':'text/html; charset=utf-8','.js':'text/javascript; charset=utf-8','.css':'text/css; charset=utf-8','.json':'application/json; charset=utf-8'};
export function localPath(url){const pathname=decodeURIComponent(new URL(url,'http://localhost').pathname);const name=pathname.startsWith('/study/')?'/generated'+pathname:pathname==='/__orkest__/orkest.css'?'/generated/orkest.css':pathname==='/'?'/index.html':pathname==='/generated/study/'?'/generated/study/index.html':pathname;if(!allowed.has(name)&&!['/generated/src/','/generated/study/','/generated/three/'].some(prefix=>name.startsWith(prefix)))return null;const path=resolve(root,'.'+name);return path.startsWith(root+sep)?path:null;}
if(process.argv[1]===fileURLToPath(import.meta.url)){
 const server=createServer(async(req,res)=>{try{if(!['GET','HEAD'].includes(req.method)){res.writeHead(405).end();return;}const candidate=localPath(req.url);if(!candidate){res.writeHead(404).end();return;}const path=await realpath(candidate);if(!path.startsWith(root+sep)||!(await stat(path)).isFile()){res.writeHead(404).end();return;}const data=await readFile(path);res.writeHead(200,{'Content-Type':types[extname(path)]||'application/octet-stream','Cache-Control':'no-store','X-Content-Type-Options':'nosniff'});res.end(req.method==='HEAD'?undefined:data);}catch{res.writeHead(404).end();}});
 server.on('error',e=>{console.error(e.message);process.exitCode=1;});server.listen(Number(process.env.PORT||4175),'127.0.0.1',()=>console.log('Office City: http://127.0.0.1:'+server.address().port));
}
