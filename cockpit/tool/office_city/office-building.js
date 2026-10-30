import * as THREE from 'three';
import {officePlan,FLOOR_HEIGHT,OFFICE_STATIONS,COMMON_FLOORS} from './office-plan.js';
/** Every visible storey corresponds to an actual furnished floor, not decorative extra boxes. */
export function buildOffice({company,index,lot,root,box,cylinder,sign,workstation,view}){
 const plan=officePlan(company.agents.length),group=new THREE.Group();group.position.set(lot.x,.1,lot.z);root.add(group);
 const themes=[{wall:'#c3b1a0',trim:'#ede3cd',accent:'#4f7881'},{wall:'#b17460',trim:'#e5cdb3',accent:'#665b53'},{wall:'#b6c2b9',trim:'#eee4cd',accent:'#527b6b'}],theme=themes[index];
 const exterior=new THREE.Group();group.add(exterior);const floors=[];
 function window(parent,x,y,z,w,h,side=false){
  if(!side){box(parent,'#7c9fa3',x,y,z,w,h,.065);box(parent,theme.trim,x,y+h/2+.06,z+.03,w+.18,.11,.11);box(parent,theme.trim,x,y-h/2-.05,z+.1,w+.25,.14,.25);box(parent,theme.trim,x,y,z+.07,.06,h,.05);}
  else{box(parent,'#7c9fa3',x,y,z,.065,h,w);box(parent,theme.trim,x+.05,y-h/2-.06,z,.22,.14,w+.2);box(parent,theme.trim,x+.05,y,z,.05,h,.06);}
 }
 for(let level=0;level<plan.floorCount;level++){
  const inner=new THREE.Group(),shell=new THREE.Group();inner.position.y=shell.position.y=level*FLOOR_HEIGHT;group.add(inner,shell);
  box(inner,'#dbd2bc',0,.12,0,14,.18,12);box(inner,theme.wall,0,1.8,-6,14,3.6,.2);box(inner,theme.wall,-7,1.8,0,.2,3.6,12);
  box(shell,theme.wall,7,1.8,0,.2,3.6,12);box(shell,theme.wall,0,1.8,6,14,3.6,.2);
  for(const x of [-5.3,-2.65,0,2.65,5.3])window(shell,x,2.15,6.13,1.65,1.65);
  for(const z of [-4,-.8,2.5])window(shell,7.13,2.15,z,1.7,1.65,true);
  for(const y of [.35,3.55]){box(shell,theme.trim,0,y,6.16,14.3,.17,.26);box(shell,theme.trim,7.16,y,0,.26,.17,12.3);}
  for(const x of [-6.85,6.85])box(shell,theme.trim,x,1.85,6.2,.22,3.6,.28);
  if(level===0){box(shell,'#3e5b61',0,1.12,6.23,1.4,2.25,.09);box(shell,'#d3c4a4',0,.13,6.55,2.1,.12,.9);sign(shell,company.name,0,3.05,6.35,6,theme.accent);box(shell,theme.accent,0,2.67,6.75,6.5,.12,1.4);}
  else for(const x of [-4.8,4.8]){box(shell,theme.trim,x,.22,6.45,2.3,.18,1);for(const dx of [-1,0,1])box(shell,'#596964',x+dx,.7,6.9,.05,.85,.06);box(shell,'#596964',x,1.1,6.9,2.2,.06,.06);}
  // A subtle wall pattern makes the brick/stone facades read at street scale.
  for(let course=0;course<8;course++){const y=.4+course*.4;for(const x of [-6,-3.9,-1.3,1.3,3.9,6]){box(shell,index===1?'#9f6657':'#b1aaa0',x+(course%2)*.12,y,6.115,.6,.025,.015);}}
  if(level>=COMMON_FLOORS){
  box(inner,level%2?'#c8d2ce':'#b8c8ca',0,.23,-.4,12.2,.035,9.7);
  OFFICE_STATIONS.forEach(([x,z],i)=>workstation(inner,x,z,i));
  // Shelving and the reception nook stay out of the front circulation aisle.
  box(inner,'#a58c70',-3.5,.9,-5.55,4.3,1.4,.52);for(const y of [.4,.95,1.5])box(inner,'#d2b28c',-3.5,y,-5.23,4.3,.08,.05);
  for(let i=0;i<17;i++)box(inner,['#8b6862','#688e90','#c7aa68','#8c869f'][i%4],-5.4+i*.23,1.2,-5.23,.16,.4,.16);
  box(inner,'#53616a',-6.25,1,-3.4,.7,1.8,.65);for(let i=0;i<5;i++)box(inner,'#92b3b1',-6.25,.5+i*.25,-3.06,.48,.08,.03);
  box(inner,'#8b9fa1',4.5,.55,4.65,2.8,.65,.85);box(inner,'#8b9fa1',4.5,1,5,2.8,1,.15);box(inner,'#a88967',2.5,.7,5,.65,1.2,.6);box(inner,'#4d5f65',2.5,1.43,5,.5,.4,.4);
  sign(inner,`${level-COMMON_FLOORS+1}º ANDAR DE TRABALHO / ${company.name}`,1.8,2.55,-5.86,5,theme.accent);
  }else if(level===0){
   box(inner,'#c9b9a1',0,.23,0,13,.035,11);box(inner,'#5e8585',-3,.95,2,4.5,1.4,1.2);box(inner,'#d9bc8c',-3,1.7,2,4.8,.14,1.4);sign(inner,'RECEPÇÃO',-3,2.4,-5.86,4,theme.accent);
   for(const x of [-4,-1.5,1]){box(inner,'#889f99',x,.55,-2,.9,.65,.8);box(inner,'#889f99',x,1,-2.4,.9,1,.13);}
   box(inner,'#c4c4b4',4.3,1.3,-3,4.8,2.4,4);for(const x of [3,5.5]){box(inner,'#6d8f8d',x,1,-.94,1.35,2,.08);sign(inner,'WC',x,2.2,-.88,.7,theme.accent);}sign(inner,company.name,0,2.9,-5.86,5,theme.accent);
   box(inner,'#778b88',5.8,1.25,4.8,1.6,2.4,.3);sign(inner,'ELEVADOR',5.8,2.7,5,1.8,theme.accent);
  }else{
   box(inner,'#d7c4a7',0,.23,0,13,.035,11);sign(inner,'CAFETERIA / CONVÍVIO',0,2.6,-5.86,6,theme.accent);
   box(inner,'#997b5b',-4.5,.75,-4,3.5,1.2,.8);for(const x of [-5.5,-3.5])box(inner,'#465b60',x,1.6,-4,.6,.7,.5);
   for(const x of [-3,1]){box(inner,'#c6a57b',x,.9,0,2.6,.15,1.5);for(const dz of [-1,1])box(inner,'#7c9493',x,.5,dz,2.3,.2,.55);}
   box(inner,'#688e81',3.6,.9,-3.5,3.8,.15,2.1);box(inner,'#ebe5d5',3.6,1.13,-3.5,.035,.4,2.1);
   for(const x of [-4,0,4]){box(inner,'#8b9fa1',x,.55,4,2.6,.65,.9);box(inner,'#8b9fa1',x,1,4.4,2.6,1,.15);}
   box(inner,'#657b82',5.7,1,-.8,1,1.8,1);box(inner,'#8ab1b0',5.7,1.4,-.22,.75,.7,.05);
  }
  if(level<plan.floorCount-1){
   for(let step=0;step<16;step++)box(inner,'#b6b2a4',6.35,.23+(step+1)*FLOOR_HEIGHT/16,4.7-step*.31,.8,.12,.32);
   box(inner,'#6c7d7c',6.85,2.1,2.25,.05,2.8,5.1);
  }
  floors.push({inner,exterior:shell,level,label:level===0?'Recepção & banheiro':level===1?'Cafeteria & convívio':`${level-COMMON_FLOORS+1}º escritório`,occupants:plan.agents.filter(a=>a.floor===level).length});
 }
 const roofY=plan.height;
 box(exterior,theme.accent,0,roofY+.12,0,14.5,.28,12.5);box(exterior,theme.trim,0,roofY+.4,6.15,14.5,.5,.24);box(exterior,theme.trim,7.15,roofY+.4,0,.24,.5,12.5);
 for(let i=0;i<=index;i++){const solar=box(exterior,'#48636d',-3+i*2.2,roofY+.42,-2,1.8,.12,2.7);solar.rotation.x=-.15;}
 box(exterior,'#b1b5ae',4.7,roofY+.5,-3,1.5,.8,1.8);cylinder(exterior,'#7d8a89',4.7,roofY+1.05,-3,.45,.3,12);
 if(index===1){cylinder(exterior,'#a49a82',-4.5,roofY+1.6,-3,1.1,2,16);for(const dx of [-.8,.8])box(exterior,'#5d6565',-4.5+dx,roofY+.7,-3,.08,1.2,.08);}
 if(index===2){const skylight=box(exterior,'#91b8b4',1.5,roofY+.6,0,3,.6,4);skylight.rotation.z=.12;}
 const pick=box(exterior,theme.wall,0,roofY/2,0,14,roofY,12);pick.material=new THREE.MeshBasicMaterial({visible:false});pick.userData.companyId=company.id;
 function setView(near,selected=0){const active=Math.max(0,Math.min(floors.length-1,selected));exterior.visible=!near;for(const floor of floors){floor.inner.visible=near&&floor.level===active;floor.exterior.visible=!near||floor.level<active;}return active;}
 setView(false);
 return {group,exterior,inner:floors[0].inner,pick,lot,company,stations:OFFICE_STATIONS,floors,plan,height:plan.height,setView};
}
