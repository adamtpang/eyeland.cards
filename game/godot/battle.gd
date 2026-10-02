extends RefCounted
## Deterministic two-sided combat for the Foundations catalog.
var cards: Dictionary
var sides: Array = []
var active = 0
var outcome = -1
var turn = 0
var log: Array[String] = []
var job: Dictionary
var serial = 0
var mulligan_pending=false
var shuffle_rng=RandomNumberGenerator.new()
var enemy_name="Crab"
var first_player=0
var enemy_power=true  # wild creatures have no class power
var opponent_mulligan_count=0
var pending_choice: Dictionary={}
var pending_attack: Dictionary={}
var revealed_secrets: Array=[]
var combat_events: Array=[]
var spell_hits: Array=[]
var healing_events: Array=[]
var buff_events: Array=[]
var timeline: Array=[]

func record_event(kind: String,event: Dictionary,timeline_position: int=-1):
	var entry=event.duplicate(true)
	entry.kind=kind
	entry.sequence=timeline.size()
	entry.turn=turn
	if timeline_position<0: timeline.append(entry)
	else:
		timeline.insert(timeline_position,entry)
		for index in range(timeline_position,timeline.size()): timeline[index].sequence=index
	match kind:
		"combat": combat_events.append(event)
		"spell_hit": spell_hits.append(event)
		"heal": healing_events.append(event)
		"buff": buff_events.append(event)
		"secret": revealed_secrets.append(event)
var death_queue: Array=[]
var weapon_deaths: Array=[]
var death_replacements: Dictionary={}
var resolving_death: Dictionary={}

func _init(catalog: Dictionary, deck: Array, enemy: Array, hp: int, enemy_hp: int, class_data: Dictionary, seed_value: int, opening_choice: bool=false,starting_player: int=0):
	cards = catalog.duplicate(true)
	var order_rng=RandomNumberGenerator.new()
	order_rng.seed=seed_value+104729
	first_player=order_rng.randi_range(0,1) if starting_player==-1 else clampi(starting_player,0,1)
	shuffle_rng.seed=seed_value+7919
	cards["the-coin"]={"id":"the-coin","name":"The Coin","type":"spell","cost":0,"text":"Gain 1 Mana Crystal this turn only.","onPlay":[{"effect":"gainMana","amount":1}]}
	job = class_data
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	for ids in [deck,enemy]:
		var shuffled = ids.duplicate()
		for i in range(shuffled.size()-1,0,-1):
			var j = rng.randi_range(0,i)
			var tmp = shuffled[i]
			shuffled[i] = shuffled[j]
			shuffled[j] = tmp
		sides.append({"deck":shuffled,"hand":[],"board":[],"hp":hp if sides.is_empty() else enemy_hp,"max_hp":hp if sides.is_empty() else enemy_hp,"armor":0,"mana":0,"max_mana":0,"fatigue":0,"power_used":false})
	sides[0].max_hp = 30
	for p in [0,1]:
		for i in range(3 if p==first_player else 4): draw(p)
	sides[1-first_player].hand.append("the-coin")
	mulligan_pending=opening_choice
	if not mulligan_pending: start_turn(first_player)

func draw(p: int):
	var s = sides[p]
	if s.deck.is_empty():
		s.fatigue += 1
		damage_hero(p,s.fatigue)
		log.append(("You take " if p == 0 else enemy_name+" takes ")+str(s.fatigue)+" fatigue damage.")
	else:
		var id = s.deck.pop_back()
		if s.hand.size()<10: s.hand.append(id)
		else: log.append(cards[id].name+" burned: hand full.")
	check_outcome()

func start_turn(p: int):
	if outcome != -1: return
	active = p
	turn += 1
	var s = sides[p]
	s.max_mana = mini(s.max_mana+1,10)
	s.locked_mana=mini(s.max_mana,int(s.get("overload",0)))
	s.overload=0
	s.mana = s.max_mana-s.locked_mana
	s.power_used = false
	s.cards_played=0
	s.hero_attacks=0
	for m in s.board:
		m.ready = true
		m.summoning_sick=false
		m.attacks_used=0
	draw(p)

func damage_hero(p: int, amount: int):
	var absorbed = mini(sides[p].armor,amount)
	sides[p].armor -= absorbed
	sides[p].hp -= amount-absorbed
	record_hero_state(p)

func record_hero_state(p: int):
	record_event("hero_state",{"owner":p,"hp":sides[p].hp,"armor":sides[p].armor,"frozen":sides[p].get("frozen",false)})

func gain_armor(p: int,amount: int):
	sides[p].armor+=amount
	record_hero_state(p)

func check_outcome():
	if sides[0].hp <= 0 and sides[1].hp <= 0: outcome = 2
	elif sides[0].hp <= 0: outcome = 1
	elif sides[1].hp <= 0: outcome = 0

func targets(p: int, attack_action: bool) -> Array:
	var taunts = []
	var all = [-1]
	for m in sides[1-p].board:
		if m.get("stealth",false): continue
		all.append(m.uid)
		if m.get("taunt",false): taunts.append(m.uid)
	return taunts if attack_action and not taunts.is_empty() else all

