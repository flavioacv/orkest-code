import {test} from 'node:test';
import assert from 'node:assert/strict';
import {WORLD_BOUNDS,WALK_ROUTES,pathState,forestPoints} from './life-plan.js';
import {interactionMap} from './interaction-map.js';
import {validateCompanies} from './scene-plan.js';
import {officeArrival} from './walk-cycle.js';
test('mapa é retangular e floresta está dentro de seus limites sem troncos duplicados',()=>{
 assert.ok((WORLD_BOUNDS.x1-WORLD_BOUNDS.x0)/(WORLD_BOUNDS.z1-WORLD_BOUNDS.z0)>1.8);
 const points=forestPoints();assert.ok(points.length>=250);assert.deepEqual(points,forestPoints());
 for(const [i,p]of points.entries()){assert.ok(p.x>WORLD_BOUNDS.x0&&p.x<WORLD_BOUNDS.x1&&p.z>WORLD_BOUNDS.z0&&p.z<WORLD_BOUNDS.z1);for(const q of points.slice(i+1))assert.ok(Math.hypot(p.x-q.x,p.z-q.z)>=1.4);}
});
test('rotas de pedestres fecham sem saltos de posição',()=>{for(const points of WALK_ROUTES){const first=pathState(points,0),last=pathState(points,first.total);assert.ok(Math.hypot(first.x-last.x,first.z-last.z)<1e-8);let previous=first;for(let d=.1;d<first.total;d+=.1){const next=pathState(points,d);assert.ok(Math.hypot(next.x-previous.x,next.z-previous.z)<.100001);previous=next;}}});
test('mapa do motor oferece recepção, banheiro, café e lazer, com mesas exclusivas e elevadores conectados',()=>{
 const company=validateCompanies([{id:'a',name:'A',agentCount:17}])[0],map=interactionMap(company);
 assert.equal(map.desks.length,17);assert.equal(new Set(map.desks.map(s=>s.agentId)).size,17);assert.equal(map.portals.length,5);
 for(const kind of ['reception','stall','coffee','lounge','pingpong','arcade','playground'])assert.ok(map.places.some(p=>p.kind===kind));
 assert.equal(new Set(map.places.map(p=>p.id)).size,map.places.length);assert.ok(map.places.every(p=>p.capacity===1));
 for(const portal of map.portals)assert.equal(portal.links.length,4);
});
test('entrada fica no nível da rua e se oculta no elevador antes de chegar ao escritório',()=>{
 assert.equal(officeArrival(0).level,'ground');assert.equal(officeArrival(4).level,'ground');assert.equal(officeArrival(6).hidden,true);assert.equal(officeArrival(9).level,'office');assert.equal(officeArrival(12).phase,'working');assert.equal(officeArrival(12).hidden,false);
});
