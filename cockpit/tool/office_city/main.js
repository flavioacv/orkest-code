import * as THREE from 'three';
import {CityScene} from './generated/src/scene.js';
import {generateLayout} from './generated/src/model.js';
import {loadCatalogAssets} from './catalog-assets.js';
import {characterState} from './walk-cycle.js';
const status=document.querySelector('#status'),error=document.querySelector('#error');
let view,assets,animation;
try {
 const canvas=document.querySelector('#scene');view=new CityScene(canvas,()=>{});
 assets=await loadCatalogAssets();
 const layout=generateLayout(17);
 // Compact district and clear lots for the office and construction site.
 layout.objects=layout.objects.filter(o=>Math.abs(o.x)<35&&o.z>-57&&o.z<0&&!(Math.abs(o.x)<7&&Math.abs(o.z+32)<9)&&!(o.x>8&&o.x<28&&o.z>-46&&o.z<-18));view.rebuild(layout);
 const office=new THREE.Group();office.position.set(0,.15,-32);view.scene.add(office);
 function box(parent,color,x,y,z,w,h,d){const mesh=new THREE.Mesh(new THREE.BoxGeometry(w,h,d),view.material(color));mesh.position.set(x,y,z);mesh.castShadow=true;mesh.receiveShadow=true;parent.add(mesh);return mesh;}
 box(office,'#b7b09d',0,-.1,0,10,.2,10);box(office,'#dbcfb7',0,.08,0,8.8,.16,8.8);
 box(office,'#e5dccb',0,1.7,-4.4,9,3.4,.22);box(office,'#e5dccb',-4.4,1.7,0,.22,3.4,9);
 const shell=new THREE.Group();office.add(shell);
 box(shell,'#d0c2aa',4.4,1.7,0,.22,3.4,9);
 box(shell,'#d0c2aa',-2.6,1.7,4.4,3.6,3.4,.22);box(shell,'#d0c2aa',2.6,1.7,4.4,3.6,3.4,.22);box(shell,'#d0c2aa',0,3,4.4,1.6,.8,.22);
 const roof=box(shell,'#52686c',0,3.55,0,9.3,.25,9.3);
 const door=box(office,'#637f84',-.78,1.2,4.35,.12,2.4,.15);door.userData.hinge=true;
 for(const x of [-2.7,2.7]){box(shell,'#8bb4b7',x,1.8,4.54,2.6,1.7,.05);box(shell,'#f2ead9',x,1.8,4.58,.08,1.7,.05);}
 box(office,'#c7c0ab',0,-.03,6,2,.12,3.2);
 const placard=document.createElement('canvas');placard.width=512;placard.height=96;const ctx=placard.getContext('2d');ctx.fillStyle='#304a50';ctx.fillRect(0,0,512,96);ctx.fillStyle='#f4ecda';ctx.font='bold 46px sans-serif';ctx.textAlign='center';ctx.fillText('ORKEST OFFICE',256,65);const texture=new THREE.CanvasTexture(placard);texture.colorSpace=THREE.SRGBColorSpace;const sign=new THREE.Mesh(new THREE.PlaneGeometry(3,.56),new THREE.MeshBasicMaterial({map:texture}));sign.position.set(0,3.05,4.57);shell.add(sign);
 function place(id,height,parent,x,z,rotation=0){const object=assets.stamp(id,height);object.position.set(x,.16,z);object.rotation.y=rotation;parent.add(object);return object;}
 for(const x of [-2,2])for(const z of [-2,1]){
  // Catalogue tables supply the furniture; monitors are original local props.
  place('y4_table_sh',.8,office,x,z-1);
  place('y4_luxchair_eu',1.15,office,x,z+.25,Math.PI);
  box(office,'#34494d',x,1.1,z-1.1,.8,.5,.07);box(office,'#83b9b7',x,1.1,z-1.05,.7,.4,.02);box(office,'#556165',x,.86,z-.65,.65,.035,.22);
 }
 place('y4_sofa_cp',1,office,2.9,-3.4);place('y4_planter_mp',.8,office,-3.7,3.5);place('y4_planter_mp',.8,office,3.7,3.5);place('y4_lamp_mp',2,office,-3.6,-3.6);
 place('y4_bench_mp',1,view.scene,-6,-24,Math.PI/2);
 const construction=new THREE.Group();construction.position.set(16,0,-34);view.scene.add(construction);box(construction,'#ad9876',0,.02,0,12,.15,12);
 for(const x of [-3,3])for(const z of [-3,3])box(construction,'#bbb5a7',x,2,z,.45,4,.45);box(construction,'#b8b2a3',0,4,0,6,.25,6);
 const crane=assets.crane(),cranePlacement=new THREE.Group();cranePlacement.add(crane.object);cranePlacement.scale.setScalar(.4);cranePlacement.position.set(20,0,-37);view.scene.add(cranePlacement);
 for(const [i,id]of ['sedan','van'].entries()){const car=assets.vehicle(id);car.position.set(-8,.12,-25+i*4);car.rotation.y=Math.PI/2;view.scene.add(car);}
 const agents=[];
 for(let i=0;i<4;i++){const actor=assets.character(i);actor.userData.name=`Agente ${i+1}`;actor.traverse(o=>o.userData.agent=actor);office.add(actor);agents.push(actor);if(i){actor.position.set(i===1?2:i===2?-2:2,.16,i===1?1.1:-1.9);actor.rotation.y=Math.PI;actor.children.forEach((child,j)=>child.visible=j===3);}}
 let interior=false,paused=false,start=performance.now(),pauseAt=0,last=0,disposed=false,autoReveal=true;
 function cutaway(value){interior=value;shell.visible=!value;door.visible=!value;document.querySelector('#roof').textContent=value?'Ver fachada':'Ver interior';view.dirty=true;}
 function focus(){cutaway(true);view.controls.target.set(0,1,-32);view.camera.position.set(10,10,-18);view.dirty=true;}
 function exterior(){cutaway(false);view.controls.target.set(4,1,-32);view.camera.position.set(23,20,-4);view.dirty=true;}
 document.querySelector('#focus').onclick=()=>{autoReveal=false;focus();};document.querySelector('#construction').onclick=()=>{autoReveal=false;view.controls.target.set(17,3,-34);view.camera.position.set(39,23,-10);view.dirty=true;};document.querySelector('#city').onclick=exterior;document.querySelector('#roof').onclick=()=>cutaway(!interior);
 document.querySelector('#replay').onclick=()=>{start=performance.now();autoReveal=true;if(paused)pauseAt=start;document.body.dataset.phase='outside';exterior();};
 document.querySelector('#pause').onclick=e=>{paused=!paused;if(paused)pauseAt=performance.now();else start+=performance.now()-pauseAt;e.target.textContent=paused?'Continuar':'Pausar';};
 const clickRay=new THREE.Raycaster();let down;
 canvas.addEventListener('pointerdown',e=>down=[e.clientX,e.clientY]);
 canvas.addEventListener('pointerup',e=>{if(e.button!==0||!down||Math.hypot(e.clientX-down[0],e.clientY-down[1])>5)return;const r=canvas.getBoundingClientRect();clickRay.setFromCamera(new THREE.Vector2((e.clientX-r.left)/r.width*2-1,-(e.clientY-r.top)/r.height*2+1),view.camera);const hits=clickRay.intersectObjects(agents,true).filter(h=>h.object.visible);if(hits[0])document.querySelector('#selection').textContent=`${hits[0].object.userData.agent.userData.name} · personagem do catálogo · demonstração`;else if(clickRay.intersectObject(shell,true).length)focus();});
 function frame(now){if(disposed)return;animation=requestAnimationFrame(frame);if(document.hidden||paused||now-last<33)return;const dt=Math.min((now-last)/1000,.1);last=now;const state=characterState((now-start)/1000),actor=agents[0];actor.position.set(state.x,.16,state.z);actor.rotation.y=state.phase==='working'?Math.PI:state.yaw;actor.children.forEach((child,i)=>child.visible=i===state.pose);if(autoReveal&&state.z<4.1){autoReveal=false;focus();}door.rotation.y=state.phase==='entering'?-Math.PI/2:0;crane.update(dt);document.body.dataset.phase=state.phase;status.textContent=state.phase==='working'?'Na estação · personagem e móveis do catálogo':state.phase==='entering'?'Entrando no prédio…':'Caminhando até a entrada…';view.dirty=true;}
 animation=requestAnimationFrame(frame);
 document.addEventListener('visibilitychange',()=>{view.suspended=document.hidden;view.dirty=true;});
 window.addEventListener('pagehide',()=>{disposed=true;cancelAnimationFrame(animation);const geometries=new Set(),materials=new Set();view.scene.traverse(o=>{if(o.geometry)geometries.add(o.geometry);if(o.material)for(const m of Array.isArray(o.material)?o.material:[o.material])materials.add(m);});view.dispose();assets.dispose();for(const g of geometries)g.dispose();for(const m of materials)m.dispose();texture.dispose();},{once:true});
 exterior();document.body.dataset.status='ready';
} catch(e){cancelAnimationFrame(animation);view?.dispose();assets?.dispose();status.textContent='Falha ao carregar';error.hidden=false;error.textContent=e.stack||String(e);console.error(e);}
