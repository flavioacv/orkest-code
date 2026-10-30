import * as THREE from 'three';
import {urbanBuilding} from './urban-building.js';
import {buildOffice} from './office-building.js';
import {LOTS,CATALOG_PROPS,STATIONS} from './scene-plan.js';
/** Creates one authored neighbourhood; no seeded/random building scatter. */
export function buildDistrict(view,assets){
 view.base.visible=false;view.city.visible=false;view.grid.visible=false;
 view.scene.background.set('#c9c7bb');view.scene.fog.near=350;view.scene.fog.far=700;
 view.setInk(.58);view.setPaper(true);view.renderer.setPixelRatio(Math.min(devicePixelRatio,1.5));
 const root=new THREE.Group();view.scene.add(root);const interactables=[],labels=[],buildings=new Map(),companyGroups=new Map();
 function box(parent,color,x,y,z,w,h,d){const m=new THREE.Mesh(new THREE.BoxGeometry(w,h,d),view.material(color));m.position.set(x,y,z);m.castShadow=h>.2;m.receiveShadow=true;parent.add(m);return m;}
 function cylinder(parent,color,x,y,z,r,h,sides=12){const m=new THREE.Mesh(new THREE.CylinderGeometry(r,r,h,sides),view.material(color));m.position.set(x,y,z);m.castShadow=true;m.receiveShadow=true;parent.add(m);return m;}
 function sign(parent,text,x,y,z,width=4,color='#324f51'){
  const canvas=document.createElement('canvas');canvas.width=512;canvas.height=96;const c=canvas.getContext('2d');c.fillStyle=color;c.fillRect(0,0,512,96);c.font='600 40px sans-serif';c.fillStyle='#fff9e9';c.textAlign='center';c.fillText(text,256,63,486);
  const texture=new THREE.CanvasTexture(canvas);texture.colorSpace=THREE.SRGBColorSpace;const m=new THREE.Mesh(new THREE.PlaneGeometry(width,width*96/512),new THREE.MeshBasicMaterial({map:texture}));m.position.set(x,y,z);parent.add(m);labels.push(texture);return m;
 }
 function stamp(id,height,parent,x,z,rotation=0){const m=assets.stamp(id,height);m.position.set(x,.16,z);m.rotation.y=rotation;parent.add(m);return m;}
 function tree(x,z,type=0,scale=1){const g=new THREE.Group();g.position.set(x,.08,z);g.scale.setScalar(scale);root.add(g);cylinder(g,'#8d6e4c',0,.95,0,.14,1.9,7);const crown=new THREE.Mesh(type?new THREE.ConeGeometry(1,2.9,7):new THREE.IcosahedronGeometry(1.1,1),view.material(type?'#697f62':'#7c966a'));crown.position.y=type?2.8:2.4;g.add(crown);return g;}
 // A single continuous ground plane; the lots are semantic, not painted squares.
 box(root,'#a4b18c',40,-.5,0,220,1,116);box(root,'#a4b18c',40,.025,0,218,.12,114);
 function rounded(shape,x0,z0,x1,z1,r){shape.moveTo(x0+r,z0);shape.lineTo(x1-r,z0);shape.quadraticCurveTo(x1,z0,x1,z0+r);shape.lineTo(x1,z1-r);shape.quadraticCurveTo(x1,z1,x1-r,z1);shape.lineTo(x0+r,z1);shape.quadraticCurveTo(x0,z1,x0,z1-r);shape.lineTo(x0,z0+r);shape.quadraticCurveTo(x0,z0,x0+r,z0);}
 const sidewalk=new THREE.Shape();rounded(sidewalk,-33,-37,33,37,8);const sidewalkHole=new THREE.Path();rounded(sidewalkHole,-27,-31,27,31,2);sidewalk.holes.push(sidewalkHole);const walk=new THREE.Mesh(new THREE.ShapeGeometry(sidewalk,20),view.material('#d0c9b9'));walk.rotation.x=-Math.PI/2;walk.position.y=.1;walk.receiveShadow=true;root.add(walk);for(const x of [-10,10])box(root,'#d0c9b9',x,.075,0,7.2,.05,65);for(const z of [-12,12])box(root,'#d0c9b9',0,.075,z,60,.05,7.2);
 const road=new THREE.Shape();rounded(road,-32,-36,32,36,7);const hole=new THREE.Path();rounded(hole,-28,-32,28,32,3);road.holes.push(hole);const ring=new THREE.Mesh(new THREE.ShapeGeometry(road,16),view.material('#6e7776'));ring.rotation.x=-Math.PI/2;ring.position.y=.13;ring.receiveShadow=true;root.add(ring);
 for(const x of [-10,10])box(root,'#6e7776',x,.115,0,4,.04,66);
 for(const z of [-12,12])box(root,'#6e7776',0,.115,z,60,.04,4);
 // Lane markings stop at crossings; pedestrian crossings align to sidewalks.
 for(let z=-28;z<=28;z+=3)if(Math.abs(Math.abs(z)-12)>4)for(const x of [-10,10])box(root,'#d9d4bc',x,.15,z,.075,.015,1.15);
 for(let x=-25;x<=25;x+=3)if(Math.abs(Math.abs(x)-10)>4)for(const z of [-12,12])box(root,'#d9d4bc',x,.15,z,1.15,.015,.075);
 for(const x of [-10,10])for(const z of [-12,12])for(const offset of [-3.2,3.2])for(let stripe=-1.4;stripe<=1.4;stripe+=.55){box(root,'#e7e2d1',x+stripe,.17,z+offset,.3,.02,1.1);box(root,'#e7e2d1',x+offset,.17,z+stripe,1.1,.02,.3);}
 // Soft landscaping edges and a varied, limited tree line.
 for(const [x,z,t,s]of [[-29,-31,0,.9],[-14,-31,1,.8],[28,-31,1,.9],[-26,-5,0,.8],[-15,5,1,.85],[26,7,0,.9],[-26,30,1,.85],[-14,30,0,1],[6,30,1,.8],[26,31,0,.85]])tree(x,z,t,s);
 for(const [x,z]of [[-12,-13],[12,13],[-12,13],[12,-13]]){cylinder(root,'#67777a',x,1.6,z,.065,3.2,8);box(root,'#67777a',x+.25,3.2,z,.6,.08,.1);box(root,'#f0d9aa',x+.5,3.1,z,.4,.12,.3);}
 function shell(parent,{w=12,d=10,h=4,color='#e7dbbf',accent='#688c88',name=''}={}){
  const exterior=new THREE.Group(),inner=new THREE.Group();parent.add(inner,exterior);
  box(inner,'#e4d5b9',0,.12,0,w,.18,d);
  box(inner,color,0,h/2,-d/2,w,h,.2);box(inner,color,-w/2,h/2,0,.2,h,d);
  box(exterior,color,w/2,h/2,0,.2,h,d);
  const doorW=1.6;for(const x of [-(w+doorW)/4,(w+doorW)/4])box(exterior,color,x,h/2,d/2,(w-doorW)/2,h,.2);
  box(exterior,color,0,h-.35,d/2,doorW,.7,.2);box(exterior,accent,0,h+.12,0,w+.4,.3,d+.4);
  for(const x of [-w*.31,w*.31]){box(exterior,'#9fbdba',x,h*.5,d/2+.12,w*.25,h*.45,.04);box(exterior,'#ede7d8',x,h*.5,d/2+.16,.07,h*.45,.04);}
  box(exterior,'#4d6c70',0,1.1,d/2,1.4,2.2,.12);
  if(name)sign(exterior,name,0,h-.48,d/2+.18,Math.min(w*.6,6),accent);
  const pick=box(exterior,color,0,h/2,0,w,h,d);pick.material=new THREE.MeshBasicMaterial({visible:false});interactables.push(pick);
  return {exterior,inner,pick};
 }
 function workstation(parent,x,z,index){
  // Dedicated desks have no embedded benches; each kit has a distinct silhouette.
  const tops=['#d8b08a','#e5e2d8','#a5b8b8','#c5b992'];const top=tops[index%4];
  box(parent,top,x,.94,z,2.15,.14,1);for(const dx of [-.86,.86])box(parent,'#56666b',x+dx,.5,z,.1,.86,.65);
  if(index===1)box(parent,top,x+.85,.94,z+.65,.45,.14,1.2);
  if(index===2)box(parent,'#6c8188',x-.8,.5,z,.48,.8,.7);
  box(parent,'#35474e',x,1.35,z-.2,.85,.53,.08);box(parent,'#91bec0',x,1.35,z-.15,.74,.43,.02);box(parent,'#57696b',x,.99,z+.25,.65,.025,.24);
  const chairColor=['#487b83','#b57d57','#77738b','#728565'][index%4];
  box(parent,chairColor,x,.53,z+1.05,.62,.16,.63);box(parent,chairColor,x,.94,z+1.34,.64,.72,.13);cylinder(parent,'#52616a',x,.26,z+1.05,.05,.4,8);box(parent,'#52616a',x,.1,z+1.05,.8,.08,.12);box(parent,'#52616a',x,.1,z+1.05,.12,.08,.8);
  if(index===3)box(parent,'#e4c484',x+.7,1.08,z,.18,.2,.18);
 }
 function addCompany(company,index){
  const building=buildOffice({company,index,lot:LOTS[index],root,box,cylinder,sign,workstation,view});
  interactables.push(building.pick);companyGroups.set(company.id,building);buildings.set(building.lot.id,building.group);return building;
 }
 function removeCompany(id){const item=companyGroups.get(id);if(!item)return;root.remove(item.group);const at=interactables.indexOf(item.pick);if(at>=0)interactables.splice(at,1);const geometries=new Set(),materials=new Set();item.group.traverse(o=>{if(o.geometry)geometries.add(o.geometry);if(o.material?.type==='MeshBasicMaterial')materials.add(o.material);});for(const geometry of geometries)if(!geometry.userData.catalogShared)geometry.dispose();for(const m of materials){m.map?.dispose();m.dispose();}companyGroups.delete(id);}
 const urban=[];
 function house(parent,config,x,z,rotation=0){const g=urbanBuilding(view,config);g.position.set(x,.15,z);g.rotation.y=rotation;parent.add(g);urban.push(g);return g;}
 const reserves=[];for(const [index,lot]of LOTS.filter(l=>l.kind==='company').entries()){
  const reserve=new THREE.Group();reserve.position.set(lot.x,0,lot.z);root.add(reserve);
  if(index===1){for(const [i,x]of [-4.6,0,4.6].entries())house(reserve,{w:4.1,d:9,floors:2+i,color:['#bfc0ac','#c4a798','#d4c39d'][i],roof:['#6d7971','#7f7266','#8e6555'][i],style:i===1?'townhouse':'brick',shop:['FLORISTA','PAPELARIA','CAFÉ LARGO'][i],seed:i+2},x,-1.4);}
  else if(index===2){house(reserve,{w:6.4,d:10,floors:4,color:'#bd8974',trim:'#e2c8a9',roof:'#626d67',style:'brick',shop:'ARMAZÉM',seed:5},-3.6,-1);house(reserve,{w:6.1,d:8,floors:3,color:'#abb7b3',roof:'#687b77',style:'artdeco',shop:'ATELIÊ',seed:7},3.4,0);}
  reserves.push(reserve);
 }
 const zones=new Map();for(const lot of LOTS.filter(l=>l.kind!=='company')){const g=new THREE.Group();g.position.set(lot.x,.1,lot.z);root.add(g);zones.set(lot.id,g);}
 const garden=zones.get('garden');
 // Winding path and lawn belong to the park, not independent square pads.
 box(garden,'#91a47e',0,.05,0,15,.1,17);
 const curve=new THREE.CatmullRomCurve3([new THREE.Vector3(0,.14,8),new THREE.Vector3(-1,.14,3),new THREE.Vector3(2,.14,-1),new THREE.Vector3(0,.14,-8)]);
 const path=new THREE.Mesh(new THREE.TubeGeometry(curve,40,.65,4,false),view.material('#d4c8ad'));path.scale.y=.03;path.position.y=.18;garden.add(path);
 cylinder(garden,'#c1b9a5',-3,.36,-2,1.45,.48,24);cylinder(garden,'#86b5b1',-3,.61,-2,1.2,.04,24);cylinder(garden,'#d8d0b9',-3,.95,-2,.24,.7,12);
 for(const prop of CATALOG_PROPS.filter(p=>p.zone==='garden'))stamp(prop.source,prop.height,garden,prop.x,prop.z);
 tree(-25,-5,0,.8);tree(-14,4,1,1.15);tree(-24,5,0,1.1);
 const cafe=zones.get('cafe');
 house(cafe,{w:8,d:8,floors:3,color:'#d6b59b',trim:'#ecddc4',roof:'#806351',style:'stone',shop:'TORREFAÇÃO / 08',seed:3},-2,-2);
 house(cafe,{w:4,d:6,floors:2,color:'#b4b9a1',roof:'#68776d',style:'townhouse',shop:'DISCOS',seed:4},5,-3);
 for(const prop of CATALOG_PROPS.filter(p=>p.zone==='cafe'))stamp(prop.source,prop.height,cafe,prop.x,prop.z+3);
 const library=zones.get('library');
 house(library,{w:10,d:9,floors:4,color:'#c6b896',trim:'#e9dec8',roof:'#6b7770',style:'artdeco',shop:'LIVRARIA & GALERIA',seed:6},1,-1.5);
 house(library,{w:3.3,d:6,floors:2,color:'#bac2b9',roof:'#777f70',style:'stone',shop:'JORNAL',seed:2},-5.9,-1);
 for(const prop of CATALOG_PROPS.filter(p=>p.zone==='library'))stamp(prop.source,prop.height,library,prop.x,prop.z+2);
 const home=zones.get('residence');
 for(const [i,x]of [-4.6,0,4.6].entries())house(home,{w:4.15,d:8.5,floors:[2,3,2][i],color:['#b9bdc2','#d1b1b1','#c8b88d'][i],trim:'#eee0c8',roof:['#6b756d','#877163','#64736f'][i],style:i===1?'timber':'townhouse',shop:i===2?'MERCEARIA':'',seed:11+i},x,-1);
 for(const x of [-5,0,5]){box(home,'#7a8d65',x,.45,5.6,2,.6,.65);box(home,'#a29377',x,.16,5.6,2.2,.2,.85);}
 const market=zones.get('market');
 house(market,{w:6.3,d:8,floors:2,color:'#c7b99f',roof:'#7a876a',style:'warehouse',shop:'OFICINA CICLO',seed:9},-3.5,-1.5);
 house(market,{w:6.2,d:7.5,floors:4,color:'#b57e64',trim:'#e2c9ad',roof:'#68716b',style:'brick',shop:'MERCADO LOCAL',seed:8},3.4,-1);
 for(let i=0;i<4;i++){box(market,['#a4b57b','#d9af72','#c3806b','#88a9a2'][i],-3.6+i*2.4,.65,4.6,1.8,.9,.9);box(market,'#d6c6a1',-3.6+i*2.4,2.4,4.5,2.1,.12,2.1);}
 for(const prop of CATALOG_PROPS.filter(p=>p.zone==='market'))stamp(prop.source,prop.height,market,prop.x,prop.z);
 // The avenue is embedded in a larger city, rather than floating on an isolated pad.
 const streetColors=['#c4b49a','#b78c75','#aeb9b4','#c4b4b6','#b9b697','#c9b99e'];
 const streetStyles=['brick','townhouse','artdeco','stone','timber','warehouse'];
 for(const side of [-1,1]){
  for(let i=0;i<6;i++){const x=-36+i*14;house(root,{w:10+(i%2),d:9+(i%3),floors:2+(i+Number(side>0))%4,color:streetColors[i],trim:'#e5d7bc',roof:['#727d72','#815d4d','#686f6a'][i%3],style:streetStyles[(i+Number(side>0))%6],shop:['FARMÁCIA','PADARIA','FOTOGRAFIA','EMPÓRIO','MÚSICA','HOTEL'][i],seed:17+i},x,side*43,side<0?0:Math.PI);}
  for(let i=0;i<4;i++)house(root,{w:10,d:9,floors:2+(i%3),color:streetColors[(i+2)%6],roof:['#626c68','#9c6c54'][i%2],style:streetStyles[(i+2)%6],shop:['MARCENARIA','ESTÚDIO','ARMAZÉM','LAVANDERIA'][i],seed:25+i},side*39.5,-26+i*17,side<0?Math.PI/2:-Math.PI/2);
 }
 // Street trees, utility poles and overhead cables add a human scale to the urban fabric.
 for(const [x,z]of [[-38,-39],[0,-39],[34,-39],[-38,39],[0,39],[34,39]])tree(x,z,0,.8);
 for(const x of [-12,12]){
  for(const z of [-28,-4,20]){cylinder(root,'#7d725f',x,2.7,z,.065,5.4,7);box(root,'#6e6e63',x,5.3,z,1.2,.1,.12);}
  for(const [z0,z1]of [[-28,-4],[-4,20]]){const curve=new THREE.CatmullRomCurve3([new THREE.Vector3(x,5.3,z0),new THREE.Vector3(x,4.7,(z0+z1)/2),new THREE.Vector3(x,5.3,z1)]);const cable=new THREE.Line(new THREE.BufferGeometry().setFromPoints(curve.getPoints(16)),new THREE.LineBasicMaterial({color:'#68685d'}));root.add(cable);}
 }
 const construction=zones.get('construction');for(const x of [-4,4])for(const z of [-4,4])box(construction,'#bcbab0',x,2.5,z,.4,5,.4);box(construction,'#c3bfb0',0,5,0,8.5,.3,8.5);box(construction,'#c3bfb0',0,.3,0,8.5,.3,8.5);
 for(const x of [-6,6]){box(construction,'#a28d70',x,.7,0,.14,1.4,14);for(let z=-6;z<=6;z+=1.5)box(construction,'#b8a286',x,.7,z,.18,1.5,.3);}sign(construction,'NOVO ATELIÊ',0,1.1,7.3,5,'#9c7852');
 const crane=assets.crane(),cranePlacement=new THREE.Group();cranePlacement.add(crane.object);cranePlacement.position.set(25,.1,20);cranePlacement.scale.set(.36,.7,.36);root.add(cranePlacement);
 return {root,zones,reserves,urban,companyGroups,interactables,addCompany,removeCompany,box,stamp,sign,crane,dispose(){for(const t of labels)t.dispose();for(const item of urban)for(const t of item.userData.textures||[])t.dispose();}};
}
