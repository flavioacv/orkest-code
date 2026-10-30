import {officePlan,COMMON_FLOORS} from './office-plan.js';
/** Semantic interaction anchors for a future OrkestSim renderer adapter; not a second scheduler. */
export function interactionMap(company){
 const plan=officePlan(company.agents.length),prefix=company.id;
 const places=[
  {id:`${prefix}:reception:1`,kind:'reception',floor:0,x:-3,z:3.2,capacity:1},{id:`${prefix}:reception:2`,kind:'reception',floor:0,x:-5.5,z:2,capacity:1},
  {id:`${prefix}:bathroom:1`,kind:'stall',floor:0,x:3,z:-1,capacity:1,hiddenDuringUse:true},
  {id:`${prefix}:bathroom:2`,kind:'stall',floor:0,x:5.5,z:-1,capacity:1,hiddenDuringUse:true},
  {id:`${prefix}:coffee`,kind:'coffee',floor:1,x:-4.5,z:-3.5,capacity:1},
  ...[ -4,0,4].map((x,i)=>({id:`${prefix}:lounge:${i}`,kind:'lounge',floor:1,x,z:4,capacity:1})),
  {id:`${prefix}:pingpong:1`,kind:'pingpong',floor:1,x:3.6,z:-1.9,capacity:1},{id:`${prefix}:pingpong:2`,kind:'pingpong',floor:1,x:3.6,z:-5.1,capacity:1},
  {id:`${prefix}:arcade`,kind:'arcade',floor:1,x:5.7,z:-.8,capacity:1},
  {id:'city:playground:swing:1',kind:'playground',outside:true,x:68,z:-8,capacity:1},{id:'city:playground:swing:2',kind:'playground',outside:true,x:70,z:-8,capacity:1},{id:'city:playground:slide',kind:'playground',outside:true,x:70,z:-2,capacity:1},
 ];
 const desks=plan.agents.map(a=>({id:`${prefix}:desk:${a.floor}:${a.desk}`,kind:'desk',floor:a.floor,x:a.x,z:a.z,capacity:1,agentId:company.agents[a.index].id}));
 const portals=Array.from({length:plan.floorCount},(_,floor)=>({id:`${prefix}:lift:${floor}`,kind:'elevator',floor,x:6.35,z:4.7,links:Array.from({length:plan.floorCount},(_,i)=>i).filter(i=>i!==floor)}));
 return{companyId:company.id,commonFloors:COMMON_FLOORS,places,desks,portals,authority:'OrkestSim owns status, activity choice and reservations; these are renderer anchors only.'};
}