func minion(p: int, uid: int) -> Dictionary:
	for m in sides[p].board:
		if m.uid == uid: return m
	return {}

func hurt(p: int, uid: int, amount: int) -> int:
	if amount<=0: return 0
	if uid == -1:
		damage_hero(p,amount)
		return amount
	else:
		var m = minion(p,uid)
		if not m.is_empty():
			if m.get("divine_shield",false):
				m.divine_shield=false
				log.append(cards[m.id].name+" loses Divine Shield.")
			else:
				m.hp -= amount
				return amount
	return 0

func buff_creature(owner: int,uid: int,attack_bonus: int,health_bonus: int):
	var target=minion(owner,uid)
	if target.is_empty() or target.hp<=0: return
	target.atk+=attack_bonus
	target.max_hp+=health_bonus
	target.hp+=health_bonus
	if attack_bonus!=0 or health_bonus!=0:
		record_event("buff",{"owner":owner,"uid":uid,"attack":attack_bonus,"health":health_bonus,"state":target.duplicate(true)})

func heal_character(owner: int,uid: int,amount: int) -> int:
	var target=sides[owner] if uid==-1 else minion(owner,uid)
	if target.is_empty() or (uid!=-1 and target.hp<=0): return 0
	var restored=mini(maxi(0,amount),maxi(0,target.max_hp-target.hp))
	target.hp+=restored
	if uid==-1 and restored>0: record_hero_state(owner)
	if restored>0: record_event("heal",{"owner":owner,"uid":uid,"amount":restored,"state":target.duplicate(true) if uid!=-1 else {}})
	return restored

func deal_damage(owner: int, target_owner: int, uid: int, amount: int, source: Dictionary) -> int:
	var dealt=hurt(target_owner,uid,amount)
	if source.get("type","")=="spell" and amount>0:
		record_event("spell_hit",{"owner":owner,"target_owner":target_owner,"uid":uid,"damage":dealt,"element":source.get("element","air"),"state":minion(target_owner,uid).duplicate(true) if uid!=-1 else {}})
	if dealt<=0: return 0
	if uid!=-1 and source.get("poisonous",false): minion(target_owner,uid).hp=0
	if source.get("lifesteal",false):
		var healing=heal_character(owner,-1,dealt)
		if healing>0: log.append("Lifesteal restores "+str(healing)+" health.")
	return dealt

func silence_minion(p: int,uid: int):
	var m=minion(p,uid)
	if m.is_empty() or m.hp<=0: return
	var base=cards[m.id]
	m.silenced=true
	m.atk=base.attack
	m.max_hp=base.health+int(m.get("aura_health",0))
	m.hp=mini(m.hp,m.max_hp)
	m.aura_attack=0
	for keyword in ["taunt","divine_shield","stealth","windfury","poisonous","lifesteal","rush","charge","frozen"]: m[keyword]=false
	m.spell_damage=0
	m.deathrattle=[]
	m.ready=not m.get("summoning_sick",false) and m.get("attacks_used",0)<1
	refresh_auras()
	record_event("minion_state",{"owner":p,"uid":uid,"state":m.duplicate(true)})
	log.append(base.name+" is silenced.")

func refresh_auras():
	for p in [0,1]:
		for m in sides[p].board:
			var old_attack=int(m.get("aura_attack",0))
			var old_health=int(m.get("aura_health",0))
			var bonus=0
			var health_bonus=0
			for source in sides[p].board:
				if source.uid!=m.uid and source.hp>0 and not source.get("silenced",false):
					if cards[source.id].get("auraAdjacent",false) and absi(sides[p].board.find(source)-sides[p].board.find(m))!=1: continue
					bonus+=int(cards[source.id].get("auraAttack",0))
					health_bonus+=int(cards[source.id].get("auraHealth",0))
			m.atk+=bonus-int(m.get("aura_attack",0))
			m.aura_attack=bonus
			var health_change=health_bonus-int(m.get("aura_health",0))
			m.max_hp+=health_change
			if m.hp>0:
				if health_change>0: m.hp+=health_change
				else: m.hp=mini(m.hp,m.max_hp)
			m.aura_health=health_bonus
			if old_attack!=bonus or old_health!=health_bonus:
				record_event("minion_state",{"owner":p,"uid":m.uid,"state":m.duplicate(true)})

