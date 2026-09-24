import sqlite3, json, re, os, math, shutil
from pathlib import Path
DB=Path('/mnt/data/work_ashendb/AshenDB/tools/work/tortoise.sqlite')
ROOT=Path('/mnt/data/build061/AshenBuilds/Data/AshenDB/Data')
con=sqlite3.connect(DB); con.row_factory=sqlite3.Row
c=con.cursor()

def esc(s):
    s=str(s or '').replace('\\','\\\\').replace('"','\\"').replace('\r',' ').replace('\n',' ')
    return '"'+s+'"'

def fmt_num(v):
    if v is None: return '0'
    if isinstance(v,float) and v.is_integer(): return str(int(v))
    return ('%.4f'%float(v)).rstrip('0').rstrip('.')

def spell_text(row):
    text=(row['description'] or row['auraDescription'] or row['name'] or '').strip()
    vals={1:row['s1'],2:row['s2'],3:row['s3']}
    # Replace common DBC tokens conservatively.
    for i,v in vals.items():
        if v is None: v=0
        text=re.sub(r'\$s'+str(i)+r'\b', fmt_num(v), text)
        text=re.sub(r'\$m'+str(i)+r'\b', fmt_num(v), text)
        text=re.sub(r'\$M'+str(i)+r'\b', fmt_num(v), text)
    text=re.sub(r'\$d\b', '', text)
    text=re.sub(r'\$t\d*\b', '', text)
    text=re.sub(r'\$[A-Za-z]\d*', '', text)
    text=re.sub(r'\s+([.,])', r'\1', text)
    text=re.sub(r'\s{2,}', ' ', text).strip()
    return text

spells={r['entry']:r for r in c.execute('select * from spells')}
items={r['entry']:r for r in c.execute('select * from items')}
item_names={k:v['name'] for k,v in items.items()}
zone_names={r['areaid']:r['name'] for r in c.execute('select * from zones')}
zone_names.update({r['entry']:r['name'] for r in c.execute('select * from areas') if r['entry'] not in zone_names})
creatures={r['entry']:r for r in c.execute('select * from creatures')}
quests={r['entry']:r for r in c.execute('select * from quests')}
prof={164:'Blacksmithing',165:'Leatherworking',171:'Alchemy',182:'Herbalism',185:'Cooking',186:'Mining',197:'Tailoring',202:'Engineering',333:'Enchanting',356:'Fishing',129:'First Aid',393:'Skinning',755:'Jewelcrafting'}

# Details
D={}
for iid,r in items.items():
    if int(r['inventory_type'] or 0) not in {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,28}: continue
    bind={1:'Binds when picked up',2:'Binds when equipped',3:'Binds when used',4:'Quest Item'}.get(int(r['bonding'] or 0),'')
    effects=[]
    for i in range(1,6):
        sid=int(r[f'spellid_{i}'] or 0); trig=int(r[f'spelltrigger_{i}'] or 0)
        if not sid: continue
        sr=spells.get(sid)
        txt=spell_text(sr) if sr else f'Spell {sid}'
        if txt: effects.append((trig,txt,sid))
    D[iid]=(bind,int(r['max_durability'] or 0),int(r['sell_price'] or 0),r['description'] or '',int(r['required_skill'] or 0),int(r['required_skill_rank'] or 0),int(r['required_reputation_faction'] or 0),int(r['required_reputation_rank'] or 0),effects)

# Sources
S={}
# crafted
for r in c.execute('select sc.spell, sc.item, sc.skill, sc.skill_min, sc.skill_req from spell_creates sc').fetchall():
    iid=r['item']; sid=r['spell']
    if iid not in items: continue
    sr=spells.get(sid); recipe=(sr['name'] if sr else item_names.get(iid,''))
    reag=[]
    for rr in con.execute('select item,count from spell_reagent where spell=? order by count desc,item',(sid,)).fetchall():
        reag.append((rr['item'],item_names.get(rr['item'],f'Item {rr["item"]}'),rr['count']))
    S.setdefault(iid,[]).append(('craft',sid,recipe,prof.get(r['skill'],f'Skill {r["skill"]}'),int(r['skill_min'] or 0),int(r['skill_req'] or 0),0,reag))
# creature drops only direct
for r in c.execute("select d.owner,d.item,d.chance,d.mincount,d.maxcount,c.name,c.zone from drops d join creatures c on c.entry=d.owner where d.src='c' and d.item is not null"):
    if r['item'] not in items: continue
    S.setdefault(r['item'],[]).append(('drop',r['owner'],r['name'] or f'Creature {r["owner"]}',zone_names.get(r['zone'],''),float(r['chance'] or 0),int(r['mincount'] or 1),int(r['maxcount'] or 1)))
