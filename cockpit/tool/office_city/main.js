import * as THREE from 'three';
import {CityScene} from './generated/src/scene.js';
import {loadCatalogAssets} from './catalog-assets.js';
import {buildDistrict} from './district.js';
import {PROFILES,LOTS,CATALOG_PROPS,COMPANY_SLOTS,validateCompanies,trafficState} from './scene-plan.js';
import {characterState} from './walk-cycle.js';
const status=document.querySelector('#status'),error=document.querySelector('#error');
let view,assets,district,animation;
try{
 const canvas=document.querySelector('#scene');view=new CityScene(canvas,()=>{});assets=await loadCatalogAssets();district=buildDistrict(view,assets);
 const agents=PROFILES.map((profile,index)=>{const actor=assets.character(index);actor.traverse(o=>o.userData.agent=actor);district.root.add(actor);return actor;});
 let companies=[],selectedCompany=null,paused=false,elapsed=0,last=performance.now(),disposed=false,cameraMove=null,activeScene='overview',bicycle=null;
 const profiles=document.querySelector('#profiles'),companiesList=document.querySelector('#companies');
 function showError(e){error.hidden=false;error.textContent=e.message||String(e);}
 function setPose(actor,pose){actor.children.forEach((o,i)=>o.visible=i===pose);}
 function renderProfiles(){profiles.replaceChildren();for(const [index,p]of PROFILES.entries()){const button=document.createElement('button');button.className='person';button.dataset.profile=p.id;const swatch=document.createElement('span');swatch.className='swatch';swatch.style.background=p.top;const text=document.createElement('span');text.textContent=`${p.name} · ${p.hairStyle}`;button.append(swatch,text);button.onclick=()=>{paused=true;document.querySelector('#pause').textContent='Continuar';const actor=agents[index],point=actor.getWorldPosition(new THREE.Vector3());if(index<4&&companies.length){selectedCompany=companies[0].id;activeScene='company';}moveCamera(point.clone().add(new THREE.Vector3(0,.9,0)),new THREE.Vector3(2.6,2.2,3.3).applyQuaternion(actor.getWorldQuaternion(new THREE.Quaternion())));document.querySelector('#selection').textContent=`${p.name} · cabelo ${p.hairStyle} · ${p.accessory} · paleta Habbo`;document.body.dataset.profile=p.id;};profiles.append(button);}}
 function moveCamera(target,offset){cameraMove={start:performance.now(),from:view.camera.position.clone(),targetFrom:view.controls.target.clone(),target:target.clone(),position:target.clone().add(offset)};}
 function focusScene(id){activeScene=id;document.querySelectorAll('.scene-nav [data-scene]').forEach(b=>b.classList.toggle('active',b.dataset.scene===id));
  if(id==='overview'){selectedCompany=null;moveCamera(new THREE.Vector3(0,1,8),new THREE.Vector3(58,58,72));}
  else if(id==='company'){if(!companies.length)return;selectedCompany=selectedCompany&&district.companyGroups.has(selectedCompany)?selectedCompany:companies[0].id;const b=district.companyGroups.get(selectedCompany);moveCamera(new THREE.Vector3(b.lot.x,1.3,b.lot.z),new THREE.Vector3(12,12,15));}
  else{selectedCompany=null;const lot=LOTS.find(l=>l.id===id);if(lot)moveCamera(new THREE.Vector3(lot.x,1,lot.z),new THREE.Vector3(13,13,17));}
  document.body.dataset.scene=id;
 }
 function renderCompanies(){companiesList.replaceChildren();for(const company of companies){const b=document.createElement('button');b.className='company';b.textContent=company.name;b.dataset.company=company.id;b.onclick=()=>{selectedCompany=company.id;focusScene('company');};companiesList.append(b);}document.querySelector('#company-empty').hidden=companies.length>0;document.querySelector('#add-company').disabled=companies.length>=COMPANY_SLOTS.length;document.querySelector('#remove-company').disabled=!companies.length;document.querySelector('#company-count').textContent=String(companies.length);}
 function syncCompanies(input){
  const next=validateCompanies(input);
  // Remove actors first so deleting a company never disposes their shared pose data.
  for(const actor of agents)district.root.attach(actor);
  const same=next.length===companies.length&&next.every((c,i)=>c.id===companies[i].id&&c.name===companies[i].name);
  if(!same){for(const id of [...district.companyGroups.keys()])district.removeCompany(id);next.forEach((company,i)=>district.addCompany(company,i));}
  companies=next;district.reserves.forEach((reserve,i)=>reserve.visible=i>=companies.length);
  if(companies[0]){const office=district.companyGroups.get(companies[0].id);for(let i=0;i<4;i++){office.inner.add(agents[i]);if(i){const [x,z]=office.stations[i];agents[i].position.set(x,.23,z+1.05);agents[i].rotation.y=Math.PI;setPose(agents[i],3);}}}
  else for(let i=0;i<4;i++){agents[i].position.set(-24+i*1.5,.16,3);setPose(agents[i],1);}
  for(const [index,x,z,rotation]of [[4,-20,5,0],[5,3,7,0],[6,23,6,0],[7,-3,29,Math.PI/2]]){agents[index].position.set(x,.16,z);agents[index].rotation.y=rotation;setPose(agents[index],1);}
  if(selectedCompany&&!district.companyGroups.has(selectedCompany))selectedCompany=null;
  renderCompanies();try{localStorage.setItem('orkest.city.companies.v1',JSON.stringify(companies));}catch(e){showError(Error('A cena funciona, mas não foi possível salvar empresas neste navegador: '+e.message));}
  view.dirty=true;document.body.dataset.companies=String(companies.length);return {companies:companies.map(c=>({...c})),capacity:COMPANY_SLOTS.length};
 }
 let initial=[{id:'orkest',name:'Orkest Code'}];try{const saved=localStorage.getItem('orkest.city.companies.v1');if(saved)initial=validateCompanies(JSON.parse(saved));}catch(e){showError(Error('Empresas salvas inválidas; restaurado o exemplo inicial. '+e.message));}
 syncCompanies(initial);renderProfiles();
 document.querySelectorAll('.scene-nav [data-scene]').forEach(b=>b.onclick=()=>focusScene(b.dataset.scene));
 document.querySelector('#company-form').onsubmit=e=>{e.preventDefault();const input=document.querySelector('#company-name'),name=input.value.trim();if(!name)return;try{const id=globalThis.crypto.randomUUID();syncCompanies([...companies,{id,name}]);input.value='';selectedCompany=id;focusScene('company');}catch(e){showError(e);}};
 document.querySelector('#remove-company').onclick=()=>{syncCompanies(companies.slice(0,-1));focusScene('overview');};
 document.querySelector('#replay').onclick=()=>{elapsed=0;paused=false;document.querySelector('#pause').textContent='Pausar';focusScene('overview');};
 document.querySelector('#pause').onclick=e=>{paused=!paused;e.target.textContent=paused?'Continuar':'Pausar';};
 const traffic=[];
 for(const [i,id]of ['sedan','hatch','suv','van','bus'].entries()){const object=assets.vehicle(id);district.root.add(object);traffic.push({id,object,offset:i*43,speed:3.1});}
 bicycle=new THREE.Group();const bikeModel=assets.stamp('y4_bike_sc',1.1);const bikeBounds=new THREE.Box3().setFromObject(bikeModel).getSize(new THREE.Vector3());if(bikeBounds.x>bikeBounds.z)bikeModel.rotation.y=-Math.PI/2;bicycle.add(bikeModel);district.root.add(bicycle);
 const pickRay=new THREE.Raycaster();let down;
 canvas.addEventListener('pointerdown',e=>down=[e.clientX,e.clientY]);
 function visible(object){for(let o=object;o;o=o.parent)if(!o.visible)return false;return true;}
 canvas.addEventListener('pointerup',e=>{if(e.button!==0||!down||Math.hypot(e.clientX-down[0],e.clientY-down[1])>5)return;const r=canvas.getBoundingClientRect();pickRay.setFromCamera(new THREE.Vector2((e.clientX-r.left)/r.width*2-1,-(e.clientY-r.top)/r.height*2+1),view.camera);
  const hit=pickRay.intersectObjects(agents,true).find(h=>visible(h.object));if(hit){document.querySelector(`#profiles [data-profile="${hit.object.userData.agent.userData.profile.id}"]`).click();return;}
  const building=pickRay.intersectObjects(district.interactables,true).find(h=>h.object.userData.companyId);if(building){selectedCompany=building.object.userData.companyId;focusScene('company');}
 });
 function frame(now){
  if(disposed)return;animation=requestAnimationFrame(frame);const dt=Math.min((now-last)/1000,.1);last=now;if(document.hidden)return;
  if(cameraMove){const t=Math.min((now-cameraMove.start)/700,1),ease=t*t*(3-2*t);view.camera.position.lerpVectors(cameraMove.from,cameraMove.position,ease);view.controls.target.lerpVectors(cameraMove.targetFrom,cameraMove.target,ease);if(t===1)cameraMove=null;view.dirty=true;}
  // Near/far hysteresis keeps full building silhouettes at city scale.
  let open=null;
  for(const [id,b]of district.companyGroups){const targetDistance=Math.hypot(view.controls.target.x-b.lot.x,view.controls.target.z-b.lot.z),distance=view.camera.position.distanceTo(new THREE.Vector3(b.lot.x,1.3,b.lot.z));const near=targetDistance<7&&distance<(b.exterior.visible?25:30);b.exterior.visible=!near;if(near)open=id;}
  document.body.dataset.interior=open||'closed';
  if(!paused){elapsed+=dt;const state=characterState(elapsed);if(companies[0]){const actor=agents[0];actor.position.set(state.x,.23,state.z);actor.rotation.y=state.phase==='working'?Math.PI:state.yaw;setPose(actor,state.pose);}document.body.dataset.phase=state.phase;district.crane.update(dt);
   for(const vehicle of traffic){const p=trafficState(elapsed*vehicle.speed+vehicle.offset);vehicle.object.position.set(p.x,.16,p.z);vehicle.object.rotation.y=p.yaw;}
   const bike=trafficState(elapsed*1.7,{halfX:28.65,halfZ:32.65,radius:3.65});bicycle.position.set(bike.x,.16,bike.z);bicycle.rotation.y=bike.yaw;if(agents[7].parent!==bicycle)bicycle.add(agents[7]);agents[7].position.set(0,.58,0);agents[7].rotation.y=0;setPose(agents[7],3);
   document.body.dataset.traffic=String(Math.floor(elapsed*3.1));view.dirty=true;
  }
  status.textContent=open?'Interior da empresa · vista próxima':'Bairro vivo · fachadas preservadas';
 }
 const registry=await (await fetch('./generated/unified-assets.json')).json();
 document.querySelector('#asset-count').textContent=registry.entries.filter(i=>i.available).length.toLocaleString('pt-BR');
 const assetDialog=document.querySelector('#asset-browser'),assetSearch=document.querySelector('#asset-search'),assetKind=document.querySelector('#asset-kind'),assetList=document.querySelector('#asset-list');
 function showAssets(){const query=assetSearch.value.toLocaleLowerCase('pt-BR'),kind=assetKind.value,items=registry.entries.filter(e=>(!kind||e.kind===kind)&&(e.name+' '+e.id+' '+e.source).toLocaleLowerCase('pt-BR').includes(query));assetList.replaceChildren();document.querySelector('#asset-results').textContent=`${items.length.toLocaleString('pt-BR')} resultados · exibindo até 40`;document.querySelector('#asset-empty').hidden=items.length>0;
  for(const entry of items.slice(0,40)){const item=document.createElement('article');item.className='asset-card';if(entry.url){const image=document.createElement('img');image.src=entry.url;image.loading='lazy';image.alt=entry.name;item.append(image);}const name=document.createElement('strong');name.textContent=entry.name;const type=document.createElement('span');type.className='muted';type.textContent=entry.kind+' · '+(entry.available?'disponível':'indisponível');const source=document.createElement('code');source.textContent=entry.source;item.append(name,type,source);if(entry.url){const link=document.createElement('a');link.href=entry.url;link.target='_blank';link.rel='noopener';link.textContent='Abrir sprite original';item.append(link);}assetList.append(item);}}
 document.querySelector('#assets').onclick=()=>{showAssets();assetDialog.showModal();};document.querySelector('#close-assets').onclick=()=>assetDialog.close();assetSearch.oninput=showAssets;assetKind.onchange=showAssets;
 document.querySelector('#model-count').textContent=String(CATALOG_PROPS.length+5+1+1+PROFILES.length+7);
 window.orkestCity={setCompanies(input){return syncCompanies(input);},getCompanies(){return companies.map(c=>({...c}));},focusCompany(id){if(!district.companyGroups.has(id))throw Error('Empresa não encontrada.');selectedCompany=id;focusScene('company');}};
 document.addEventListener('visibilitychange',()=>{view.suspended=document.hidden;last=performance.now();view.dirty=true;});
 window.addEventListener('pagehide',()=>{disposed=true;cancelAnimationFrame(animation);delete window.orkestCity;const geometries=new Set(),materials=new Set();view.scene.traverse(o=>{if(o.geometry)geometries.add(o.geometry);for(const m of Array.isArray(o.material)?o.material:o.material?[o.material]:[])materials.add(m);});view.dispose();assets.dispose();district.dispose();for(const g of geometries)g.dispose();for(const m of materials)m.dispose();},{once:true});
 view.controls.minDistance=3;view.controls.maxDistance=170;view.camera.position.set(66,64,82);view.controls.target.set(0,1,0);focusScene('overview');animation=requestAnimationFrame(frame);document.body.dataset.status='ready';document.querySelector('#loading').hidden=true;
}catch(e){cancelAnimationFrame(animation);view?.dispose();assets?.dispose();status.textContent='Falha ao carregar';error.hidden=false;error.textContent=e.stack||String(e);console.error(e);}
