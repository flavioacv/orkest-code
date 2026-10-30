import {readdir,readFile} from 'node:fs/promises';
import {relative,resolve} from 'node:path';
import {createHash} from 'node:crypto';
/** Index existing PNGs without copying or changing the original art collection. */
export async function pixelInventory(root){
 const paths=[];
 async function walk(dir){for(const item of await readdir(dir,{withFileTypes:true})){const path=resolve(dir,item.name);if(item.isDirectory())await walk(path);else if(item.isFile()&&item.name.toLowerCase().endsWith('.png'))paths.push(path);}}
 await walk(root);paths.sort();const byHash=new Map();
 // Bounded batches keep file descriptors and temporary buffers small.
 for(let start=0;start<paths.length;start+=16){const batch=await Promise.all(paths.slice(start,start+16).map(async path=>{const data=await readFile(path);if(data.length<24||!data.subarray(0,8).equals(Buffer.from([137,80,78,71,13,10,26,10])))throw Error('PNG inválido: '+path);const source=relative(root,path);return{source,sha256:createHash('sha256').update(data).digest('hex'),bytes:data.length,width:data.readUInt32BE(16),height:data.readUInt32BE(20)};}));
  for(const item of batch){if(byHash.has(item.sha256)){byHash.get(item.sha256).aliases.push(item.source);continue;}byHash.set(item.sha256,{id:'pixel:'+item.sha256,name:item.source.split('/').at(-1).replace(/_[^_]+_[^_]+\.png$/i,'').replace(/\.png$/i,''),kind:'pixel-art',source:'assets/sprites/'+item.source,url:'/pixel-art/'+item.source.split('/').map(encodeURIComponent).join('/'),aliases:[item.source],sha256:item.sha256,bytes:item.bytes,width:item.width,height:item.height,available:true,usage:'Referência e sprite 2D; não é malha 3D',license:'preservada do acervo existente; sem nova atribuição'});}}
 return{files:paths.length,unique:byHash.size,duplicates:paths.length-byHash.size,entries:[...byHash.values()]};
}
