extends SceneTree
var passed=0
var failed=0
func check(ok: bool,label: String):
	if ok: passed+=1
	else: failed+=1; push_error(label)
func _initialize():
	var m=preload("res://model.gd").new()
	var deck=preload("res://collection.gd").practice_deck(m.cards,"fire")
	var b=preload("res://battle.gd").new(m.cards,deck,deck,30,30,m.world.classes[0],1)
	b.summon(0,"home-breeze-finch"); b.summon(1,"home-breeze-finch")
	var finch=b.sides[0].board[0]
	b.summon(0,"fire-cinder-captain")
	var captain=b.sides[0].board[1]
	check(finch.atk==3 and captain.atk==4 and b.sides[1].board[0].atk==2,"Aura buffs only other friendly minions")
	b.summon(0,"home-breeze-finch")
	check(b.sides[0].board[2].atk==3,"New summon receives existing aura")
	b.summon(0,"fire-cinder-captain")
	check(finch.atk==4 and captain.atk==5,"Multiple sources stack and buff each other")
	b.refresh_auras(); b.refresh_auras()
	check(finch.atk==4,"Repeated refresh does not accumulate bonuses")
	b.resolve_effects(0,[{"effect":"buffAll","attack":2,"health":0}],{})
	captain.hp=0; b.clean()
	check(finch.atk==5,"Source death removes only aura, retaining permanent buff")
	b.sides[0].board[-1].hp=0; b.clean()
	check(finch.atk==4,"Last source removes remaining aura")
	b.sides[0].board=[]
	b.summon(0,"home-breeze-finch"); b.summon(0,"air-flock-captain"); b.summon(0,"home-breeze-finch"); b.summon(0,"home-breeze-finch")
	var board=b.sides[0].board
	check(board[0].atk==4 and board[1].atk==3 and board[2].atk==4 and board[3].atk==2,"Positional aura buffs only adjacent creatures")
	var old_neighbor=board[2]
	b.summon(0,"home-breeze-finch",2)
	check(old_neighbor.atk==2 and b.sides[0].board[2].atk==4,"Insertion moves aura to new neighbor")
	b.sides[0].board[2].hp=0; b.clean()
	check(old_neighbor.atk==4,"Neighbor death reconnects adjacency")
	b.silence_minion(0,b.sides[0].board[1].uid)
	check(old_neighbor.atk==2 and b.sides[0].board[0].atk==2,"Silence removes positional aura")
	b.sides[0].board=[]
	b.summon(0,"home-breeze-finch"); b.summon(0,"water-reef-conductor")
	finch=b.sides[0].board[0]
	check(finch.hp==3 and finch.max_hp==3,"Health aura raises current and maximum health")
	finch.hp=1; b.refresh_auras(); b.refresh_auras()
	check(finch.hp==1,"Repeated aura refresh cannot heal damage")
	b.silence_minion(0,finch.uid)
	check(finch.hp==1 and finch.max_hp==3,"Silence retains external aura without healing")
	b.sides[0].board[1].hp=0; b.clean()
	check(finch.hp==1 and finch.max_hp==2,"Removing health aura clamps maximum without harming wounded survivor")
	b.resolve_effects(0,[{"effect":"buffAll","attack":0,"health":2}],{})
	b.summon(0,"water-reef-conductor"); b.silence_minion(0,b.sides[0].board[1].uid)
	check(finch.max_hp==4 and finch.hp==4,"Aura removal preserves permanent health enchantment")
	print("AURAS: ",passed," passed; ",failed," failed")
	quit(1 if failed else 0)
