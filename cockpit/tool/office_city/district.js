import * as THREE from 'three';
import {LOTS,CATALOG_PROPS,STATIONS} from './scene-plan.js';
/** Creates one authored neighbourhood; no seeded/random building scatter. */
export function buildDistrict(view,assets){
 view.base.visible=false;view.city.visible=false;view.grid.visible=false;
 view.scene.background.set('#dedbd0');view.scene.fog.near=160;view.scene.fog.far=350;
 view.setInk(.25);view.setPaper(false);view.renderer.setPixelRatio(Math.min(devicePixelRatio,1.5));
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
 box(root,'#a4b18c',0,-.5,0,68,1,76);box(root,'#a4b18c',0,.025,0,64,.12,72);
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
 for(const [x,z,t,s]of [[-29,-31,0,.9],[-14,-31,1,.8],[26,-30,1,.9],[-26,-5,0,.8],[-15,5,1,.85],[26,7,0,.9],[-26,30,1,.85],[-14,30,0,1],[6,30,1,.8],[26,31,0,.85]])tree(x,z,t,s);
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
  const lot=LOTS[index],g=new THREE.Group();g.position.set(lot.x,.1,lot.z);root.add(g);const themes=[['#e6dec9','#537e82'],['#e8d0b9','#aa7256'],['#d5dfd1','#638669']];
  const building=shell(g,{w:14,d:12,h:3.8,color:themes[index][0],accent:themes[index][1],name:company.name});building.pick.userData.companyId=company.id;
  // Rooms retain solid back walls. Only the selected near building opens.
  box(building.inner,'#b9c9c8',-2.8,.23,-1,7.7,.035,9.2);box(building.inner,'#e2c9ac',3.6,.23,-3.1,5,.035,5.2);box(building.inner,'#d6c9d6',3.6,.23,3,5,.035,4.2);
  box(building.inner,'#e4dfd0',1.4,1.05,-2.7,.15,1.8,6.2);box(building.inner,'#e4dfd0',4.15,1.05,.5,5.4,1.8,.15);
  const stations=STATIONS;stations.forEach(([x,z],i)=>workstation(building.inner,x,z,i));
  // Reception, storage and lounge use purpose-built furniture, inspired by Office pixel art.
  box(building.inner,'#8b9fa1',3.9,.55,3.45,3,.65,1.05);box(building.inner,'#8b9fa1',3.9,1,3.9,3,1,.18);for(const x of [2.35,5.45])box(building.inner,'#799294',x,.76,3.45,.2,.8,1.15);
  box(building.inner,'#ad8d69',3.8,.55,1.95,1.8,.14,.7);box(building.inner,'#ccac7f',3.8,.43,1.95,1.3,.2,.45);
  box(building.inner,'#a58c70',-4.4,.9,-5.55,3,1.4,.52);for(const y of [.4,.95,1.5])box(building.inner,'#d2b28c',-4.4,y,-5.23,3,.08,.05);
  for(let i=0;i<12;i++)box(building.inner,['#8b6862','#688e90','#c7aa68','#8c869f'][i%4],-5.65+i*.22,1.19,-5.23,.16,.34+(i%3)*.06,.16);
  box(building.inner,'#53616a',-6.15,1,-3.2,.85,1.8,.7);for(let i=0;i<5;i++)box(building.inner,'#92b3b1',-6.15,.5+i*.25,-2.83,.6,.08,.03);
  box(building.inner,'#a88967',5.9,.7,.95,.8,1.2,.65);box(building.inner,'#4d5f65',5.9,1.45,.95,.6,.5,.5);box(building.inner,'#d1b279',5.9,1.4,1.22,.2,.22,.08);
  sign(building.inner,'ESTÚDIO',-3.1,2.4,-5.86,2.1,themes[index][1]);sign(building.inner,'REUNIÕES',3.6,2.4,-5.86,2.6,themes[index][1]);
  if(index===0){for(const prop of CATALOG_PROPS.filter(p=>p.zone==='company-1'))stamp(prop.source,prop.height,building.inner,prop.x,prop.z);}
  else box(building.inner,'#9c7757',3.6,.75,-3.3,2.5,.14,1.5);
  // Roof details distinguish companies without cloning a whole tower.
  for(let i=0;i<=index;i++){const panel=box(building.exterior,'#4e6971',-3+i*1.8,4.08,-2,1.4,.1,2.4);panel.rotation.x=-.15;}
  box(building.exterior,'#b6b7a8',4.8,4.2,-3,1.3,.6,1.5);
  if(index===1){
   box(building.exterior,'#e1c4ab',0,5.3,-1.8,9,2.5,7);box(building.exterior,'#9b6d55',0,6.65,-1.8,9.5,.22,7.5);
   for(const x of [-3,0,3])box(building.exterior,'#9ab5b4',x,5.4,1.73,1.7,1.4,.05);
   box(building.exterior,'#a57d66',0,4.1,3,10,.18,2);for(const x of [-4.8,4.8])box(building.exterior,'#a57d66',x,4.55,3,.12,.85,2);
  }
  if(index===2){
   cylinder(building.exterior,'#668a81',0,4.05,-1,3.4,.25,32);cylinder(building.exterior,'#a8c0b7',0,4.55,-1,2.6,.9,24);
   box(building.exterior,'#587f70',0,5.1,-1,6,.2,5.6);for(const x of [-5.8,5.8])box(building.exterior,'#d7dfcf',x,2.1,6.8,.3,4.1,.3);
   box(building.exterior,'#6c947b',0,4.1,6.5,13,.22,2);
  }
  companyGroups.set(company.id,{group:g,...building,lot,company,stations});buildings.set(lot.id,g);return companyGroups.get(company.id);
 }
 function removeCompany(id){const item=companyGroups.get(id);if(!item)return;root.remove(item.group);const at=interactables.indexOf(item.pick);if(at>=0)interactables.splice(at,1);const geometries=new Set(),materials=new Set();item.group.traverse(o=>{if(o.geometry)geometries.add(o.geometry);if(o.material?.type==='MeshBasicMaterial')materials.add(o.material);});for(const geometry of geometries)if(!geometry.userData.catalogShared)geometry.dispose();for(const m of materials){m.map?.dispose();m.dispose();}companyGroups.delete(id);}
 const reserves=[];for(const lot of LOTS.filter(l=>l.kind==='company')){const reserve=new THREE.Group();root.add(reserve);for(const [dx,dz,t,s]of [[-4,-3,0,1.1],[2,-4,1,.9],[4,3,0,.85]])reserve.attach(tree(lot.x+dx,lot.z+dz,t,s));reserves.push(reserve);}
 const zones=new Map();for(const lot of LOTS.filter(l=>l.kind!=='company')){const g=new THREE.Group();g.position.set(lot.x,.1,lot.z);root.add(g);zones.set(lot.id,g);}
 const garden=zones.get('garden');
 // Winding path and lawn belong to the park, not independent square pads.
 box(garden,'#91a47e',0,.05,0,15,.1,17);
 const curve=new THREE.CatmullRomCurve3([new THREE.Vector3(0,.14,8),new THREE.Vector3(-1,.14,3),new THREE.Vector3(2,.14,-1),new THREE.Vector3(0,.14,-8)]);
 const path=new THREE.Mesh(new THREE.TubeGeometry(curve,40,.65,4,false),view.material('#d4c8ad'));path.scale.y=.03;path.position.y=.18;garden.add(path);
 cylinder(garden,'#c1b9a5',-3,.36,-2,1.45,.48,24);cylinder(garden,'#86b5b1',-3,.61,-2,1.2,.04,24);cylinder(garden,'#d8d0b9',-3,.95,-2,.24,.7,12);
 for(const prop of CATALOG_PROPS.filter(p=>p.zone==='garden'))stamp(prop.source,prop.height,garden,prop.x,prop.z);
 tree(-25,-5,0,.8);tree(-14,4,1,1.15);tree(-24,5,0,1.1);
 const cafe=zones.get('cafe');shell(cafe,{w:11,d:8,h:3.5,color:'#e4b99c',accent:'#9a6651',name:'CAFÉ / 08'});for(const prop of CATALOG_PROPS.filter(p=>p.zone==='cafe'))stamp(prop.source,prop.height,cafe,prop.x,prop.z+3);
 for(let i=0;i<7;i++)box(cafe,i%2?'#e7d6b5':'#537e77',-4.5+i*1.5,2.8,4.8,1.48,.12,2);sign(cafe,'TORREFAÇÃO',0,3.9,4.16,5,'#9a6651');
 const library=zones.get('library');const lib=shell(library,{w:11,d:10,h:5,color:'#d8dbd0',accent:'#637f88',name:'BIBLIOTECA'});
 for(const x of [-4.8,-2.4,0,2.4,4.8])box(lib.exterior,'#f1e8d5',x,2.4,5.25,.2,4.6,.35);
 for(const prop of CATALOG_PROPS.filter(p=>p.zone==='library'))stamp(prop.source,prop.height,library,prop.x,prop.z);
 // Public roof terrace is a distinct civic building, not another office clone.
 box(lib.exterior,'#abc0b0',0,5.4,0,8,.5,7);sign(library,'LEITURA & GALERIA',0,5.9,3.6,6,'#637f88');
 const home=zones.get('residence');shell(home,{w:10,d:8,h:3.8,color:'#d6c1a3',accent:'#87916d',name:'VILA / 01'});const roof=new THREE.Mesh(new THREE.ConeGeometry(7.5,2.8,4),view.material('#ad7058'));roof.rotation.y=Math.PI/4;roof.position.y=5.2;roof.scale.z=.8;home.add(roof);box(home,'#c6b598',3,5.8,-1,.7,2,.7);for(const x of [-3,3])box(home,'#748c6b',x,.6,6,2,.7,.7);
 const market=zones.get('market');shell(market,{w:10,d:7,h:3.2,color:'#d9c28f',accent:'#6c8b83',name:'MERCADO'});for(let i=0;i<4;i++){box(market,['#a4b57b','#d9af72','#c3806b','#88a9a2'][i],-3.6+i*2.4,.65,4.6,1.8,.9,.9);box(market,'#d6c6a1',-3.6+i*2.4,2.4,4.5,2.1,.12,2.1);}for(const prop of CATALOG_PROPS.filter(p=>p.zone==='market'))stamp(prop.source,prop.height,market,prop.x,prop.z);
 const construction=zones.get('construction');for(const x of [-4,4])for(const z of [-4,4])box(construction,'#bcbab0',x,2.5,z,.4,5,.4);box(construction,'#c3bfb0',0,5,0,8.5,.3,8.5);box(construction,'#c3bfb0',0,.3,0,8.5,.3,8.5);
 for(const x of [-6,6]){box(construction,'#a28d70',x,.7,0,.14,1.4,14);for(let z=-6;z<=6;z+=1.5)box(construction,'#b8a286',x,.7,z,.18,1.5,.3);}sign(construction,'NOVO ATELIÊ',0,1.1,7.3,5,'#9c7852');
 const crane=assets.crane(),cranePlacement=new THREE.Group();cranePlacement.add(crane.object);cranePlacement.position.set(25,.1,20);cranePlacement.scale.setScalar(.36);root.add(cranePlacement);
 return {root,zones,reserves,companyGroups,interactables,addCompany,removeCompany,box,stamp,sign,crane,dispose(){for(const t of labels)t.dispose();}};
}
