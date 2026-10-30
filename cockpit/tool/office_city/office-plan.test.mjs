import {test} from 'node:test';
import assert from 'node:assert/strict';
import {officePlan,normalizeAgents,DESKS_PER_FLOOR,FLOOR_HEIGHT,COMMON_FLOORS} from './office-plan.js';
import {validateCompanies} from './scene-plan.js';
test('oito agentes cabem no piso; nono, décimo sétimo e sessenta e quatro geram pisos reais',()=>{
 for(const [count,floors]of [[0,3],[1,3],[8,3],[9,4],[16,4],[17,5],[64,10]]){
  const p=officePlan(count);assert.equal(p.floorCount,floors);assert.equal(p.agents.length,count);assert.equal(p.capacity,(floors-COMMON_FLOORS)*DESKS_PER_FLOOR);assert.ok(p.capacity>=count);
  assert.equal(new Set(p.agents.map(a=>`${a.floor}:${a.desk}`)).size,count);
  for(const a of p.agents){assert.ok(a.floor<floors);assert.ok(a.desk<8);assert.equal(a.y,a.floor*FLOOR_HEIGHT+.23);}
 }
 for(const count of [-1,.5,65,NaN,'8'])assert.throws(()=>officePlan(count));
});
test('crescer preserva as posições dos agentes existentes; reduzir elimina só excedentes',()=>{
 const small=officePlan(8),large=officePlan(17);assert.deepEqual(large.agents.slice(0,8),small.agents);assert.deepEqual(officePlan(9).agents,large.agents.slice(0,9));
});
test('listas reais têm contagem exata e identidade única entre empresas',()=>{
 const agents=Array.from({length:9},(_,i)=>({id:`session-${i}`,name:`Agente ${i}`}));const c=validateCompanies([{id:'p',name:'Projeto',agents}])[0];assert.equal(c.agentCount,9);assert.deepEqual(c.agents,agents);
 assert.throws(()=>validateCompanies([{id:'p',name:'P',agents:[agents[0]]},{id:'q',name:'Q',agents:[agents[0]]}]));
 assert.throws(()=>normalizeAgents({id:'p',agentCount:8,agents}));assert.throws(()=>normalizeAgents({id:'p',agents:[agents[0],agents[0]]}));
});
