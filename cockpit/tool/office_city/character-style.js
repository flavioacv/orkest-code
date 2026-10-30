import * as THREE from 'three';
/** Original 3D interpretation of the pixel-art hair/accessory vocabulary. */
export function styleCharacter(profile,headY){
 const group=new THREE.Group();group.position.y=headY;
 const materials=new Map();
 function mat(color){if(!materials.has(color))materials.set(color,new THREE.MeshStandardMaterial({color,roughness:.9,flatShading:true}));return materials.get(color);}
 function box(c,x,y,z,w,h,d){const m=new THREE.Mesh(new THREE.BoxGeometry(w,h,d),mat(c));m.position.set(x,y,z);m.castShadow=true;group.add(m);return m;}
 function ball(c,x,y,z,r){const m=new THREE.Mesh(new THREE.IcosahedronGeometry(r,1),mat(c));m.position.set(x,y,z);m.castShadow=true;group.add(m);return m;}
 const h=profile.hair;
 if(profile.hairStyle==='buzz'){ball(h,0,.045,-.018,.139).scale.set(1,.7,1);}
 else if(profile.hairStyle==='afro'){for(let i=0;i<12;i++){const a=i/12*Math.PI*2;ball(h,Math.cos(a)*.13,.05+Math.sin(a)*.075,-.04+Math.sin(a)*.055,.093);}ball(h,0,.13,-.03,.14);}
 else if(profile.hairStyle==='curly'){for(let i=0;i<9;i++)ball(h,(i%3-1)*.09,.09+Math.floor(i/3)*.025,(Math.floor(i/3)-1)*.075,.075);}
 else{
  box(h,0,.095,-.018,.28,.12,.24);box(h,-.125,0,-.02,.055,.16,.2);box(h,.125,0,-.02,.055,.16,.2);
  if(profile.hairStyle==='bob'){box(h,0,-.07,-.11,.3,.25,.12);box(h,-.13,-.06,.03,.065,.2,.13);box(h,.13,-.06,.03,.065,.2,.13);}
  if(profile.hairStyle==='bun')ball(h,0,.16,-.09,.095);
  if(profile.hairStyle==='ponytail'){ball(h,0,.055,-.17,.075);box(h,0,-.075,-.19,.1,.24,.1);}
  if(profile.hairStyle==='side_part'){const fringe=box(h,-.035,.07,.12,.23,.1,.065);fringe.rotation.z=-.18;}
  if(profile.hairStyle==='spiky')for(let i=0;i<4;i++){const spike=new THREE.Mesh(new THREE.ConeGeometry(.06,.19,4),mat(h));spike.position.set(-.12+i*.08,.2,-.02);group.add(spike);}
 }
 // Eyes face forward (+Z), matching the original model.
 for(const x of [-.052,.052])box('#2b2530',x,-.012,.126,.022,.026,.016);
 if(profile.accessory==='glasses'){
  for(const x of [-.062,.062]){box('#2b2b33',x,.003,.14,.1,.014,.016);box('#2b2b33',x,-.045,.14,.1,.012,.016);for(const dx of [-.045,.045])box('#2b2b33',x+dx,-.022,.14,.01,.055,.016);}box('#2b2b33',0,-.012,.14,.034,.013,.016);
 }
 if(profile.accessory==='headphones'){for(const x of [-.17,.17])box(profile.top,x,-.02,0,.07,.13,.1);box('#2b2b33',0,.175,-.01,.35,.035,.07);}
 if(profile.accessory==='earrings')for(const x of [-.15,.15])ball('#f2c14e',x,-.09,.015,.022);
 if(profile.accessory==='cap'){box(profile.top,0,.12,0,.31,.12,.28);box(profile.top,0,.08,.16,.3,.03,.14);}
 return group;
}
