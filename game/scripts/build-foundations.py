"""Rebuild the authored Foundations prototype catalog. No player saves are touched."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
path = ROOT / 'godot/data/cards.json'
old = json.loads(path.read_text(encoding='utf-8-sig'))
cards = [c for c in old['sets'][0]['cards'] if c['id'].startswith('home-')]
for c in cards:
    c.setdefault('type', 'minion')
    c.setdefault('rarity', 'common')
    c['set'] = 'foundations'

# Rows: name | cost | attack/health (or spell) | rarity | effects.
# D damage, A armor, H hero heal, C draw, R empty-crystal ramp,
# E enemy-board damage, X both boards, B friendly-board buff,
# W friendly-board healing, S summon, P same-element board buff.
rows = {
'fire': '''Cinder Moth|1|2/1|common|stealth
Coalback Pup|2|2/2|common|deathfinch
Kiln Keeper|2|1/3|common|A2
Ash Courier|3|2/3|rare|C1
Flare Fox|3|4/2|common|D1
Hearth Turtle|3|2/4|common|taunt
Ember Ram|4|4/3|common|rush
Furnace Beetle|4|3/5|rare|A3
Cinder Captain|5|4/4|rare|aura1
Lava Salamander|5|5/4|rare|E1
Pyre Roc|6|6/5|epic|D2
Volcano Drake|7|6/7|epic|E2
Ashen Colossus|8|8/8|epic|X2
Solara, First Flame|10|8/8|legendary|E4
Kindle|0|spell|common|A1
Flame Lance|2|spell|common|D3;combo5
Stoke the Hearth|2|spell|common|A3;C1
Ember Chorus|3|spell|rare|P2/0
Brushfire|3|spell|common|E2
Fuel the Fire|3|spell|rare|C2
Scorching Wave|5|spell|rare|E3
Meteor Fall|6|spell|epic|D8
Worldfire|8|spell|epic|Y7''',
'water': '''Dewdrop Newt|2|1/2|common|poisonous
Reef Otter|2|2/3|common|lifesteal
Pearl Keeper|2|1/3|common|H2
Brook Guide|3|2/3|rare|C1
Coral Defender|3|2/4|common|taunt
Mist Heron|3|3/3|common|H2
Tidepool Mystic|4|3/5|rare|W2
Shellback Tortoise|4|2/4|common|taunt;shield
River Stag|5|4/6|rare|H4
Reef Conductor|5|4/4|rare|healthaura1
Glacier Whale|6|5/7|epic|taunt
Pearl Leviathan|7|6/7|epic|H6
Moonwell Serpent|8|6/8|epic|C2
Nerissa, Deep Song|10|7/10|legendary|H8;W8
Sea Glass|3|spell|common|silence
Undertow|2|spell|common|D3;freezetarget
Clearwater|2|spell|common|C1;H2
Restoring Rain|3|spell|rare|W4;H4
Deep Current|3|spell|rare|C2
Coral Bloom|4|spell|rare|P1/2
Crashing Surf|5|spell|common|E3;freeze
Tidal Renewal|6|spell|epic|H8;C2
Call the Reef|7|spell|epic|S2/home-shore-guard;H4''',
'earth': '''Mossback Cub|2|2/3|common|
Pebble Sentry|2|1/4|common|taunt
Resin Tender|3|2/4|rare|A3
Root Digger|3|2/2|rare|R1
Granite Badger|4|3/6|common|taunt
Grove Keeper|4|3/4|common|H3
Stonehorn Elk|5|5/6|common|
Rootbound Elder|5|3/6|rare|P1/1
Resin Golem|6|4/8|rare|taunt;A3
Mountain Mammoth|7|7/8|epic|
Ancient Grove|8|6/10|epic|taunt;H4
Orun, Living Mountain|10|9/12|legendary|taunt
Pebble Ward|2|spell|common|secretarmor
Resin Salve|1|spell|common|H3
Stone Skin|2|spell|common|A5
Deep Roots|2|spell|rare|choose
Earthen Spear|3|spell|common|weapon;deatharmor
Wild Growthsong|3|spell|rare|P1/2
Reclaim|4|spell|rare|A4;C2
Crab Colony|4|spell|common|S3/home-resin-crab
Earthquake|6|spell|epic|X5
Mountain's Gift|8|spell|epic|A8;S2/home-shore-guard''',
'air': '''Wispwing|1|1/2|common|
Cloud Hare|2|3/2|common|
Gale Messenger|2|1/2|rare|C1
Skyfin Ray|3|2/2|common|charge
Wind Archivist|3|2/3|rare|spellpower
Storm Kite|4|4/3|common|D1
Cloud Shepherd|4|2/4|rare|S1/home-breeze-finch
Zephyr Dancer|4|3/4|common|windfury
Flock Captain|5|3/5|rare|adjacent2
Thunder Roc|6|6/5|epic|D2
Sky Librarian|7|5/7|epic|C2
Nimbus Guardian|8|7/9|epic|taunt
Aella, Open Sky|10|7/7|legendary|S2/home-breeze-finch;B1/1
Tailwind|0|spell|common|B1/0
Feather Ward|1|spell|common|targetbuff
Gust Bolt|1|spell|common|D3;overload1
Fresh Breeze|3|spell|rare|countersecret
Gather the Flock|3|spell|common|S2/home-breeze-finch
Rising Winds|3|spell|rare|P1/1
Windfall|2|spell|rare|discover
Thunderhead|5|spell|common|E3
Skyward Chorus|6|spell|epic|B2/2
Eye of the Storm|8|spell|epic|E3;C2'''
}

def effect(code, element):
    kind, value = code[0], code[1:]
    if kind in 'BP':
        a, h = map(int, value.split('/'))
        return {'effect':'buffAll' if kind=='B' else 'buffElement','attack':a,'health':h}, f'Give your {element.title()+" " if kind=="P" else ""}minions +{a}/+{h}.'
    if kind == 'S':
        count, target = value.split('/')
        name = next(c['name'] for c in cards if c['id']==target)
        return {'effect':'summon','amount':int(count),'card':target}, f'Summon {count} {name}'+('.' if count=='1' else 's.')
    v = int(value)
    names = {'D':'damage','A':'gainArmor','H':'healCaster','C':'draw','R':'ramp','E':'damageEnemies','Y':'damageAll','X':'damageBoard','W':'healBoard'}
    texts = {'D':f'Deal {v} damage.', 'A':f'Gain {v} Armor.', 'H':f'Restore {v} Health to your hero.', 'C':f'Draw {v} card'+('.' if v==1 else 's.'), 'R':f'Gain {v} empty Mana Crystal.', 'E':f'Deal {v} damage to all enemy minions.', 'Y':f'Deal {v} damage to ALL characters.', 'X':f'Deal {v} damage to ALL minions.', 'W':f'Restore {v} Health to your minions.'}
    return {'effect':names[kind],'amount':v}, texts[kind]

for element, block in rows.items():
    for row in block.splitlines():
        name, cost, stats, rarity, effects = row.split('|')
        ident = ''.join(c.lower() if c.isalnum() else '-' for c in name).strip('-')
        while '--' in ident: ident=ident.replace('--','-')
        c = {'id':element+'-'+ident,'name':name,'element':element,'type':'spell' if stats=='spell' else 'minion','rarity':rarity,'cost':int(cost),'set':'foundations'}
        if stats!='spell': c['attack'], c['health'] = map(int,stats.split('/'))
        rules=[]; actions=[]
        for code in filter(None,effects.split(';')):
            if code.startswith('healthaura'): c['auraHealth']=int(code[10:]); rules.append(f'Your other minions have +{code[10:]} Health.'); continue
            if code.startswith('adjacent'): c['auraAttack']=int(code[8:]); c['auraAdjacent']=True; rules.append(f'Adjacent minions have +{code[8:]} Attack.'); continue
            if code=='discover': actions.append({'effect':'discover'}); rules.append('Discover an Air minion.'); continue
            if code=='choose': c['choices']=[{'name':'Grow','text':'Gain an empty Mana Crystal.','effects':[{'effect':'ramp','amount':1}]},{'name':'Shelter','text':'Gain 6 Armor.','effects':[{'effect':'gainArmor','amount':6}]}]; rules.append('Choose One: Gain an empty Mana Crystal; or gain 6 Armor.'); continue
            if code=='countersecret': c['secret']={'trigger':'spellPlayed','effects':[]}; rules.append('Secret: When your opponent casts a spell, counter it.'); continue
            if code=='secretarmor': c['secret']={'trigger':'heroAttacked','effects':[{'effect':'gainArmor','amount':8}]}; rules.append('Secret: When your hero is attacked, gain 8 Armor.'); continue
            if code=='freezetarget': c['targeting']='optionalCreature'; actions.append({'effect':'freezeTarget'}); rules.append('Freeze the target.'); continue
            if code=='weapon': c['type']='weapon'; c['attack']=3; c['durability']=2; actions.append({'effect':'equipWeapon','attack':3,'durability':2}); rules.append('Equip a 3/2 Earthen Spear.'); continue
            if code=='targetbuff': c['targeting']='optionalCreature'; c['targetSide']='friendly'; actions.append({'effect':'buffTarget','attack':1,'health':2}); rules.append('Give a friendly minion +1/+2.'); continue
            if code=='silence': actions.append({'effect':'silenceEnemies'}); rules.append('Silence all enemy minions.'); continue
            if code.startswith('aura'): c['auraAttack']=int(code[4:]); rules.append(f'Your other minions have +{code[4:]} Attack.'); continue
            if code=='freeze': actions.append({'effect':'freezeEnemies'}); rules.append('Freeze all enemy minions.'); continue
            if code.startswith('combo'): c['combo']=[{'effect':'damage','amount':int(code[5:])}]; rules.append(f'Combo: Deal {code[5:]} damage instead.'); continue
            if code.startswith('overload'): c['overload']=int(code[8:]); rules.append(f"Overload: ({c['overload']})."); continue
            if code=='deathfinch': c['deathrattle']=[{'effect':'summon','card':'home-breeze-finch','amount':1}]; rules.append('Deathrattle: Summon a Breeze Finch.'); continue
            if code=='deatharmor': c['deathrattle']=[{'effect':'gainArmor','amount':2}]; rules.append('Deathrattle: Gain 2 Armor.'); continue
            if code=='taunt': c['taunt']=True; rules.append('Taunt.'); continue
            if code=='spellpower': c['spellDamage']=1; rules.append('Spell Damage +1.'); continue
            if code=='shield': c['divineShield']=True; rules.append('Divine Shield.'); continue
            if code in ('rush','charge','windfury','stealth','poisonous','lifesteal'): c[code]=True; rules.append(code.title()+'.'); continue
            action, text = effect(code,element)
            if action['effect']=='damage': c['targeting']='optionalCreature'
            actions.append(action)
            rules.append(text)
        if actions: c['onPlay']=actions
        if stats!='spell' and actions:
            at=1 if c.get('taunt') else 0
            rules[at]='Battlecry: '+rules[at]
        c['text']=' '.join(rules)
        c['art']= {'fire':'home-emberling','water':'home-tideling','earth':'home-mossling','air':'home-cloudling'}[element] if stats!='spell' else {'fire':'home-spark','water':'home-mending-tide','earth':'home-shore-guard','air':'home-breeze-finch'}[element]
        c['artStatus']='dedicated original illustration; assets/cards/manifest.json'
        cards.append(c)

assert len(cards)==100
assert len({c['id'] for c in cards})==100
assert all(sum(c['element']==e for c in cards)==25 for e in rows)
assert sum(c['type']=='minion' for c in cards)==60
path.write_text(json.dumps({'sets':[{'id':'foundations','name':'Foundations','cards':cards}]},indent=2)+'\n',encoding='utf-8')
print('Foundations: 100 cards; 25 per element; 60 minions / 39 spells / 1 weapon.')