func clean():
	if not pending_choice.is_empty(): return
	while true:
		if not resolving_death.is_empty():
			death_replacements[resolving_death.uid]=serial if serial>resolving_death.previous_serial else -1
			resolving_death={}
		check_outcome()
		if outcome!=-1:
			death_queue=[]
			weapon_deaths=[]
			return
		if death_queue.is_empty():
			death_replacements={}
			death_queue.append_array(weapon_deaths)
			weapon_deaths=[]
			for p in [0,1]:
				var left=[]
				var visible_layout=sides[p].board.map(func(member): return member.uid)
				for m in sides[p].board:
					if m.hp<=0:
						death_queue.append({"owner":p,"minion":m,"left":left.duplicate()})
						visible_layout.erase(m.uid)
						record_event("death",{"owner":p,"uid":m.uid,"id":m.id,"position":left.size(),"minion":m,"layout":visible_layout.duplicate()})
					left.append(m.uid)
				sides[p].board=sides[p].board.filter(func(m): return m.hp>0)
			refresh_auras()
			if death_queue.is_empty(): return
			death_queue.sort_custom(func(a,b): return a.minion.uid<b.minion.uid)
		var death=death_queue.pop_front()
		var effects=death.minion.get("deathrattle",[])
		if effects.is_empty(): continue
		log.append(cards[death.minion.id].name+" triggers Deathrattle.")
		var source=cards[death.minion.id].duplicate(true)
		source.type="weapon" if death.get("weapon",false) else "minion"
		source.poisonous=death.minion.get("poisonous",false)
		source.lifesteal=death.minion.get("lifesteal",false)
		var position=0
		var board=sides[death.owner].board
		for i in range(death.left.size()-1,-1,-1):
			var anchor=death_replacements.get(death.left[i],death.left[i])
			for j in range(board.size()):
				if board[j].uid==anchor: position=j+1; break
			if position>0: break
		resolving_death={"uid":death.minion.uid,"previous_serial":serial}
		resolve_effects(death.owner,effects,source,-1,-1 if death.get("weapon",false) else position)
		if not pending_choice.is_empty(): return

func can_play(p: int, index: int) -> bool:
	if not pending_choice.is_empty(): return false
	if mulligan_pending or outcome != -1 or p != active or index < 0 or index >= sides[p].hand.size(): return false
	var c = cards[sides[p].hand[index]]
	if c.has("secret"):
		var secrets=sides[p].get("secrets",[])
		if secrets.size()>=5 or secrets.has(c.id): return false
	if c.get("targeting","")=="optionalCreature" and card_targets(p,c).is_empty(): return false
	return c.cost <= sides[p].mana and (c.get("type", "minion") != "minion" or sides[p].board.size()<7)

func spell_damage(p: int) -> int:
	var total=0
	for m in sides[p].board:
		if m.hp>0: total+=int(m.get("spell_damage",0))
	return total

func card_targets(p: int,c: Dictionary) -> Array:
	if c.get("targetSide","enemy")=="friendly":
		return sides[p].board.filter(func(m): return m.hp>0).map(func(m): return m.uid)
	return targets(p,false)

func play_effects(p: int,c: Dictionary) -> Array:
	if sides[p].get("cards_played",0)>0 and c.has("combo"): return c.combo
	return c.get("onPlay",[])

func character_name(owner: int,uid: int) -> String:
	if uid==-1: return "your hero" if owner==0 else enemy_name+"'s hero"
	var creature=minion(owner,uid)
	return cards[creature.id].name if not creature.is_empty() else "a removed creature"

func play(p: int, index: int, target: int = -1, board_index: int = -1,choice: int=-1) -> bool:
	if not can_play(p,index): return false
	var s = sides[p]
	var c = cards[s.hand[index]]
	if c.has("choices"):
		if choice<0 or choice>=c.choices.size(): return false
		c=c.duplicate(true)
		c.onPlay=c.choices[choice].effects
	if c.get("targeting","") == "optionalCreature" and not card_targets(p,c).has(target): return false
	var target_note=" on "+character_name(p if c.get("targetSide","")=="friendly" else 1-p,target) if c.get("targeting","")=="optionalCreature" else ""
	s.mana -= c.cost
	s.hand.remove_at(index)
	var effects=play_effects(p,c)
	s.cards_played=int(s.get("cards_played",0))+1
	if c.get("type","")=="spell" and counter_spell(1-p):
		log.append(c.name+" is countered.")
		clean()
		return true
	s.overload=int(s.get("overload",0))+int(c.get("overload",0))
	if c.has("secret"):
		if not s.has("secrets"): s.secrets=[]
		var secret_before=s.secrets.duplicate()
		s.secrets.append(c.id)
		record_event("secret_state",{"owner":p,"before":secret_before,"secrets":s.secrets.duplicate()})
	if c.get("type","minion") == "minion":
		summon(p,c.id,board_index)
	if sides[p].get("cards_played",0)>1 and c.has("combo"): log.append(c.name+" activates Combo.")
	resolve_effects(p,effects,c,target)
	log.append(("You play " if p == 0 else enemy_name+" plays ")+("a Secret" if p==1 and c.has("secret") else c.name)+target_note+".")
	clean()
	return true

