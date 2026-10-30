/** Authored route uses the entrance and the aisle, in office-local metres. */
export const ROUTE=[[0,9],[0,6.2],[0,4.8],[-4.8,4.8],[-4.8,2.05]];
export const WALK_SECONDS=12;
export function characterState(seconds){
 const time=Math.max(0,seconds),lengths=ROUTE.slice(1).map((p,i)=>Math.hypot(p[0]-ROUTE[i][0],p[1]-ROUTE[i][1]));
 const total=lengths.reduce((a,b)=>a+b,0);let distance=Math.min(time/WALK_SECONDS,1)*total;
 for(let i=0;i<lengths.length;i++){
  if(distance<=lengths[i]||i===lengths.length-1){const a=ROUTE[i],b=ROUTE[i+1],t=Math.min(1,distance/lengths[i]);return{x:a[0]+(b[0]-a[0])*t,z:a[1]+(b[1]-a[1])*t,yaw:Math.atan2(b[0]-a[0],b[1]-a[1]),phase:time>=WALK_SECONDS?'working':time<2.5?'outside':'entering',pose:time>=WALK_SECONDS?3:Math.floor(time*6)%3};}distance-=lengths[i];
 }
}

/** Door/elevator hand-off keeps arrivals at street height until they are inside. */
export function officeArrival(seconds){
 const t=Math.max(0,seconds),walkPose=Math.floor(t*6)%3;
 if(t<3)return{x:0,z:9-(9-6.2)*t/3,yaw:Math.PI,pose:walkPose,phase:'outside',level:'ground',hidden:false};
 if(t<5)return{x:0,z:6.2-(6.2-5.4)*(t-3)/2,yaw:Math.PI,pose:walkPose,phase:'entering',level:'ground',hidden:false};
 if(t<8)return{x:0,z:5.4,yaw:Math.PI,pose:1,phase:'elevator',level:'ground',hidden:true};
 const progress=Math.min((t-8)/4,1),length=4.8+2.75,distance=progress*length;
 const x=distance<=4.8?-distance:-4.8,z=distance<=4.8?4.8:4.8-(distance-4.8);
 return{x,z,yaw:distance<4.8?-Math.PI/2:Math.PI,pose:t>=12?3:walkPose,phase:t>=12?'working':'entering',level:'office',hidden:false};
}
