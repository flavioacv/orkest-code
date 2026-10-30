import * as THREE from 'three';
import {urbanBuilding} from './urban-building.js';
import {WORLD_BOUNDS,LIFE_PROPS,WALK_ROUTES,forestPoints,pathState} from './life-plan.js';
import {trafficState} from './scene-plan.js';
/** Ambient city inhabitants are separate from session-backed office agents. */
export function createCityLife(view,assets,district){
 const {root,box,sign,stamp}=district,group=new THREE.Group();root.add(group);const materials=[],geometries=[],actors=[],forest=forestPoints();
 function circle(color,x,y,z,r,h=.12){const mesh=new THREE.Mesh(new THREE.CylinderGeometry(r,r,h,48),view.material(color));mesh.position.set(x,y,z);mesh.receiveShadow=true;group.add(mesh);return mesh;}
 function rounded(shape,x0,z0,x1,z1,r){shape.moveTo(x0+r,z0);shape.lineTo(x1-r,z0);shape.quadraticCurveTo(x1,z0,x1,z0+r);shape.lineTo(x1,z1-r);shape.quadraticCurveTo(x1,z1,x1-r,z1);shape.lineTo(x0+r,z1);shape.quadraticCurveTo(x0,z1,x0,z1-r);shape.lineTo(x0,z0+r);shape.quadraticCurveTo(x0,z0,x0+r,z0);}
 const walkShape=new THREE.Shape();rounded(walkShape,56,-34,132,34,9);const walkHole=new THREE.Path();rounded(walkHole,64,-26,124,26,1);walkShape.holes.push(walkHole);const walk=new THREE.Mesh(new THREE.ShapeGeometry(walkShape,24),view.material('#cec6b5'));walk.rotation.x=-Math.PI/2;walk.position.y=.11;group.add(walk);
 const roadShape=new THREE.Shape();rounded(roadShape,58,-32,130,32,7);const roadHole=new THREE.Path();rounded(roadHole,62,-28,126,28,3);roadShape.holes.push(roadHole);const road=new THREE.Mesh(new THREE.ShapeGeometry(roadShape,24),view.material('#6e7776'));road.rotation.x=-Math.PI/2;road.position.y=.14;group.add(road);
 box(group,'#cec6b5',45,.08,12,30,.06,7.2);box(group,'#6e7776',45,.14,12,30,.04,4);
 for(let x=34;x<57;x+=3)box(group,'#ded8c3',x,.17,12,1.3,.02,.075);
 // Lake edge is irregular, with a small pier instead of an isolated square floor.
 const lakeShape=new THREE.Shape();lakeShape.moveTo(-10,0);lakeShape.bezierCurveTo(-14,-8,-2,-10,8,-7);lakeShape.bezierCurveTo(15,-3,10,8,1,7);lakeShape.bezierCurveTo(-4,9,-12,6,-10,0);
 const lakeGeometry=new THREE.ShapeGeometry(lakeShape,32);for(const [scale,color,y]of [[1.1,'#c5b28e',.15],[1,'#81aaa8',.18]]){const mesh=new THREE.Mesh(lakeGeometry,view.material(color));mesh.rotation.x=-Math.PI/2;mesh.scale.setScalar(scale);mesh.position.set(95,y,-8);group.add(mesh);}
 box(group,'#a68962',93,.35,0,2,.18,5);for(const x of [92.3,93.7])box(group,'#846f52',x,.3,1.8,.12,.9,.12);
 circle('#c7c0aa',82,.16,14,9);circle('#e5dac1',82,.32,14,2.5,.4);circle('#82adae',82,.55,14,2.15,.035);circle('#b9b4a5',82,1,14,.3,1);
 // Paths, planting and water jets make the civic park a destination of its own.
 for(const points of [WALK_ROUTES[5],WALK_ROUTES[6]]){const curve=new THREE.CatmullRomCurve3(points.map(([x,z])=>new THREE.Vector3(x,.2,z)),true);const path=new THREE.Mesh(new THREE.TubeGeometry(curve,72,.6,4,true),view.material('#cfc2a6'));path.scale.y=.035;path.position.y=.21;group.add(path);}
 for(let i=0;i<6;i++){const a=i*Math.PI/3,x=82+Math.cos(a)*2,z=14+Math.sin(a)*2;const curve=new THREE.QuadraticBezierCurve3(new THREE.Vector3(x,.6,z),new THREE.Vector3(82+Math.cos(a),2.2,14+Math.sin(a)),new THREE.Vector3(82,.9,14));const jet=new THREE.Mesh(new THREE.TubeGeometry(curve,14,.035,5,false),view.material('#a8c8c4'));group.add(jet);}
 for(const [x,z]of [[74,20],[89,20],[108,3],[73,-13]]){circle('#ad9d78',x,.22,z,1.2,.18);for(let i=0;i<8;i++){const a=i*Math.PI/4;const flower=new THREE.Mesh(new THREE.IcosahedronGeometry(.18,0),view.material(['#c08876','#d0ba77','#a5ad82'][i%3]));flower.position.set(x+Math.cos(a)*.7,.5,z+Math.sin(a)*.7);group.add(flower);}}
 for(const prop of LIFE_PROPS){const object=stamp(prop.id,prop.height,group,prop.x,prop.z),size=new THREE.Box3().setFromObject(object).getSize(new THREE.Vector3());object.scale.multiplyScalar(Math.min(1,prop.maxWidth/Math.max(size.x,.001),prop.maxDepth/Math.max(size.z,.001)));}
 for(const [x,z,rotation]of [[76,14,Math.PI/2],[88,15,-Math.PI/2],[80,21,0]]){const bench=new THREE.Group();bench.position.set(x,0,z);bench.rotation.y=rotation;group.add(bench);box(bench,'#ad9368',0,.55,0,2.8,.14,.6);box(bench,'#ad9368',0,.95,.3,2.8,.7,.1);for(const dx of [-1,1])box(bench,'#5c6b67',dx,.28,0,.1,.5,.5);}
 // Court, shaded playground and a six-stall public fair.
 box(group,'#b2a385',113,.15,15,11,.1,15);box(group,'#8aab9a',113,.22,15,9,.06,13);
 for(const x of [108.7,117.3])box(group,'#e2ddc9',x,.27,15,.05,.02,12.5);for(const z of [8.7,15,21.3])box(group,'#e2ddc9',113,.27,z,8.6,.02,.05);
 for(const z of [9,21]){box(group,'#6c7d7d',113,1.7,z,.1,3.2,.1);box(group,'#e2d9bf',113,2.7,z,1.6,.9,.09);const hoop=new THREE.Mesh(new THREE.TorusGeometry(.36,.025,6,16),view.material('#b77d59'));hoop.rotation.x=Math.PI/2;hoop.position.set(113,2.4,z+(z===9?.5:-.5));group.add(hoop);}
 const stallNames=['HORTA','FRUTAS','PÃES','FLORES','ARTES','CAFÉ'];
 for(let i=0;i<6;i++){const x=74+i*5.2,z=-22,color=['#77966f','#c08d63','#b8a479','#a97b8c','#7d9f9f','#b5a05e'][i];box(group,'#a58a65',x,.85,z,3.6,1.2,1.5);for(const dx of [-1.7,1.7])box(group,'#93826a',x+dx,1.5,z,.09,2.8,.09);for(let band=0;band<6;band++)box(group,band%2?'#eadfc4':color,x-1.6+band*.64,2.9,z, .65,.13,2.8);sign(group,stallNames[i],x,2.2,z+.8,2.8,color);
  for(let fruit=0;fruit<4;fruit++)box(group,['#ba795d','#b6b36c','#7fa073'][fruit%3],x-1+fruit*.7,1.6,z+.3,.45,.35,.4);
  const vendor=assets.character(16+i);vendor.position.set(x,.18,z-.2);vendor.children.forEach((o,j)=>o.visible=j===1);group.add(vendor);actors.push(vendor);
 }
 const police=urbanBuilding(view,{w:7,d:8,floors:2,color:'#b8c1be',trim:'#e4dfcd',roof:'#526b7c',style:'artdeco',shop:'POLÍCIA / BASE',seed:3});police.position.set(50,.15,-25);group.add(police);
 // Instanced vegetation keeps the larger map from becoming hundreds of separate draw calls.
 const trunkGeo=new THREE.CylinderGeometry(.13,.18,1.7,6),crownGeos=[new THREE.IcosahedronGeometry(1.05,1),new THREE.ConeGeometry(1.0,2.8,7),new THREE.DodecahedronGeometry(1.2,0)];geometries.push(trunkGeo,...crownGeos);
 const trunkMaterial=view.material('#8c7656'),trunks=new THREE.InstancedMesh(trunkGeo,trunkMaterial,forest.length),matrix=new THREE.Matrix4();
 forest.forEach((p,i)=>{matrix.compose(new THREE.Vector3(p.x,.8*p.scale,p.z),new THREE.Quaternion(),new THREE.Vector3(p.scale,p.scale,p.scale));trunks.setMatrixAt(i,matrix);});trunks.castShadow=true;group.add(trunks);
 for(let type=0;type<3;type++){const points=forest.filter(p=>p.type===type),mesh=new THREE.InstancedMesh(crownGeos[type],view.material(['#7f966c','#667f64','#92a273'][type]),points.length);points.forEach((p,i)=>{matrix.compose(new THREE.Vector3(p.x,(type===1?2.7:2.3)*p.scale,p.z),new THREE.Quaternion().setFromAxisAngle(new THREE.Vector3(0,1,0),i*.7),new THREE.Vector3(p.scale,p.scale,p.scale));mesh.setMatrixAt(i,matrix);});mesh.castShadow=true;group.add(mesh);}
 const trail=new THREE.CatmullRomCurve3(WALK_ROUTES[7].map(([x,z])=>new THREE.Vector3(x,.2,z)),true);const trailMesh=new THREE.Mesh(new THREE.TubeGeometry(trail,64,.65,4,false),view.material('#c9bb99'));trailMesh.scale.y=.04;trailMesh.position.y=.19;group.add(trailMesh);
 const walkers=[];for(let i=0;i<18;i++){const actor=assets.character(24+i,i===3?{top:'#2f4c7d',bottom:'#2e3e5e',accessory:'cap',hairStyle:'buzz'}:{});group.add(actor);actors.push(actor);walkers.push({actor,route:WALK_ROUTES[i%WALK_ROUTES.length],offset:i*3.7,speed:.75+(i%3)*.08});}
 const patrol=assets.vehicle('suv','#e0e2d8'),ambulance=assets.vehicle('van','#deded3');group.add(patrol,ambulance);
 function beacon(vehicle){const base=new THREE.Box3().setFromObject(vehicle),top=base.max.y;box(vehicle,'#384e5b',0,top+.08,0, .9,.12,.3);const red=new THREE.Mesh(new THREE.BoxGeometry(.35,.17,.28),new THREE.MeshStandardMaterial({color:'#ce5b56',emissive:'#a12724'})),blue=new THREE.Mesh(new THREE.BoxGeometry(.35,.17,.28),new THREE.MeshStandardMaterial({color:'#6b9bbb',emissive:'#2658b4'}));red.position.set(-.24,top+.21,0);blue.position.set(.24,top+.21,0);vehicle.add(red,blue);materials.push(red.material,blue.material);return{red,blue};}
 const lights=beacon(patrol);beacon(ambulance);box(patrol,'#415a6d',0,.7,0,1.75,.28,1.2);box(ambulance,'#b96454',.9,1.1,0,.06,.7,.18);box(ambulance,'#b96454',.91,1.1,0,.06,.18,.7);
 function update(elapsed){for(const w of walkers){const p=pathState(w.route,elapsed*w.speed+w.offset);w.actor.position.set(p.x,.17,p.z);w.actor.rotation.y=p.yaw;const pose=Math.floor(elapsed*6)%3;w.actor.children.forEach((o,i)=>o.visible=i===pose);}for(const [vehicle,speed,offset]of [[patrol,3,0],[ambulance,2.6,89]]){const p=trafficState(elapsed*speed+offset,{halfX:34,halfZ:30,radius:5});vehicle.position.set(p.x+94,.16,p.z);vehicle.rotation.y=p.yaw;}const flash=Math.floor(elapsed*3)%2;lights.red.material.emissiveIntensity=flash?.2:1.8;lights.blue.material.emissiveIntensity=flash?1.8:.2;}
 update(0);return{group,actors,walkers,forestCount:forest.length,update,dispose(){for(const m of materials)m.dispose();for(const t of police.userData.textures||[])t.dispose();}};
}
