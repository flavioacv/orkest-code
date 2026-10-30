import {test} from 'node:test';
import assert from 'node:assert/strict';
import {characterState,ROUTE,WALK_SECONDS} from './walk-cycle.js';
test('percurso atravessa a porta antes de alcançar a estação',()=>{
 assert.deepEqual([characterState(0).x,characterState(0).z],ROUTE[0]);
 let crossed=false;
 for(let t=0;t<WALK_SECONDS;t+=.01){const s=characterState(t);assert.ok(Number.isFinite(s.x+s.z+s.yaw));if(s.z>5.9&&s.z<6.1){crossed=true;assert.equal(s.x,0);}if(s.z<6)assert.ok(Math.abs(s.x)<6.8);assert.ok(s.pose>=0&&s.pose<3);}
 assert.ok(crossed);const end=characterState(WALK_SECONDS);assert.equal(end.phase,'working');assert.equal(end.pose,3);assert.equal(end.x,ROUTE.at(-1)[0]);assert.ok(Math.abs(end.z-ROUTE.at(-1)[1])<1e-9);assert.deepEqual(characterState(100),end);
});
