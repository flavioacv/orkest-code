import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {LOTS,PROFILES,CATALOG_PROPS,STATIONS,trafficState,validateCompanies} from './scene-plan.js';
import {characterState,WALK_SECONDS} from './walk-cycle.js';
import {unifiedAssets} from './asset-registry.js';
test('lotes distintos preservam corredores de ruas e não se sobrepõem',()=>{
 assert.equal(new Set(LOTS.map(l=>l.id)).size,9);
 for(const [i,a]of LOTS.entries())for(const b of LOTS.slice(i+1))assert.ok(Math.abs(a.x-b.x)>=(a.w+b.w)/2||Math.abs(a.z-b.z)>=(a.d+b.d)/2);
 for(const lot of LOTS){for(const x of [-10,10])assert.ok(Math.abs(lot.x-x)>=lot.w/2+2);for(const z of [-12,12])assert.ok(Math.abs(lot.z-z)>=lot.d/2+2);}
});
test('tráfego mantém continuidade e sentido nas curvas e no fechamento do circuito',()=>{
 const total=trafficState(0).total;let previous=trafficState(0);
 for(let d=.01;d<total+.01;d+=.01){const s=trafficState(d);assert.ok(Math.hypot(s.x-previous.x,s.z-previous.z)<.01001);assert.ok(Math.abs(s.x)<=30.00001&&Math.abs(s.z)<=34.00001);assert.ok(Math.abs(s.x)>27||Math.abs(s.z)>31);previous=s;}
 const end=trafficState(total);assert.ok(Math.hypot(end.x-trafficState(0).x,end.z-trafficState(0).z)<1e-8);
});
test('empresas validam identidade, capacidade e nomes sem aceitar duplicatas',()=>{
 const c=validateCompanies([{id:'a',name:' A '}])[0];assert.equal(c.name,'A');assert.equal(c.agentCount,8);assert.equal(c.agents.length,8);
 for(const input of [null,[{id:'a',name:''}],[{id:'a',name:'A'},{id:'a',name:'B'}],Array.from({length:4},(_,i)=>({id:String(i),name:'A'}))])assert.throws(()=>validateCompanies(input));
});
test('catálogo unificado é único, props existem e aparências diferem em geometria e paleta',async()=>{
 const catalog=JSON.parse(await readFile(new URL('./generated/study/catalog.json',import.meta.url)));
 const registry=unifiedAssets(catalog);assert.equal(new Set(registry.entries.map(e=>e.id)).size,registry.entries.length);
 assert.equal(new Set(CATALOG_PROPS.map(p=>p.source)).size,CATALOG_PROPS.length);
 for(const p of CATALOG_PROPS)assert.ok(catalog.items.some(i=>i.id===p.source));
 assert.equal(new Set(PROFILES.map(p=>p.hairStyle)).size,8);assert.equal(new Set(PROFILES.map(p=>p.skin)).size,8);
 const palettes=await readFile(new URL('../../third_party/office_engine/shared/world/appearance-flat.ts',import.meta.url),'utf8');
 const types=await readFile(new URL('../../third_party/office_engine/shared/appearance.ts',import.meta.url),'utf8');
 for(const p of PROFILES){for(const color of [p.skin,p.hair,p.top,p.bottom])assert.ok(palettes.includes(color));assert.ok(types.includes("'"+p.hairStyle+"'"));}
});

test('estações não duplicam ocupantes e percurso não atravessa tampos',()=>{
 assert.equal(new Set(STATIONS.map(p=>p.join(':'))).size,8);
 const end=characterState(WALK_SECONDS);assert.ok(Math.abs(end.x-STATIONS[0][0])<1e-8);assert.ok(Math.abs(end.z-STATIONS[0][1]-1.05)<1e-8);
 for(let t=0;t<WALK_SECONDS;t+=.02){const p=characterState(t);for(const [x,z]of STATIONS)assert.ok(Math.abs(p.x-x)>1.075+.15||Math.abs(p.z-z)>.5+.15);}
});
