import {test} from 'node:test';
import assert from 'node:assert/strict';
import {localPath} from './server.mjs';
import {readFile} from 'node:fs/promises';
import {createHash} from 'node:crypto';
test('servidor restringe arquivos e travessia de diretórios',()=>{for(const path of ['/prepare.mjs','/.git/config','/generated/study/../../server.mjs','/%2e%2e/server.mjs'])assert.equal(localPath(path),null);assert.ok(localPath('/generated/study/vendor/people-Bo_XNOUZ.js'));});
test('cópias próprias e módulos capturados preservam bytes do inventário',async()=>{const inventory=JSON.parse(await readFile(new URL('./generated/inventory.json',import.meta.url)));const entries=inventory.files.filter(f=>f.path.startsWith('src/')||f.path.startsWith('study/'));assert.ok(entries.length>100);for(const entry of entries){const bytes=await readFile(new URL('./generated/'+entry.path,import.meta.url));assert.equal(createHash('sha256').update(bytes).digest('hex'),entry.sha256,entry.path);}});
