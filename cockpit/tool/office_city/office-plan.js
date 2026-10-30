/** Prototype layout: eight desks per floor, with a continuous front/central aisle. */
export const DESKS_PER_FLOOR=8;
export const COMMON_FLOORS=2;
export const FLOOR_HEIGHT=3.8;
export const MAX_AGENTS=64;
export const OFFICE_STATIONS=[[-4.8,1],[-1.6,1],[1.6,1],[4.8,1],[-4.8,-3],[-1.6,-3],[1.6,-3],[4.8,-3]];
/** Allocates every agent once; extra floors are built only when seats run out. */
export function officePlan(agentCount){
 if(!Number.isInteger(agentCount)||agentCount<0||agentCount>MAX_AGENTS)throw Error(`Informe de 0 a ${MAX_AGENTS} agentes neste protótipo.`);
 const officeFloorCount=Math.max(1,Math.ceil(agentCount/DESKS_PER_FLOOR)),floorCount=COMMON_FLOORS+officeFloorCount;
 const agents=Array.from({length:agentCount},(_,index)=>{const floor=COMMON_FLOORS+Math.floor(index/DESKS_PER_FLOOR),desk=index%DESKS_PER_FLOOR,[x,z]=OFFICE_STATIONS[desk];return{index,floor,desk,x,y:floor*FLOOR_HEIGHT+.23,z:z+1.05};});
 return{agentCount,officeFloorCount,floorCount,capacity:officeFloorCount*DESKS_PER_FLOOR,height:floorCount*FLOOR_HEIGHT,agents};
}
export function normalizeAgents(company){
 if(company.agents!==undefined){
  if(!Array.isArray(company.agents))throw Error('A equipe deve ser uma lista de agentes.');
  officePlan(company.agents.length);if(company.agentCount!==undefined&&company.agentCount!==company.agents.length)throw Error('Contagem de agentes diverge da lista recebida.');const ids=new Set();
  return company.agents.map(agent=>{if(!agent||typeof agent.id!=='string'||!agent.id.trim()||ids.has(agent.id)||typeof agent.name!=='string'||!agent.name.trim()||agent.name.length>64)throw Error('Agente inválido ou repetido na empresa.');ids.add(agent.id);return{id:agent.id,name:agent.name.trim()};});
 }
 const count=company.agentCount===undefined?8:company.agentCount;officePlan(count);
 const names=['Ana','Léo','Maya','Rui','Bia','Ivo','Sol','Tom'];
 return Array.from({length:count},(_,i)=>({id:`${company.id}:agent:${i+1}`,name:i<8?names[i]:`${names[i%8]} ${Math.floor(i/8)+1}`}));
}
