import * as THREE from 'three';
import {CityScene} from './generated/src/scene.js';
import {generateLayout} from './generated/src/model.js';
const status=document.querySelector('#status'),error=document.querySelector('#error');
try {
 const canvas=document.querySelector('#scene'),view=new CityScene(canvas,()=>{});
 const layout=generateLayout(17);
 // Reserve a dry site for the bespoke office instead of overlapping city objects.
 layout.objects=layout.objects.filter(o=>Math.abs(o.x)>16||Math.abs(o.z+32)>12);view.rebuild(layout);
 const office=new THREE.Group();office.position.set(0,.4,-32);view.scene.add(office);
 function box(parent,color,x,y,z,w,h,d){const mesh=new THREE.Mesh(new THREE.BoxGeometry(w,h,d),view.material(color));mesh.position.set(x,y,z);mesh.castShadow=true;mesh.receiveShadow=true;parent.add(mesh);return mesh;}
 box(office,'#dcc8a7',0,0,0,28,.5,20);
 box(office,'#e8ddcb',0,3,-10,28,6,.4);box(office,'#e8ddcb',-14,3,0,.4,6,20);
 const roof=box(office,'#56767b',0,6.5,0,29,.5,21);roof.visible=false;
 const agents=[];
 for(let i=0;i<6;i++){
  const x=-9+(i%3)*9,z=-5+Math.floor(i/3)*9;
  box(office,'#a57753',x,1.9,z,6,.3,2.7);box(office,'#4b585d',x-2,1,z,.3,2,.3);box(office,'#4b585d',x+2,1,z,.3,2,.3);
  box(office,'#354b58',x,2.9,z-.7,2.2,1.4,.2);box(office,'#86b9b4',x,2.9,z-.55,1.9,1.1,.05);box(office,'#43505a',x,1.1,z+2,2,.3,2);box(office,'#43505a',x,2,z+2.8,2,1.7,.25);
  const actor=new THREE.Group();actor.position.set(x,0,z+2);office.add(actor);
  const colors=['#568b98','#bd835e','#698b6a'];box(actor,colors[i%3],0,1.9,0,1,1.5,.65);box(actor,'#ddad88',0,3,0,.8,.8,.8);box(actor,'#384553',-.3,.7,0,.35,1,.4);box(actor,'#384553',.3,.7,0,.35,1,.4);
  actor.userData={name:`Agente ${i+1}`,status:['trabalhando','aguardando','livre'][i%3]};actor.traverse(o=>o.userData.agent=actor);agents.push(actor);
 }
 const clickRay=new THREE.Raycaster();let down;
 canvas.addEventListener('pointerdown',e=>down=[e.clientX,e.clientY]);
 canvas.addEventListener('pointerup',e=>{if(!down||Math.hypot(e.clientX-down[0],e.clientY-down[1])>5)return;const r=canvas.getBoundingClientRect();clickRay.setFromCamera(new THREE.Vector2((e.clientX-r.left)/r.width*2-1,-(e.clientY-r.top)/r.height*2+1),view.camera);const hit=clickRay.intersectObjects(agents,true)[0];if(hit)document.querySelector('#selection').textContent=`${hit.object.userData.agent.userData.name} · ${hit.object.userData.agent.userData.status} · demonstração`;});
 function focus(){view.controls.target.set(0,1,-32);view.camera.position.set(30,32,6);view.dirty=true;}
 document.querySelector('#focus').onclick=focus;document.querySelector('#city').onclick=()=>{view.controls.target.set(0,0,0);view.camera.position.set(110,110,145);view.dirty=true;};
 document.querySelector('#roof').onclick=e=>{roof.visible=!roof.visible;e.target.textContent=roof.visible?'Ocultar teto':'Mostrar teto';view.dirty=true;};
 document.addEventListener('visibilitychange',()=>{view.suspended=document.hidden;view.dirty=true;});window.addEventListener('pagehide',()=>view.dispose(),{once:true});
 focus();status.textContent='Cena pronta · 6 agentes demonstrativos';document.body.dataset.status='ready';
} catch(e){status.textContent='Falha ao carregar';error.hidden=false;error.textContent=e.stack||String(e);}