func resolve_effects(p: int,effects: Array,c: Dictionary,target: int=-1,summon_position: int=-1):
	var s=sides[p]
	for effect_index in range(effects.size()):
		var effect=effects[effect_index]
		if outcome!=-1: break
		match effect.effect:
			"discover":
				var pool=cards.keys().filter(func(id): return cards[id].get("set","")=="foundations" and cards[id].get("type","")=="minion" and cards[id].get("element","")==c.element)
				var offers=[]
				while offers.size()<3 and not pool.is_empty():
					var index=shuffle_rng.randi_range(0,pool.size()-1)
					offers.append(pool[index]); pool.remove_at(index)
				if not offers.is_empty():
					pending_choice={"owner":p,"offers":offers,"remaining":effects.slice(effect_index+1),"source":c,"target":target,"position":summon_position}
					return
			"freezeTarget":
				if target==-1:
					sides[1-p].frozen=true
					record_hero_state(1-p)
				else:
					var m=minion(1-p,target)
					if not m.is_empty() and m.hp>0:
						m.frozen=true
						record_event("minion_state",{"owner":1-p,"uid":m.uid,"state":m.duplicate(true)})
			"equipWeapon":
				if not s.get("weapon",{}).is_empty():
					log.append("Previous weapon replaced.")
					destroy_weapon(p)
				serial+=1
				s.weapon={"uid":serial,"id":c.id,"attack":int(effect.attack),"durability":int(effect.durability),"deathrattle":c.get("deathrattle",[]).duplicate(true)}
				for keyword in ["lifesteal","poisonous","windfury"]: s.weapon[keyword]=c.get(keyword,false)
				record_event("weapon_state",{"owner":p,"before":{},"weapon":s.weapon.duplicate(true)})
				log.append("Weapon equipped: %d/%d." % [effect.attack,effect.durability])
			"buffTarget":
				buff_creature(p if c.get("targetSide","")=="friendly" else 1-p,target,int(effect.attack),int(effect.health))
			"silenceEnemies":
				for m in sides[1-p].board: silence_minion(1-p,m.uid)
			"freezeEnemies":
				for m in sides[1-p].board:
					if m.hp>0:
						m.frozen=true
						record_event("minion_state",{"owner":1-p,"uid":m.uid,"state":m.duplicate(true)})
			"gainMana": s.mana=mini(10-int(s.get("locked_mana",0)),s.mana+int(effect.amount))
			"gainArmor": gain_armor(p,int(effect.amount))
			"healCaster": heal_character(p,-1,int(effect.amount))
			"damage": deal_damage(p,1-p,target,int(effect.amount)+(spell_damage(p) if c.get("type","minion")=="spell" else 0),c)
			"draw":
				for i in range(int(effect.amount)):
					if outcome==-1: draw(p)
			"ramp": s.max_mana=mini(10,s.max_mana+int(effect.amount))
			"damageEnemies", "damageBoard", "damageAll":
				var amount=int(effect.amount)+(spell_damage(p) if c.get("type","minion")=="spell" else 0)
				for side in ([1-p] if effect.effect=="damageEnemies" else [0,1]):
					for m in sides[side].board: deal_damage(p,side,m.uid,amount,c)
					if effect.effect=="damageAll": deal_damage(p,side,-1,amount,c)
				# All targets receive this damage batch before determining a winner.
				check_outcome()
			"buffAll", "buffElement":
				for m in s.board:
					if m.hp<=0: continue
					if effect.effect=="buffElement" and cards[m.id].element!=c.element: continue
					buff_creature(p,m.uid,int(effect.attack),int(effect.health))
			"healBoard":
				for m in s.board:
					heal_character(p,m.uid,int(effect.amount))
			"summon":
				for i in range(int(effect.amount)):
					if summon(p,effect.card,summon_position) and summon_position>=0: summon_position+=1
			_: push_error("Unsupported card effect: "+str(effect.effect))

func choose_discover(p: int,index: int) -> bool:
	if pending_choice.is_empty() or pending_choice.owner!=p or index<0 or index>=pending_choice.offers.size() or outcome!=-1: return false
	var choice=pending_choice
	var id=choice.offers[index]
	pending_choice={}
	if sides[p].hand.size()<10:
		sides[p].hand.append(id)
		log.append("You discover "+cards[id].name+"." if p==0 else enemy_name+" discovers a card.")
	else: log.append("Discovered card burned: hand full.")
	resolve_effects(p,choice.remaining,choice.source,choice.target,choice.position)
	clean()
	resume_attack()
	return true

func summon(p: int,id: String,board_index: int=-1) -> bool:
	var s=sides[p]
	if s.board.size()>=7: return false
	var c=cards[id]
	serial+=1
	s.board.insert(s.board.size() if board_index<0 else clampi(board_index,0,s.board.size()),{"uid":serial,"id":id,"atk":c.attack,"hp":c.health,"max_hp":c.health,"ready":c.get("rush",false) or c.get("charge",false),"poisonous":c.get("poisonous",false),"lifesteal":c.get("lifesteal",false),"deathrattle":c.get("deathrattle",[]).duplicate(true),"spell_damage":c.get("spellDamage",0),"stealth":c.get("stealth",false),"attacks_used":0,"windfury":c.get("windfury",false),"summoning_sick":true,"rush":c.get("rush",false),"charge":c.get("charge",false),"taunt":c.get("taunt",false),"divine_shield":c.get("divineShield",false)})
	record_event("summon",{"owner":p,"uid":serial,"id":id,"position":s.board.find(minion(p,serial)),"minion":minion(p,serial),"layout":s.board.map(func(member): return member.uid)})
	refresh_auras()
	return true

