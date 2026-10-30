import * as THREE from 'three';
import {CityScene} from './generated/src/scene.js';
import {loadCatalogAssets} from './catalog-assets.js';
import {createCityLife} from './city-life.js';
import {DESTINATIONS} from './life-plan.js';
import {interactionMap} from './interaction-map.js';
import {buildDistrict} from './district.js';
import {PROFILES,LOTS,CATALOG_PROPS,COMPANY_SLOTS,validateCompanies,trafficState} from './scene-plan.js';
import {FLOOR_HEIGHT,MAX_AGENTS,COMMON_FLOORS} from './office-plan.js';
import {officeArrival} from './walk-cycle.js';
const status=document.querySelector('#status'),error=document.querySelector('#error');
let view,assets,district,animation,cityLife;
try{
 const canvas=document.querySelector('#scene');view=new CityScene(canvas,()=>{});assets=await loadCatalogAssets();district=buildDistrict(view,assets);cityLife=createCityLife(view,assets,district);
 const entities=new Map(),ambient=Array.from({length:4},(_,i)=>{const actor=assets.character(i+8);actor.traverse(o=>o.userData.agent=actor);district.root.add(actor);return actor;});
 let agents=[],selectedFloor=COMMON_FLOORS;
 let companies=[],selectedCompany=null,paused=false,elapsed=0,last=performance.now(),disposed=false,cameraMove=null,activeScene='overview',bicycle=null;
 const profiles=document.querySelector('#profiles'),companiesList=document.querySelector('#companies');
 function showError(e){error.hidden=false;error.textContent=e.message||String(e);}
 function setPose(actor,pose){actor.children.forEach((o,i)=>o.visible=i===pose);}
 function currentCompany(){return companies.find(c=>c.id===selectedCompany)||companies[0];}
 function exportedCompanies(){return companies.map(c=>({...c,agents:c.agents.map(a=>({...a}))}));}
 function renderFloorControls(){const company=currentCompany(),building=company&&district.companyGroups.get(company.id),select=document.querySelector('#floor-select');select.replaceChildren();if(building){selectedFloor=Math.min(selectedFloor,building.floors.length-1);for(const floor of building.floors){const option=document.createElement('option');option.value=String(floor.level);option.textContent=`${floor.label} · ${floor.occupants} agentes`;select.append(option);}select.value=String(selectedFloor);document.querySelector('#prev-floor').disabled=selectedFloor===0;document.querySelector('#next-floor').disabled=selectedFloor>=building.floors.length-1;document.querySelector('#team-count').value=String(company.agentCount);document.querySelector('#team-summary').textContent=`${company.agentCount} agentes · ${building.plan.floorCount} ${building.plan.floorCount===1?'andar':'andares'} · ${building.plan.capacity} estações`;document.body.dataset.agents=String(company.agentCount);document.body.dataset.floors=String(building.plan.floorCount);document.body.dataset.capacity=String(building.plan.capacity);}document.querySelector('#team-controls').hidden=!building;}
 function renderProfiles(){profiles.replaceChildren();const company=currentCompany();if(!company)return;for(const descriptor of company.agents){const entity=entities.get(descriptor.id);if(!entity)continue;const p=entity.actor.userData.profile,button=document.createElement('button');button.className='person';button.dataset.agent=descriptor.id;const swatch=document.createElement('span');swatch.className='swatch';swatch.style.background=p.top;const text=document.createElement('span');text.textContent=`${descriptor.name} · ${entity.floor===0?'térreo':entity.floor+'º andar'}`;button.append(swatch,text);button.onclick=()=>{paused=true;document.querySelector('#pause').textContent='Continuar';selectedCompany=entity.companyId;selectedFloor=entity.floor;activeScene='company';renderFloorControls();const actor=entity.actor,point=actor.getWorldPosition(new THREE.Vector3());moveCamera(point.clone().add(new THREE.Vector3(0,.9,0)),new THREE.Vector3(2.6,2.2,3.3).applyQuaternion(actor.getWorldQuaternion(new THREE.Quaternion())));document.querySelector('#selection').textContent=`${descriptor.name} · ${p.hairStyle} · ${p.accessory}`;document.body.dataset.profile=descriptor.id;};profiles.append(button);}}
 function moveCamera(target,offset){cameraMove={start:performance.now(),from:view.camera.position.clone(),targetFrom:view.controls.target.clone(),target:target.clone(),position:target.clone().add(offset)};}
 function focusScene(id){activeScene=id;document.querySelectorAll('.scene-nav [data-scene]').forEach(b=>b.classList.toggle('active',b.dataset.scene===id));
  if(id==='overview'){selectedCompany=null;moveCamera(new THREE.Vector3(39,1,0),new THREE.Vector3(80,100,125));}
  else if(id==='company'){if(!companies.length)return;selectedCompany=selectedCompany&&district.companyGroups.has(selectedCompany)?selectedCompany:companies[0].id;const b=district.companyGroups.get(selectedCompany);moveCamera(new THREE.Vector3(b.lot.x,1.3+selectedFloor*FLOOR_HEIGHT,b.lot.z),new THREE.Vector3(12,12,15));}
  else{selectedCompany=null;const lot=LOTS.find(l=>l.id===id)||DESTINATIONS.find(l=>l.id===id);if(lot)moveCamera(new THREE.Vector3(lot.x,1,lot.z),new THREE.Vector3(13,13,17));}
  renderFloorControls();renderProfiles();document.body.dataset.scene=id;
 }
 function renderCompanies(){companiesList.replaceChildren();for(const company of companies){const b=document.createElement('button');b.className='company';b.textContent=`${company.name} · ${company.agentCount} agentes`;b.dataset.company=company.id;b.onclick=()=>{selectedCompany=company.id;selectedFloor=COMMON_FLOORS;focusScene('company');};companiesList.append(b);}document.querySelector('#company-empty').hidden=companies.length>0;document.querySelector('#add-company').disabled=companies.length>=COMPANY_SLOTS.length;document.querySelector('#remove-company').disabled=!companies.length;document.querySelector('#company-count').textContent=String(companies.length);document.querySelector('#model-count').textContent=String(companies.reduce((n,c)=>n+c.agentCount,0)+ambient.length+cityLife.actors.length);}
 function syncCompanies(input){
  const next=validateCompanies(input);error.hidden=true;error.textContent="";
  // Detach retained actors before rebuilding their floors; stable IDs keep their appearance.
  for(const entity of entities.values())district.root.attach(entity.actor);
  for(const id of [...district.companyGroups.keys()])district.removeCompany(id);
  const retained=new Set();
  next.forEach((company,companyIndex)=>{const office=district.addCompany(company,companyIndex);for(const allocation of office.plan.agents){const descriptor=company.agents[allocation.index];retained.add(descriptor.id);let entity=entities.get(descriptor.id);if(!entity){const actor=assets.character(allocation.index+companyIndex*11);actor.userData.agentId=descriptor.id;actor.traverse(o=>o.userData.agent=actor);entity={actor};entities.set(descriptor.id,entity);}entity.companyId=company.id;entity.floor=allocation.floor;entity.desk=allocation.desk;entity.actor.userData.name=descriptor.name;entity.actor.userData.companyId=company.id;office.floors[allocation.floor].inner.add(entity.actor);entity.actor.position.set(allocation.x,.23,allocation.z);entity.actor.rotation.y=Math.PI;setPose(entity.actor,3);}});
  for(const [id,entity]of entities)if(!retained.has(id)){entity.actor.removeFromParent();assets.disposeCharacter(entity.actor);entities.delete(id);}
  agents=[...entities.values()].map(e=>e.actor);companies=next;district.reserves.forEach((reserve,i)=>reserve.visible=i>=companies.length);
  for(const [index,x,z,rotation]of [[0,-20,5,0],[1,3,7,0],[2,23,6,0],[3,-3,29,Math.PI/2]]){district.root.add(ambient[index]);ambient[index].position.set(x,.16,z);ambient[index].rotation.y=rotation;setPose(ambient[index],1);}
  if(selectedCompany&&!district.companyGroups.has(selectedCompany))selectedCompany=null;
  renderCompanies();renderFloorControls();renderProfiles();try{localStorage.setItem('orkest.city.companies.v1',JSON.stringify(companies));}catch(e){showError(Error('Não foi possível salvar empresas neste navegador: '+e.message));}
  view.dirty=true;document.body.dataset.companies=String(companies.length);return{companies:exportedCompanies(),capacity:COMPANY_SLOTS.length};
 }
 function setTeam(companyId,input){const company=companies.find(c=>c.id===companyId);if(!company)throw Error('Empresa não encontrada.');let team;if(Array.isArray(input))team=input;else{if(!Number.isInteger(input)||input<0||input>MAX_AGENTS)throw Error(`Informe de 0 a ${MAX_AGENTS} agentes.`);team=Array.from({length:input},(_,i)=>company.agents[i]||{id:`${company.id}:agent:${i+1}`,name:PROFILES[i%8].name+(i>=8?' '+(Math.floor(i/8)+1):'')});}const oldFloors=district.companyGroups.get(companyId).plan.floorCount;syncCompanies(companies.map(c=>c.id===companyId?{...c,agents:team,agentCount:team.length}:c));selectedCompany=companyId;const newFloors=district.companyGroups.get(companyId).plan.floorCount;selectedFloor=newFloors>oldFloors?newFloors-1:Math.min(selectedFloor,newFloors-1);focusScene('company');return exportedCompanies().find(c=>c.id===companyId);}
 let initial=[{id:'orkest',name:'Orkest Code'}];try{const saved=localStorage.getItem('orkest.city.companies.v1');if(saved)initial=validateCompanies(JSON.parse(saved));}catch(e){showError(Error('Empresas salvas inválidas; restaurado o exemplo inicial. '+e.message));}
 syncCompanies(initial);renderProfiles();
 document.querySelectorAll('.scene-nav [data-scene]').forEach(b=>b.onclick=()=>focusScene(b.dataset.scene));
 document.querySelector('#company-form').onsubmit=e=>{e.preventDefault();const input=document.querySelector('#company-name'),name=input.value.trim();if(!name)return;try{const id=globalThis.crypto.randomUUID();syncCompanies([...companies,{id,name}]);input.value='';selectedCompany=id;focusScene('company');}catch(e){showError(e);}};
 document.querySelector('#remove-company').onclick=()=>{syncCompanies(companies.slice(0,-1));focusScene('overview');};
 document.querySelector('#apply-team').onclick=()=>{try{const c=currentCompany();if(c)setTeam(c.id,Number(document.querySelector('#team-count').value));}catch(e){showError(e);}};
 document.querySelector('#prev-floor').onclick=()=>{if(selectedFloor>0){selectedFloor--;focusScene('company');}};document.querySelector('#next-floor').onclick=()=>{const c=currentCompany();if(c&&selectedFloor<district.companyGroups.get(c.id).floors.length-1){selectedFloor++;focusScene('company');}};
 document.querySelector('#floor-select').onchange=e=>{selectedFloor=Number(e.target.value);focusScene('company');};
 document.querySelector('#replay').onclick=()=>{elapsed=0;paused=false;document.querySelector('#pause').textContent='Pausar';focusScene('overview');};
 document.querySelector('#pause').onclick=e=>{paused=!paused;e.target.textContent=paused?'Continuar':'Pausar';};
 const traffic=[];
 for(const [i,id]of ['sedan','hatch','suv','van','bus'].entries()){const object=assets.vehicle(id);district.root.add(object);traffic.push({id,object,offset:i*43,speed:i===1||i===3?2.1:3.1,route:i===1||i===3?{halfX:10,halfZ:12,radius:2}:undefined});}
 bicycle=new THREE.Group();const bikeModel=assets.stamp('y4_bike_sc',1.1);const bikeBounds=new THREE.Box3().setFromObject(bikeModel).getSize(new THREE.Vector3());if(bikeBounds.x>bikeBounds.z)bikeModel.rotation.y=-Math.PI/2;bicycle.add(bikeModel);district.root.add(bicycle);
 const pickRay=new THREE.Raycaster();let down;
 canvas.addEventListener('pointerdown',e=>down=[e.clientX,e.clientY]);
 function visible(object){for(let o=object;o;o=o.parent)if(!o.visible)return false;return true;}
 canvas.addEventListener('pointerup',e=>{if(e.button!==0||!down||Math.hypot(e.clientX-down[0],e.clientY-down[1])>5)return;const r=canvas.getBoundingClientRect();pickRay.setFromCamera(new THREE.Vector2((e.clientX-r.left)/r.width*2-1,-(e.clientY-r.top)/r.height*2+1),view.camera);
  const hit=pickRay.intersectObjects([...agents,...ambient],true).find(h=>visible(h.object));if(hit){const id=hit.object.userData.agent.userData.agentId;if(id){selectedCompany=hit.object.userData.agent.userData.companyId;renderProfiles();for(const b of profiles.querySelectorAll('[data-agent]'))if(b.dataset.agent===id)b.click();}return;}
  const building=pickRay.intersectObjects(district.interactables,true).find(h=>h.object.userData.companyId);if(building){selectedCompany=building.object.userData.companyId;focusScene('company');}
 });
 function frame(now){
  if(disposed)return;animation=requestAnimationFrame(frame);const dt=Math.min((now-last)/1000,.1);last=now;if(document.hidden)return;
  if(cameraMove){const t=Math.min((now-cameraMove.start)/700,1),ease=t*t*(3-2*t);view.camera.position.lerpVectors(cameraMove.from,cameraMove.position,ease);view.controls.target.lerpVectors(cameraMove.targetFrom,cameraMove.target,ease);if(t===1)cameraMove=null;view.dirty=true;}
  // Near/far hysteresis keeps full building silhouettes at city scale.
  let open=null;
  for(const [id,b]of district.companyGroups){const floor=id===selectedCompany?selectedFloor:Math.max(0,Math.min(b.floors.length-1,Math.round((view.controls.target.y-1.3)/FLOOR_HEIGHT))),targetDistance=Math.hypot(view.controls.target.x-b.lot.x,view.controls.target.z-b.lot.z),distance=view.camera.position.distanceTo(new THREE.Vector3(b.lot.x,1.3+floor*FLOOR_HEIGHT,b.lot.z));const near=targetDistance<7&&distance<(b.exterior.visible?25:30);b.setView(near,floor);if(near)open=id;}

  document.body.dataset.interior=open||'closed';let visibleAgents=0,visibleFloor=-1;for(const building of district.companyGroups.values())for(const floor of building.floors)if(floor.inner.visible){visibleAgents+=floor.occupants;visibleFloor=floor.level;}document.body.dataset.visibleAgents=String(visibleAgents);document.body.dataset.activeFloor=String(visibleFloor);
  if(!paused){elapsed+=dt;const state=officeArrival(elapsed);if(companies[0]){const entity=entities.get(companies[0].agents[0]?.id);if(entity){const actor=entity.actor,building=district.companyGroups.get(companies[0].id);actor.visible=!state.hidden;if(state.level==='ground'){if(actor.parent!==district.root)district.root.add(actor);actor.position.set(building.lot.x+state.x,.33,building.lot.z+state.z);}else{if(actor.parent!==building.floors[entity.floor].inner)building.floors[entity.floor].inner.add(actor);actor.position.set(state.x,.23,state.z);}actor.rotation.y=state.phase==='working'?Math.PI:state.yaw;setPose(actor,state.pose);}}document.body.dataset.phase=state.phase;district.crane.update(dt);cityLife.update(elapsed);
   for(const vehicle of traffic){const p=trafficState(elapsed*vehicle.speed+vehicle.offset,vehicle.route);vehicle.object.position.set(p.x,.16,p.z);vehicle.object.rotation.y=p.yaw;}
   const bike=trafficState(elapsed*1.7,{halfX:28.65,halfZ:32.65,radius:3.65});bicycle.position.set(bike.x,.16,bike.z);bicycle.rotation.y=bike.yaw;if(ambient[3].parent!==bicycle)bicycle.add(ambient[3]);ambient[3].position.set(0,.58,0);ambient[3].rotation.y=0;setPose(ambient[3],3);
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

 window.orkestCity={getInteractionMap(id){const c=companies.find(c=>c.id===id);if(!c)throw Error('Empresa não encontrada.');return interactionMap(c);},setCompanies(input){return syncCompanies(input);},getCompanies(){return exportedCompanies();},setAgents(companyId,input){return setTeam(companyId,input);},focusCompany(id){if(!district.companyGroups.has(id))throw Error('Empresa não encontrada.');selectedCompany=id;selectedFloor=COMMON_FLOORS;focusScene('company');}};
 document.addEventListener('visibilitychange',()=>{view.suspended=document.hidden;last=performance.now();view.dirty=true;});
 window.addEventListener('pagehide',()=>{disposed=true;cancelAnimationFrame(animation);delete window.orkestCity;const geometries=new Set(),materials=new Set();view.scene.traverse(o=>{if(o.geometry)geometries.add(o.geometry);for(const m of Array.isArray(o.material)?o.material:o.material?[o.material]:[])materials.add(m);});view.dispose();assets.dispose();district.dispose();cityLife.dispose();for(const g of geometries)g.dispose();for(const m of materials)m.dispose();},{once:true});
 view.controls.minDistance=3;view.controls.maxDistance=320;view.camera.position.set(66,64,82);view.controls.target.set(0,1,0);focusScene('overview');animation=requestAnimationFrame(frame);document.body.dataset.status='ready';document.querySelector('#loading').hidden=true;
}catch(e){cancelAnimationFrame(animation);view?.dispose();assets?.dispose();status.textContent='Falha ao carregar';error.hidden=false;error.textContent=e.stack||String(e);console.error(e);}