# vendors
for r in c.execute('select nv.entry,nv.item,nv.maxcount,c.name,c.zone from npc_vendor nv left join creatures c on c.entry=nv.entry where nv.item is not null'):
    if r['item'] not in items: continue
    S.setdefault(r['item'],[]).append(('vendor',r['entry'],r['name'] or f'Vendor {r["entry"]}',zone_names.get(r['zone'],''),int(r['maxcount'] or 0)))
# quests rewards and choices
for r in c.execute("select qi.quest,qi.item,qi.role,qi.count,q.title,q.zone,q.level from quest_item qi join quests q on q.entry=qi.quest where qi.role in ('reward','choice') and qi.item is not null"):
    if r['item'] not in items: continue
    S.setdefault(r['item'],[]).append(('quest',r['quest'],r['title'] or f'Quest {r["quest"]}',zone_names.get(r['zone'],''),r['role'],int(r['count'] or 1),int(r['level'] or 0)))

# Sets
SETS={}
for r in c.execute('select id,name from item_sets'):
    SETS[r['id']]={'name':r['name'] or f'Set {r["id"]}','items':[],'bonuses':[]}
for iid,r in items.items():
    sid=int(r['set_id'] or 0)
    if sid and sid in SETS: SETS[sid]['items'].append((iid,r['name']))
for r in c.execute('select setid,threshold,spell from item_set_bonus order by setid,threshold'):
    if r['setid'] not in SETS: continue
    sr=spells.get(r['spell']); txt=spell_text(sr) if sr else f'Spell {r["spell"]}'
    SETS[r['setid']]['bonuses'].append((int(r['threshold'] or 0),int(r['spell'] or 0),txt))

# write shards helper

def lua_val(v):
    if isinstance(v,str): return esc(v)
    if isinstance(v,bool): return 'true' if v else 'false'
    if v is None: return 'nil'
    if isinstance(v,(int,float)): return fmt_num(v)
    if isinstance(v,(list,tuple)): return '{'+','.join(lua_val(x) for x in v)+'}'
    if isinstance(v,dict):
        parts=[]
        for k,val in v.items(): parts.append(k+'='+lua_val(val))
        return '{'+','.join(parts)+'}'
    raise TypeError(v)

def write_shards(folder,prefix,var,data,per=800):
    p=ROOT/folder
    if p.exists(): shutil.rmtree(p)
    p.mkdir(parents=True)
    ids=sorted(data)
    files=[]
    for n,start in enumerate(range(0,len(ids),per),1):
        fn=f'{prefix}_{n:03d}.lua'; files.append(f'Data\\AshenDB\\Data\\{folder}\\{fn}')
        with (p/fn).open('w',encoding='utf-8',newline='\n') as f:
            f.write(f'local T = AshenDB.{var}\n')
            for iid in ids[start:start+per]: f.write(f'T[{iid}]={lua_val(data[iid])}\n')
    return files

detail_files=write_shards('Details','Details','ItemDetails',D,800)
source_files=write_shards('Sources','Sources','ItemSources',S,450)
set_files=write_shards('Sets','Sets','ItemSets',SETS,120)

# update Core namespace
core=ROOT.parent/'Core.lua'
text=core.read_text(encoding='utf-8')
if 'AshenDB.ItemSets' not in text: text += '\nAshenDB.ItemSets = AshenDB.ItemSets or {}\n'
core.write_text(text,encoding='utf-8')

# rebuild toc portions from current, using generated paths
addon=ROOT.parents[2]
toc=addon/'AshenBuilds.toc'
lines=toc.read_text(encoding='utf-8').splitlines()
out=[]
for line in lines:
    if ('Data\\AshenDB\\Data\\Details\\' in line or 'Data\\AshenDB\\Data\\Sources\\' in line or 'Data\\AshenDB\\Data\\Sets\\' in line): continue
    if line=='Data\\AshenDBAdapter.lua':
        out.extend(detail_files); out.extend(source_files); out.extend(set_files)
    out.append(line)
toc.write_text('\n'.join(out)+'\n',encoding='utf-8')
print('details',len(D),'sources items',len(S),'sets',len(SETS),'files',len(detail_files),len(source_files),len(set_files))
print('lionheart',D.get(12640),S.get(12640))