func attack_targets(p: int,uid: int) -> Array:
	if uid==-1:
		var s=sides[p]
		if s.get("weapon",{}).get("attack",0)<=0 or s.get("hero_attacks",0)>=(2 if s.get("weapon",{}).get("windfury",false) else 1) or s.get("frozen",false): return []
		return targets(p,true)
	var m=minion(p,uid)
	if m.is_empty() or not m.ready or m.atk<=0 or m.get("frozen",false): return []
	var allowed=targets(p,true)
	if m.get("summoning_sick",false) and not m.get("charge",false):
		if not m.get("rush",false): return []
		allowed.erase(-1)
	return allowed

func counter_spell(defender: int) -> bool:
	if defender==active: return false
	for id in sides[defender].get("secrets",[]).duplicate():
		if cards[id].secret.trigger!="spellPlayed": continue
		var secret_before=sides[defender].secrets.duplicate()
		sides[defender].secrets.erase(id)
		log.append("Secret revealed: "+cards[id].name+".")
		record_event("secret",{"owner":defender,"id":id,"before":secret_before,"remaining":sides[defender].secrets.duplicate()})
		return true
	return false

func attack_participants_live(p: int,uid: int,target: int) -> bool:
	if outcome!=-1 or sides[p].hp<=0 or sides[1-p].hp<=0: return false
	if uid!=-1:
		var attacker=minion(p,uid)
		if attacker.is_empty() or attacker.hp<=0: return false
	if target!=-1:
		var defender=minion(1-p,target)
		if defender.is_empty() or defender.hp<=0: return false
	return true

func trigger_attack_secrets(defender: int,target: int,attacker_uid: int=-1):
	if defender==active or target!=-1: return
	for id in sides[defender].get("secrets",[]).duplicate():
		if not attack_participants_live(1-defender,attacker_uid,target): return
		var secret=cards[id].secret
		if secret.trigger!="heroAttacked": continue
		var secret_before=sides[defender].secrets.duplicate()
		sides[defender].secrets.erase(id)
		log.append("Secret revealed: "+cards[id].name+".")
		record_event("secret",{"owner":defender,"id":id,"before":secret_before,"remaining":sides[defender].secrets.duplicate()})
		resolve_effects(defender,secret.effects,cards[id])
		clean()
		if outcome!=-1 or not pending_choice.is_empty(): return

func attack(p: int, uid: int, target: int) -> bool:
	if not pending_choice.is_empty(): return false
	if uid==-1: return hero_attack(p,target)
	var m = minion(p,uid)
	if mulligan_pending or outcome != -1 or active != p or m.is_empty() or not m.ready or m.atk <= 0 or not attack_targets(p,uid).has(target): return false
	m.stealth=false
	m.attacks_used=m.get("attacks_used",0)+1
	m.ready=m.attacks_used<(2 if m.get("windfury",false) else 1)
	pending_attack={"owner":p,"uid":uid,"target":target}
	resume_attack()
	return true

func destroy_weapon(p: int,previous: Dictionary={}):
	var weapon=sides[p].get("weapon",{})
	if weapon.is_empty(): return
	sides[p].weapon={}
	record_event("weapon_state",{"owner":p,"before":(previous if not previous.is_empty() else weapon).duplicate(true),"weapon":{}})
	if not weapon.get("deathrattle",[]).is_empty():
		weapon_deaths.append({"owner":p,"minion":weapon,"left":[],"weapon":true})

func hero_attack(p: int,target: int) -> bool:
	if not pending_choice.is_empty(): return false
	if mulligan_pending or outcome!=-1 or active!=p or not attack_targets(p,-1).has(target): return false
	var s=sides[p]
	s.hero_attacks=int(s.get("hero_attacks",0))+1
	pending_attack={"owner":p,"uid":-1,"target":target}
	resume_attack()
	return true

