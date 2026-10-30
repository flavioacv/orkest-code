/** Authored route uses the entrance and the aisle, in office-local metres. */
export const ROUTE=[[0,9],[0,6.2],[0,4.8],[-4,4.8],[-4,2.05]];
export const WALK_SECONDS=12;
export function characterState(seconds){
 const time=Math.max(0,seconds),lengths=ROUTE.slice(1).map((p,i)=>Math.hypot(p[0]-ROUTE[i][0],p[1]-ROUTE[i][1]));
 const total=lengths.reduce((a,b)=>a+b,0);let distance=Math.min(time/WALK_SECONDS,1)*total;
 for(let i=0;i<lengths.length;i++){
  if(distance<=lengths[i]||i===lengths.length-1){const a=ROUTE[i],b=ROUTE[i+1],t=Math.min(1,distance/lengths[i]);return{x:a[0]+(b[0]-a[0])*t,z:a[1]+(b[1]-a[1])*t,yaw:Math.atan2(b[0]-a[0],b[1]-a[1]),phase:time>=WALK_SECONDS?'working':time<2.5?'outside':'entering',pose:time>=WALK_SECONDS?3:Math.floor(time*6)%3};}distance-=lengths[i];
 }
}
