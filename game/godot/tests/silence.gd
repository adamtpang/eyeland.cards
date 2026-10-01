extends SceneTree
var passed=0
var failed=0
func check(ok: bool,label: String):
	if ok: passed+=1
	else: failed+=1; push_error(label)
func _initialize():
	var m=preload("res://model.gd").new()
	var deck=preload("res://collection.gd").practice_deck(m.cards,"water")
	var b=preload("res://battle.gd").new(m.cards,deck,deck,30,30,m.world.classes[0],1)
	b.summon(1,"water-shellback-tortoise")
	var turtle=b.sides[1].board[0]
	turtle.atk+=5; turtle.max_hp+=5; turtle.hp+=5; turtle.frozen=true
	b.sides[0].hand=["water-sea-glass"]; b.sides[0].mana=3
	check(b.play(0,0) and turtle.atk==2 and turtle.hp==4 and turtle.max_hp==4,"Silence restores printed stats")
	check(not turtle.taunt and not turtle.divine_shield and not turtle.frozen,"Silence removes shield, Taunt and Freeze")
	b.summon(1,"fire-coalback-pup"); var pup=b.sides[1].board[-1]
	b.silence_minion(1,pup.uid); pup.hp=0; b.clean()
	check(b.sides[1].board.size()==1,"Silenced Deathrattle never triggers")
	b.summon(1,"fire-cinder-captain"); var captain=b.sides[1].board[-1]
	b.silence_minion(1,turtle.uid)
	check(turtle.atk==3,"External aura reapplies to silenced recipient")
	b.silence_minion(1,captain.uid)
	check(turtle.atk==2,"Silencing aura source removes its bonus")
	turtle.hp=1; b.silence_minion(1,turtle.uid)
	check(turtle.hp==1,"Silence does not heal existing damage")
	b.summon(0,"air-skyfin-ray"); var charge=b.sides[0].board[0]
	b.silence_minion(0,charge.uid)
	check(b.attack_targets(0,charge.uid).is_empty(),"Silencing Charge restores summoning restriction")
	b.summon(0,"air-wind-archivist"); b.silence_minion(0,b.sides[0].board[-1].uid)
	check(b.spell_damage(0)==0,"Silence removes Spell Damage")
	print("SILENCE: ",passed," passed; ",failed," failed")
	quit(1 if failed else 0)
