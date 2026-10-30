import * as THREE from 'three';
const unitBox=new THREE.BoxGeometry(1,1,1);
/** Authored facade kit: varied storeys, roofs, shopfronts and street detail, instanced by color. */
export function urbanBuilding(view,{w=5,d=8,floors=3,color='#c4b299',trim='#ede3d0',roof='#716d64',style='stone',shop='',seed=1}={}){
 const group=new THREE.Group(),batches=new Map(),height=floors*2.7,front=d/2;
 function box(c,x,y,z,sx,sy,sz,ry=0){if(!batches.has(c))batches.set(c,[]);const matrix=new THREE.Matrix4().compose(new THREE.Vector3(x,y,z),new THREE.Quaternion().setFromAxisAngle(new THREE.Vector3(0,1,0),ry),new THREE.Vector3(sx,sy,sz));batches.get(c).push(matrix);}
 box(color,0,height/2,0,w,height,d);box(trim,0,.24,0,w+.18,.32,d+.18);
 const columns=Math.max(2,Math.floor(w/1.8)),spacing=w/(columns+.4);
 for(let level=0;level<floors;level++){
  const y=level*2.7+1.55;
  if(level===0&&shop){
   for(const x of [-w*.27,w*.27]){box('#4e6469',x,1.2,front+.045,w*.38,1.9,.075);box('#b4c1b7',x,1.26,front+.1,w*.32,1.55,.03);for(const dx of [-w*.17,0,w*.17])box(trim,x+dx,1.2,front+.13,.055,1.95,.05);}
   box(trim,0,1.15,front+.14,.16,2.3,.18);
  }else for(let col=0;col<columns;col++){
   const x=(col-(columns-1)/2)*spacing,ww=Math.min(1.12,spacing*.65),hh=style==='warehouse'?1.65:1.35;
   box('#667d81',x,y,front+.025,ww+.1,hh+.12,.06);box('#adbbb7',x,y,front+.075,ww,hh,.045);
   for(const dx of [-ww/2,0,ww/2])box(trim,x+dx,y,front+.11,.055,hh+.15,.055);
   box(trim,x,y,front+.12,ww,.055,.055);box(trim,x,y-hh/2-.1,front+.15,ww+.25,.16,.28);box(trim,x,y+hh/2+.1,front+.08,ww+.22,.12,.12);
   if(style==='townhouse'||style==='timber'){for(const dx of [-ww/2-.17,ww/2+.17])box(roof,x+dx,y,front+.09,.18,hh+.1,.07);}
   if(style==='artdeco'){box(trim,x,y+.95,front+.07,.12,.5,.12);}
   if(style==='brick'&&level===1){box(trim,x,y-.9,front+.5,ww+.4,.12,.9);for(const dx of [-ww/2,0,ww/2])box('#535d5a',x+dx,y-.5,front+.91,.035,.7,.04);box('#535d5a',x,y-.16,front+.91,ww+.15,.05,.05);}
  }
  // Side facade has its own windows instead of a blank block.
  for(const z of [-d*.29,d*.06,d*.35]){box('#839b9e',w/2+.025,y,z,.06,1.3,1.0);box(trim,w/2+.08,y-.77,z,.2,.15,1.2);box(trim,w/2+.08,y,z,.05,1.3,.06);}
  for(const z of [-front,front])box(trim,0,level*2.7+.12,z,w+.22,.14,.2);
 }
 if(style==='brick'||style==='stone')for(let row=0;row<Math.floor(height/.4);row++){
  const y=.4+row*.4;for(let j=0;j<columns+1;j++)box(style==='brick'?'#98624e':'#b5a895',(j-columns/2)*w/(columns+1)+(row%2)*.12,y,front+.012,.42,.025,.01);
 }
 if(style==='townhouse'||style==='timber'){
  const shape=new THREE.Shape();shape.moveTo(-w/2-.18,0);shape.lineTo(w/2+.18,0);shape.lineTo(0,2.3);shape.closePath();const geometry=new THREE.ExtrudeGeometry(shape,{depth:d+.4,bevelEnabled:false});geometry.translate(0,height,-d/2-.2);const mesh=new THREE.Mesh(geometry,view.material(roof));mesh.castShadow=true;group.add(mesh);
  box(trim,0,height+.65,front+.22,1.0,.85,.08);box('#81999b',0,height+.65,front+.28,.73,.62,.03);
  box(color,-w*.29,height+1.2,-d*.2,.42,2,.55);
  if(style==='timber')for(const y of [2.7,5.4,8.1])if(y<height)box('#645343',0,y,front+.14,w,.14,.1);
 }else{
  box(roof,0,height+.12,0,w+.4,.24,d+.4);for(const x of [-w/2,w/2])box(trim,x,height+.35,0,.2,.5,d+.3);for(const z of [-front,front])box(trim,0,height+.35,z,w+.3,.5,.2);
  const ventColor=seed%2?'#9eaaa5':'#b3b1a7';for(let i=0;i<1+seed%3;i++){box(ventColor,-w*.22+i*.9,height+.46,-d*.2, .65,.55,.95);box('#75817e',-w*.22+i*.9,height+.76,-d*.2,.52,.04,.65);}
 }
 if(shop){
  for(let i=0;i<6;i++)box(i%2?trim:roof,-w*.44+i*w*.176,2.35,front+.65,w*.177,.12,1.3);
  const canvas=document.createElement('canvas');canvas.width=512;canvas.height=96;const ctx=canvas.getContext('2d');ctx.fillStyle=roof;ctx.fillRect(0,0,512,96);ctx.fillStyle='#f5ead8';ctx.font='600 40px sans-serif';ctx.textAlign='center';ctx.fillText(shop,256,63,490);const texture=new THREE.CanvasTexture(canvas);texture.colorSpace=THREE.SRGBColorSpace;
  const sign=new THREE.Mesh(new THREE.PlaneGeometry(w*.9,.6),new THREE.MeshBasicMaterial({map:texture}));sign.position.set(0,2.85,front+.2);group.add(sign);group.userData.textures=[texture];
 }else{box('#5c6f69',0,.95,front+.15,.95,1.9,.12);box(trim,0,.11,front+.6,1.4,.15,.9);}
 if(style==='artdeco')for(const x of [-w*.45,w*.45])box(trim,x,height/2,front+.2,.22,height,.32);
 if(style==='warehouse'){
  box('#5a6a68',-w*.22,.9,front+.18,w*.35,1.8,.1);for(let i=0;i<7;i++)box('#7c8880',-w*.22,.2+i*.23,front+.24,w*.32,.035,.04);
  box('#b69872',w*.28,1.1,front+.3,.6,2.2,.3);
 }
 for(const [c,matrices]of batches){const mesh=new THREE.InstancedMesh(unitBox,view.material(c),matrices.length);matrices.forEach((m,i)=>mesh.setMatrixAt(i,m));mesh.castShadow=mesh.receiveShadow=true;mesh.computeBoundingSphere();group.add(mesh);}
 group.userData.urban={w,d,floors,style,shop,height:height+(style==='townhouse'||style==='timber'?2.3:.9)};return group;
}