func resume_attack():
	if pending_attack.is_empty() or not pending_choice.is_empty(): return
	var action=pending_attack
	var p=int(action.owner)
	var uid=int(action.uid)
	var target=int(action.target)
	trigger_attack_secrets(1-p,target,uid)
	if not pending_choice.is_empty(): return
	# Clear before combat cleanup: a death-trigger choice must not replay combat.
	pending_attack={}
	if not attack_participants_live(p,uid,target):
		log.append("Attack interrupted.")
		return
	var source=sides[p].get("weapon",{}) if uid==-1 else minion(p,uid)
	if source.is_empty(): return
	var amount=int(source.get("attack",0) if uid==-1 else source.atk)
	var target_name=character_name(1-p,target)
	# Combat is presented before its Lifesteal triggers; amounts resolve synchronously.
	var combat_position=timeline.size()
	var retaliation=0
	if target!=-1:
		var defender=minion(1-p,target)
		retaliation=deal_damage(1-p,p,uid,int(defender.atk),defender)
	var dealt=deal_damage(p,1-p,target,amount,source)
	record_event("combat",{"owner":p,"uid":uid,"target":target,"card":source.get("id",""),"damage":dealt,"retaliation":retaliation,"source_state":minion(p,uid).duplicate(true) if uid!=-1 else {},"target_state":minion(1-p,target).duplicate(true) if target!=-1 else {}},combat_position)
	if uid==-1:
		var previous_weapon=source.duplicate(true)
		source.durability-=1
		log.append(("Your hero" if p==0 else enemy_name+"'s hero")+" attacks "+target_name+" for %d damage; takes %d in return." % [dealt,retaliation])
		if source.durability<=0:
			log.append("Weapon breaks.")
			destroy_weapon(p,previous_weapon)
		else: record_event("weapon_state",{"owner":p,"before":previous_weapon,"weapon":source.duplicate(true)})
	else:
		log.append(cards[source.id].name+" attacks "+target_name+" for %d damage; takes %d in return." % [dealt,retaliation])
	clean()

func power(target: int = -1,p: int=0) -> bool:
	if not pending_choice.is_empty(): return false
	var s = sides[p]
	if mulligan_pending or active != p or outcome != -1 or s.mana < 2 or s.power_used: return false
	if job.effect == "target" and not targets(p,false).has(target): return false
	s.mana -= 2
	s.power_used = true
	match job.effect:
		"armor": gain_armor(p,int(job.amount))
		"damage": damage_hero(1-p,job.amount)
		"target": hurt(1-p,target,job.amount)
	log.append(("You use " if p==0 else enemy_name+" uses ")+job.power+".")
	clean()
	return true

func creature_value(m: Dictionary) -> float:
	return float(m.atk)+float(m.hp)*0.5+(1.0 if m.get("taunt",false) else 0.0)

func damage_value(m: Dictionary,amount: int,source: Dictionary) -> float:
	if amount<=0: return 0.0
	if m.get("divine_shield",false): return 1.0
	return creature_value(m)+1.0 if amount>=m.hp or source.get("poisonous",false) else float(amount)*0.3

func healing_value(p: int,amount: int,source: Dictionary) -> float:
	return minf(amount,maxi(0,sides[p].max_hp-sides[p].hp))*0.7 if source.get("lifesteal",false) else 0.0

func damage_choice(p: int,amount: int,source: Dictionary={}) -> Dictionary:
	var enemy=sides[1-p]
	var result={"target":-1,"score":float(amount)*0.6+healing_value(p,amount,source)}
	if amount>=enemy.hp+enemy.armor: result.score=10000.0
	for uid in targets(p,false):
		if uid==-1: continue
		var m=minion(1-p,uid)
		var score=damage_value(m,amount,source)
		if not m.get("divine_shield",false): score+=healing_value(p,amount,source)
		if score>result.score: result={"target":uid,"score":score}
	return result

func placement_value(board: Array) -> float:
	var value=0.0
	for i in range(board.size()):
		var source=board[i]
		if source.get("silenced",false) or source.hp<=0: continue
		var c=cards[source.id]
		for j in range(board.size()):
			if i==j: continue
			if c.get("auraAdjacent",false) and absi(i-j)!=1: continue
			var recipient=board[j]
			var attack_weight=1.5 if recipient.get("ready",false) and not recipient.get("frozen",false) else 1.0
			value+=float(c.get("auraAttack",0))*attack_weight+float(c.get("auraHealth",0))*0.65
	return value

func best_placement(p: int,c: Dictionary) -> Dictionary:
	var board=sides[p].board
	var before=placement_value(board)
	var best={"position":board.size(),"value":-INF}
	for i in range(board.size()+1):
		var candidate=board.duplicate()
		candidate.insert(i,{"id":c.id,"hp":c.health,"ready":c.get("rush",false) or c.get("charge",false)})
		var value=placement_value(candidate)-before
		if value>best.value: best={"position":i,"value":value}
	return best

func best_option(p: int,c: Dictionary) -> int:
	var best=0
	var highest=-INF
	for i in range(c.choices.size()):
		var score=0.0
		for effect in c.choices[i].effects:
			match effect.effect:
				"ramp": score+=minf(effect.amount,10-sides[p].max_mana)*3.0
				"gainArmor": score+=effect.amount*(0.8 if sides[p].hp<=10 else 0.35)
				"healCaster": score+=minf(effect.amount,sides[p].max_hp-sides[p].hp)*0.7
				"draw": score+=minf(effect.amount,minf(sides[p].deck.size(),10-sides[p].hand.size()+1))*2.5
		if score>highest: highest=score; best=i
	return best

