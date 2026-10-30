/** Authored lots, metres; roads occupy the corridors between them. */
export const LOTS=[
 {id:'company-1',label:'Orkest · sede',kind:'company',x:-20,z:-24,w:16,d:18},
 {id:'company-2',label:'Expansão de empresas',kind:'company',x:0,z:-24,w:16,d:18},
 {id:'company-3',label:'Expansão de empresas',kind:'company',x:20,z:-24,w:16,d:18},
 {id:'garden',label:'Praça das ideias',kind:'garden',x:-20,z:0,w:16,d:18},
 {id:'cafe',label:'Café do bairro',kind:'cafe',x:0,z:0,w:16,d:18},
 {id:'library',label:'Biblioteca & galeria',kind:'library',x:20,z:0,w:16,d:18},
 {id:'residence',label:'Vila residencial',kind:'residence',x:-20,z:24,w:16,d:18},
 {id:'market',label:'Mercado & bicicletas',kind:'market',x:0,z:24,w:16,d:18},
 {id:'construction',label:'Ateliê em construção',kind:'construction',x:20,z:24,w:16,d:18},
];
export const STATIONS=[[-4,1],[-.8,-3],[-4,-3],[-.8,1]];
export const COMPANY_SLOTS=LOTS.filter(l=>l.kind==='company');
/** Semantic appearances use the same palette and part names as Habblaud pixel art. */
export const PROFILES=[
 {id:'ana',name:'Ana',hairStyle:'bob',hair:'#8e3b2b',skin:'#f6cfb0',top:'#36b0b0',bottom:'#2e3e5e',accessory:'glasses',look:'f'},
 {id:'leo',name:'Léo',hairStyle:'curly',hair:'#2b2530',skin:'#9a6444',top:'#efb54a',bottom:'#3f5f8c',accessory:'headphones',look:'m'},
 {id:'maya',name:'Maya',hairStyle:'bun',hair:'#3f2c22',skin:'#bd8560',top:'#8d66cf',bottom:'#2c2c35',accessory:'earrings',look:'f'},
 {id:'rui',name:'Rui',hairStyle:'side_part',hair:'#8f929b',skin:'#eab894',top:'#2f4c7d',bottom:'#b49c72',accessory:'glasses',look:'m'},
 {id:'bia',name:'Bia',hairStyle:'ponytail',hair:'#d6ae68',skin:'#ffe2cc',top:'#e2604f',bottom:'#3f5f8c',accessory:'none',look:'f'},
 {id:'ivo',name:'Ivo',hairStyle:'spiky',hair:'#3fb3a0',skin:'#d69f78',top:'#4a86d8',bottom:'#2c2c35',accessory:'none',look:'m'},
 {id:'sol',name:'Sol',hairStyle:'afro',hair:'#5f3c28',skin:'#5a3623',top:'#4bab72',bottom:'#e2ded5',accessory:'earrings',look:'f'},
 {id:'tom',name:'Tom',hairStyle:'buzz',hair:'#87593a',skin:'#7a4a31',top:'#c9713f',bottom:'#5f6845',accessory:'cap',look:'m'},
];
/** One placement per named catalogue prop; workstation kits are authored separately. */
export const CATALOG_PROPS=[
 {id:'meeting-table',source:'y4_table_sh',height:.78,zone:'company-1',x:3.8,z:-3.5},
 {id:'reading-chair',source:'y4_luxchair_eu',height:1.1,zone:'library',x:3,z:4},
 {id:'sheltered-seat',source:'y4_sofa_cp',height:1.3,zone:'garden',x:3.5,z:3.5},
 {id:'entry-planter',source:'y4_planter_mp',height:.85,zone:'company-1',x:5.8,z:5},
 {id:'reading-light',source:'y4_lamp_mp',height:2.1,zone:'library',x:4.5,z:3},
 {id:'park-bench',source:'y4_bench_mp',height:.95,zone:'garden',x:-4,z:3},
 {id:'pergola',source:'y4_pergola_sh',height:3,zone:'garden',x:2,z:-3},
 {id:'bicycle-rack',source:'y4_bikerack_mp',height:1,zone:'market',x:-4,z:5.8},
 {id:'cafe-terrace',source:'y4_cafe_mp',height:2.2,zone:'cafe',x:0,z:3.5},
];
export function validateCompanies(input){
 if(!Array.isArray(input)||input.length>COMPANY_SLOTS.length)throw Error('Informe até três empresas.');
 const ids=new Set();return input.map(c=>{if(!c||typeof c.id!=='string'||!c.id.trim()||ids.has(c.id)||typeof c.name!=='string'||!c.name.trim()||c.name.length>64)throw Error('Empresa inválida ou repetida.');ids.add(c.id);return{id:c.id,name:c.name.trim()};});
}
/** Constant-speed continuous closed road, rounded corners. Coordinates never enter lots. */
export function trafficState(distance,{halfX=30,halfZ=34,radius=5}={}){
 const horizontal=2*(halfX-radius),vertical=2*(halfZ-radius),arc=Math.PI*radius/2;
 const lengths=[horizontal,arc,vertical,arc,horizontal,arc,vertical,arc],total=lengths.reduce((a,b)=>a+b,0);
 let d=((distance%total)+total)%total;
 for(let i=0;i<8;i++){
  if(d<=lengths[i]){
   if(i===0)return{x:-halfX+radius+d,z:-halfZ,yaw:Math.PI/2,total};
   if(i===2)return{x:halfX,z:-halfZ+radius+d,yaw:0,total};
   if(i===4)return{x:halfX-radius-d,z:halfZ,yaw:-Math.PI/2,total};
   if(i===6)return{x:-halfX,z:halfZ-radius-d,yaw:Math.PI,total};
   const start=({1:-Math.PI/2,3:0,5:Math.PI/2,7:Math.PI})[i],a=start+d/radius;
   const cx=i===1||i===3?halfX-radius:-halfX+radius,cz=i===1||i===7?-halfZ+radius:halfZ-radius;
   return{x:cx+Math.cos(a)*radius,z:cz+Math.sin(a)*radius,yaw:Math.atan2(-Math.sin(a),Math.cos(a)),total};
  }d-=lengths[i];
 }
}
