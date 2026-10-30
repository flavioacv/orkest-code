import * as THREE from 'three';

/** Copies vertex data across Three.js versions; never mixes renderer objects. */
export function copyGeometry(source, palette) {
 const geometry=new THREE.BufferGeometry();
 for(const name of ['position','normal','uv','color']){
  const attr=source.attributes[name];if(!attr)continue;
  const values=new Float32Array(attr.count*attr.itemSize);
  for(let i=0;i<attr.count;i++)for(let j=0;j<attr.itemSize;j++)values[i*attr.itemSize+j]=attr.getComponent(i,j);
  geometry.setAttribute(name,new THREE.BufferAttribute(values,attr.itemSize));
 }
 if(source.index)geometry.setIndex(Array.from(source.index.array));
 const positions=geometry.attributes.position;
 if(!positions?.count)throw Error('Modelo do catálogo sem vértices.');
 for(const value of positions.array)if(!Number.isFinite(value))throw Error('Modelo do catálogo com coordenadas inválidas.');
 if(palette&&source.attributes.aSlot){
  const color=geometry.attributes.color||new THREE.Float32BufferAttribute(new Float32Array(positions.count*3).fill(1),3);
  for(let i=0;i<color.count;i++){
   const slot=Math.round(source.attributes.aSlot.getX(i));const tint=palette[slot];if(!tint)continue;
   const c=new THREE.Color(tint);color.setXYZ(i,color.getX(i)*c.r,color.getY(i)*c.g,color.getZ(i)*c.b);
  }geometry.setAttribute('color',color);
 }
 if(!geometry.attributes.normal)geometry.computeVertexNormals();
 geometry.computeBoundingBox();return geometry;
}

/** Loads only the generators used by this local scene, keeping captured bytes intact. */
export async function loadCatalogAssets(){
 const base='./generated/study/vendor/';
 const [{t:Geo},shapes,people,bridge,materials,cars]=await Promise.all([
  import(base+'geo-6J3HrpC4.js'),import(base+'shapes-CJnSlBeI.js'),import(base+'people-Bo_XNOUZ.js'),import(base+'study-meshes-bridge.js'),import(base+'materials-CtfbYfPn.js'),import(base+'vehicles-Bp2dhUqA.js')]);
 const modules=['european_draw-BfR-1DxW.js','shared_draw-BEGvGEkm.js','cyberpunk_draw-jCF9-zUO.js','metropolis_yb_draw-CPSdHJLu.js','metropolis_draw-BeTX-c34.js'];
 await Promise.all(modules.map(name=>import(base+name)));
 const material=new THREE.MeshStandardMaterial({vertexColors:true,roughness:.88,flatShading:true});
 const cache=new Map();
 function mesh(geometry){const object=new THREE.Mesh(geometry,material);object.castShadow=object.receiveShadow=true;return object;}
 function stamp(id,height){
  const key=id+':'+height;
  if(!cache.has(key)){
   if(!shapes.i(id))throw Error('Peça indisponível: '+id);
   const geo=new Geo();shapes.T(geo,shapes.E(id,0),0,0,0);const source=geo.toGeometry({keep:true});const geometry=copyGeometry(source);source.dispose();
   const bounds=geometry.boundingBox,size=bounds.getSize(new THREE.Vector3()),center=bounds.getCenter(new THREE.Vector3());
   if(size.y<=0)throw Error('Altura inválida: '+id);
   geometry.translate(-center.x,-bounds.min.y,-center.z);geometry.scale(height/size.y,height/size.y,height/size.y);cache.set(key,geometry);
  }const object=mesh(cache.get(key));object.userData.catalogId=id;return object;
 }
 function character(index){
  const group=new THREE.Group();const palette={1:['#4c8693','#b46f54','#6c885c','#aa874a'][index%4],2:'#354459',3:'#d4a17c',4:'#49392f'};
  for(let pose=0;pose<3;pose++){
   const source=people.d(index%2,pose).toGeometry();const geometry=copyGeometry(source,palette);source.dispose();const object=mesh(geometry);object.visible=pose===1;group.add(object);
  }
  // Local seated adaptation of the original neutral mesh; not an original pose.
  const seated=group.children[1].geometry.clone(),p=seated.attributes.position;
  for(let i=0;i<p.count;i++){const y=p.getY(i);if(y>=.85)p.setY(i,y-.2);else if(y>.42){p.setY(i,.48+(y-.42)*.4);p.setZ(i,p.getZ(i)+(.85-y)*.9);}else{p.setY(i,y/.42*.48);p.setZ(i,p.getZ(i)+.387);}}
  seated.computeVertexNormals();seated.computeBoundingBox();const seat=mesh(seated);seat.visible=false;group.add(seat);group.userData.catalogId='people.d';return group;
 }
 function crane(){
  const original=new materials.l.Group(),core={x0:-3,x1:3,z0:-3,z1:3,top:10,wallTop:8};let seed=123;
  const rand=()=>((seed=(Math.imul(seed,1664525)+1013904223)>>>0)/4294967296);
  const handle=bridge.studyCreateCrane({core,tall:true,small:false,group:original,inside:()=>true},24,24,rand,false);
  if(!handle)throw Error('Guindaste indisponível.');handle.root.scale.y=1;bridge.studyUpdateCrane(handle,0,core);
  const pairs=[];
  function convert(node){const target=node.geometry?mesh(copyGeometry(node.geometry)):new THREE.Group();pairs.push([node,target]);for(const child of node.children)target.add(convert(child));return target;}
  const object=convert(original);object.userData.catalogId='construction-crane';
  function update(dt){bridge.studyUpdateCrane(handle,dt,core);for(const [a,b]of pairs){b.position.copy(a.position);b.quaternion.copy(a.quaternion);b.scale.copy(a.scale);b.visible=a.visible;}}
  update(0);return {object,update};
 }
 function vehicle(id){const source=cars.u()[id];if(!source)throw Error('Veículo indisponível: '+id);const object=mesh(copyGeometry(source,{1:'#a5674f',2:'#435965',3:'#8b9c9d',4:'#d5c39c'}));object.userData.catalogId=id;return object;}
 function dispose(){const geometries=new Set(cache.values());for(const geometry of geometries)geometry.dispose();material.dispose();}
 return {stamp,character,crane,vehicle,dispose};
}