func ai_choice(p: int) -> Dictionary:
	if not pending_choice.is_empty():
		if pending_choice.owner!=p: return {"kind":"none"}
		var best_index=0
		var value=-INF
		for i in range(pending_choice.offers.size()):
			var card=cards[pending_choice.offers[i]]
			var score=float(card.attack)+float(card.health)*0.65-float(card.cost)*0.5
			if score>value: value=score; best_index=i
		return {"kind":"discover","index":best_index}
	if mulligan_pending or outcome != -1 or active != p: return {"kind":"none"}
	var s=sides[p]
	var best={"kind":"none","score":0.0}
	for i in range(s.hand.size()):
		if not can_play(p,i): continue
		var c=cards[s.hand[i]]
		var chosen=-1
		if c.has("choices"):
			chosen=best_option(p,c)
			c=c.duplicate(true)
			c.onPlay=c.choices[chosen].effects
		var score=0.0
		var target=-1
		var position=-1
		if c.has("secret"): score+=3.0
		if c.get("type","minion")=="minion": score=float(c.attack)+float(c.health)*0.65+(1.5 if c.get("taunt",false) else 0.0)
		if c.get("type","minion")=="minion":
			var placement=best_placement(p,c)
			position=placement.position
			score+=placement.value
		for effect in play_effects(p,c):
			match effect.effect:
				"discover": score+=3.5
				"freezeTarget":
					if target==-1:
						if not sides[1-p].get("frozen",false): score+=float(sides[1-p].get("weapon",{}).get("attack",0))*0.7
					else:
						var m=minion(1-p,target)
						if not m.is_empty() and not m.get("frozen",false): score+=float(m.atk)*0.7
				"equipWeapon":
					score+=float(effect.attack)*float(effect.durability)*0.8
					if not s.get("weapon",{}).is_empty(): score-=float(s.weapon.attack)*s.weapon.durability*0.5
				"buffTarget":
					var value=-1.0
					for uid in card_targets(p,c):
						var m=minion(p,uid)
						var candidate=float(effect.attack)*(1.5 if m.ready else 1.0)+float(effect.health)*0.65+float(m.hp)*0.05
						if candidate>value: value=candidate; target=uid
					score+=maxf(0,value)
				"silenceEnemies":
					for m in sides[1-p].board:
						if not m.get("silenced",false):
							score+=maxf(0,float(m.atk-cards[m.id].attack))+float(m.get("spell_damage",0))
							for key in ["taunt","divine_shield","windfury","poisonous","lifesteal"]:
								if m.get(key,false): score+=1.5
							if not m.get("deathrattle",[]).is_empty(): score+=2.0
				"freezeEnemies":
					for m in sides[1-p].board:
						if not m.get("frozen",false): score+=float(m.atk)*0.7
				"damage":
					var choice=damage_choice(p,int(effect.amount)+(spell_damage(p) if c.get("type","minion")=="spell" else 0),c)
					target=choice.target; score+=choice.score
				"gainArmor": score+=float(effect.amount)*0.35
				"healCaster": score+=minf(effect.amount,s.max_hp-s.hp)*0.7
				"draw":
					score+=minf(effect.amount,minf(s.deck.size(),10-s.hand.size()+1))*2.5
					if effect.amount>s.deck.size(): score-=(effect.amount-s.deck.size())*(s.fatigue+2)*2
				"ramp": score+=minf(effect.amount,10-s.max_mana)*3.0
				"gainMana":
					# Save the Coin unless it enables an otherwise unaffordable play now.
					for id in s.hand:
						var next=cards[id]
						if next.cost>s.mana and next.cost<=mini(10,s.mana+int(effect.amount)) and (next.get("type","minion")!="minion" or s.board.size()<7): score=maxf(score,5.0)
				"healBoard":
					for m in s.board: score+=minf(effect.amount,m.get("max_hp",cards[m.id].health)-m.hp)*0.7
				"buffAll", "buffElement":
					for m in s.board:
						if effect.effect=="buffElement" and cards[m.id].element!=c.element: continue
						score+=effect.attack+effect.health*0.65
				"summon":
					var summoned=cards[effect.card]
					var room=7-s.board.size()-(1 if c.get("type","minion")=="minion" else 0)
					score+=mini(effect.amount,room)*(summoned.attack+summoned.health*0.65)
				"damageEnemies", "damageBoard", "damageAll":
					var amount=int(effect.amount)+(spell_damage(p) if c.get("type","minion")=="spell" else 0)
					var total_damage=0
					for m in sides[1-p].board:
						score+=damage_value(m,amount,c)
						if not m.get("divine_shield",false): total_damage+=amount
					if effect.effect in ["damageBoard","damageAll"]:
						for m in s.board:
							score-=damage_value(m,amount,c)
							if not m.get("divine_shield",false): total_damage+=amount
					score+=healing_value(p,total_damage,c)
					if effect.effect=="damageAll":
						var own_lethal=amount>=s.hp+s.armor
						var enemy_lethal=amount>=sides[1-p].hp+sides[1-p].armor
						if own_lethal: score=-10000.0
						elif enemy_lethal: score=10000.0
						else: score+=float(amount)*0.2
		if score<10000.0: score-=float(c.get("overload",0))*0.75
		if score>best.score: best={"kind":"play","index":i,"target":target,"score":score,"choice":chosen,"position":position}
	if s.mana>=2 and not s.power_used and (p==0 or enemy_power):
		var choice={"target":-1,"score":float(job.amount)*0.35}
		if job.effect=="target": choice=damage_choice(p,int(job.amount))
		elif job.effect=="damage": choice.score=10000.0 if job.amount>=sides[1-p].hp+sides[1-p].armor else float(job.amount)*0.6
		if choice.score>best.score: best={"kind":"power","target":choice.target,"score":choice.score}
	for m in s.board:
		if not m.ready or m.atk<=0: continue
		for target in attack_targets(p,m.uid):
			var score=float(m.atk)*0.6
			if target==-1:
				score+=healing_value(p,int(m.atk),m)
				if m.atk>=sides[1-p].hp+sides[1-p].armor: score=10000.0
			else:
				var defender=minion(1-p,target)
				score=damage_value(defender,int(m.atk),m)
				if not defender.get("divine_shield",false): score+=healing_value(p,int(m.atk),m)
				if not m.get("divine_shield",false):
					if defender.atk>0 and (defender.atk>=m.hp or defender.get("poisonous",false)): score-=creature_value(m)
					score-=healing_value(1-p,int(defender.atk),defender)
				if defender.get("taunt",false): score=maxf(score,0.1)
			if score>best.score: best={"kind":"attack","uid":m.uid,"target":target,"score":score}
	for target in attack_targets(p,-1):
		var amount=int(s.weapon.attack)
		var score=float(amount)*0.6+healing_value(p,amount,s.weapon)
		if target==-1:
			if amount>=sides[1-p].hp+sides[1-p].armor: score=10000.0
		else:
			var defender=minion(1-p,target)
			score=damage_value(defender,amount,s.weapon)-float(defender.atk)*0.5
			var after_retaliation=s.hp-maxi(0,int(defender.atk)-int(s.armor))
			var restored=mini(amount,maxi(0,s.max_hp-after_retaliation)) if s.weapon.get("lifesteal",false) and not defender.get("divine_shield",false) else 0
			score+=restored*.7-healing_value(1-p,int(defender.atk),defender)
			if after_retaliation+restored<=0: score=-10000.0
		if score>best.score: best={"kind":"attack","uid":-1,"target":target,"score":score}
	return best

