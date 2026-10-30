import {PROFILES,CATALOG_PROPS} from './scene-plan.js';
/** A single logical catalogue; original Studio IDs and provenance remain traceable. */
export function unifiedAssets(catalog){
 const entries=catalog.items.map(item=>({id:'studio:'+item.id,name:item.label,kind:item.kind,source:'study/vendor/'+item.module,available:item.kind!=='unavailable',license:'não determinada; estudo local'}));
 for(const id of ['office-building','workstation','library','cafe','residence','market','construction'])entries.push({id:'orkest:'+id,name:id,kind:'authored-3d',source:'district.js',available:true,license:'código próprio do projeto'});
 for(const p of PROFILES)entries.push({id:'habbo:'+p.id,name:p.name,kind:'appearance',source:'scene-plan.js + character-style.js',reference:'third_party/office_engine/shared/world/appearance-flat.ts + shared/appearance.ts',available:true,adaptation:'paletas e vocabulário pixel art, geometria 3D própria sobre people.d'});
 const unique=new Map();for(const item of entries)if(!unique.has(item.id))unique.set(item.id,item);
 return {version:1,entries:[...unique.values()],placements:CATALOG_PROPS,profiles:PROFILES,notes:['Os arquivos capturados permanecem preservados em generated, fora do Git.','Aparências 3D interpretam os estilos pixel art; não são conversão automática de sprites.','Prédios remotos e quatro packs binários não estão disponíveis.']};
}
