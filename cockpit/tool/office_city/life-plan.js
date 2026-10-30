/** Extended rectangular city: dense centre, civic park, market and woodland. */
export const WORLD_BOUNDS={x0:-70,x1:150,z0:-58,z1:58};
export const DESTINATIONS=[{id:'forest',label:'Bosque & trilhas',x:139,z:0},{id:'leisure',label:'Parque & lago',x:91,z:7},{id:'fair',label:'Feira ao ar livre',x:90,z:-22},{id:'police',label:'Base da polícia',x:50,z:-25}];
export const LIFE_PROPS=[{id:'y4_swings_eu',height:2.6,x:69,z:-8,maxWidth:6,maxDepth:4},{id:'y4_slide_sh',height:2.3,x:70,z:-2,maxWidth:3,maxDepth:5},{id:'y4_picnic_eu',height:1.1,x:100,z:2,maxWidth:5,maxDepth:5}];
export const WALK_ROUTES=[
 [[-13.1,-29],[-13.1,-17]],[[13.1,-7],[13.1,7]],[[ -25,29],[-15,29]],[[ -6,30],[6,30]],
 [[-26.5,-6],[-13.5,-6],[-13.5,6],[-26.5,6]],
 [[71,14],[73,1],[82,-1],[87,8],[98,12],[104,19],[88,22]],
 [[74,-18],[104,-18],[104,-16.8],[77,-16.8]],
 [[135,-20],[140,-12],[137,0],[141,14],[134,24]],
];
export function pathState(points,distance,closed=true){
 const path=closed?[...points,points[0]]:points,lengths=path.slice(1).map((p,i)=>Math.hypot(p[0]-path[i][0],p[1]-path[i][1])),total=lengths.reduce((a,b)=>a+b,0);
 let d=closed?((distance%total)+total)%total:Math.max(0,Math.min(total,distance));
 for(let i=0;i<lengths.length;i++){if(d<=lengths[i]||i===lengths.length-1){const a=path[i],b=path[i+1],t=d/lengths[i];return{x:a[0]+(b[0]-a[0])*t,z:a[1]+(b[1]-a[1])*t,yaw:Math.atan2(b[0]-a[0],b[1]-a[1]),total};}d-=lengths[i];}
}
function distanceToSegment(x,z,a,b){const dx=b[0]-a[0],dz=b[1]-a[1],t=Math.max(0,Math.min(1,((x-a[0])*dx+(z-a[1])*dz)/(dx*dx+dz*dz)));return Math.hypot(x-a[0]-t*dx,z-a[1]-t*dz);}
export function forestPoints(){
 let seed=718;const rand=()=>((seed=(Math.imul(seed,1664525)+1013904223)>>>0)/4294967296),points=[];
 for(const [x0,x1,z0,z1,count]of [[-66,-50,-48,48,70],[134,147,-49,48,65],[52,126,-52,-39,70],[56,126,37,50,55]]){
  for(let attempt=0,placed=0;placed<count&&attempt<count*20;attempt++){const x=x0+rand()*(x1-x0),z=z0+rand()*(z1-z0);if(WALK_ROUTES[7].some((a,i)=>distanceToSegment(x,z,a,WALK_ROUTES[7][(i+1)%WALK_ROUTES[7].length])<1.7))continue;if(points.some(p=>Math.hypot(x-p.x,z-p.z)<1.4))continue;points.push({x,z,scale:.75+rand()*.65,type:Math.floor(rand()*3)});placed++;}
 }
 for(const [x,z,type,scale]of [[66,12,0,1.1],[68,20,2,1.2],[73,25,1,.9],[91,25,0,1.1],[106,24,2,1],[120,23,1,1],[115,-6,0,1.2],[112,-15,2,.9],[77,2,0,.9],[66,-15,1,1]])points.push({x,z,type,scale});
 return points;
}