func ai_step(p: int) -> bool:
	var best=ai_choice(p)
	match best.kind:
		"discover": return choose_discover(p,best.index)
		"play": return play(p,best.index,best.target,best.get("position",-1),best.get("choice",-1))
		"power": return power(best.target,p)
		"attack": return attack(p,best.uid,best.target)
	return false

func end_turn(p: int) -> bool:
	if not pending_choice.is_empty(): return false
	if mulligan_pending or active != p or outcome != -1: return false
	var hero_limit=2 if sides[p].get("weapon",{}).get("windfury",false) else 1
	if sides[p].get("frozen",false) and sides[p].get("hero_attacks",0)<hero_limit:
		sides[p].frozen=false
		record_hero_state(p)
	for m in sides[p].board:
		var eligible=not m.get("summoning_sick",false) or m.get("charge",false) or m.get("rush",false)
		var attacks_left=int(m.get("attacks_used",0))<(2 if m.get("windfury",false) else 1)
		if m.get("frozen",false) and eligible and attacks_left:
			m.frozen=false
			record_event("minion_state",{"owner":p,"uid":m.uid,"state":m.duplicate(true)})
	start_turn(1-p)
	return true

func replace_opening(p: int,indices: Array) -> bool:
	if indices.size()>sides[p].deck.size(): return false
	var unique=[]
	for index in indices:
		if not index is int or index<0 or index>=sides[p].hand.size() or unique.has(index): return false
		if sides[p].hand[index]=="the-coin": return false
		unique.append(index)
	var returned=[]
	# All replacements are drawn before any rejected cards return to the deck.
	for index in unique:
		returned.append(sides[p].hand[index])
		sides[p].hand[index]=sides[p].deck.pop_back()
	sides[p].deck.append_array(returned)
	for i in range(sides[p].deck.size()-1,0,-1):
		var j=shuffle_rng.randi_range(0,i)
		var tmp=sides[p].deck[i]
		sides[p].deck[i]=sides[p].deck[j]
		sides[p].deck[j]=tmp
	return true

func mulligan(indices: Array) -> bool:
	if not mulligan_pending or not replace_opening(0,indices): return false
	var opponent_rejects=[]
	for i in range(sides[1].hand.size()):
		var id=sides[1].hand[i]
		if id!="the-coin" and cards[id].cost>3 and opponent_rejects.size()<sides[1].deck.size(): opponent_rejects.append(i)
	opponent_mulligan_count=opponent_rejects.size()
	replace_opening(1,opponent_rejects)
	mulligan_pending=false
	log.append("You play first." if first_player==0 else "Opponent plays first. You have The Coin.")
	log.append("Opponent replaced %d opening cards." % opponent_mulligan_count)
	start_turn(first_player)
	return true

