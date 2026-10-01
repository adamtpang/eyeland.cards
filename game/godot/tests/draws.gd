extends SceneTree
var passed=0
var failures=0
func check(ok: bool,label: String):
	if ok: passed+=1
	else: failures+=1; push_error(label)
func _initialize():
	var model=preload("res://model.gd").new()
	var deck=preload("res://collection.gd").practice_deck(model.cards,"fire")
	for caster in [0,1]:
		var b=preload("res://battle.gd").new(model.cards,deck,deck,30,30,model.world.classes[0],4)
		b.active=caster; b.sides[caster].mana=10; b.sides[caster].hand=["fire-worldfire"]
		b.sides[0].hp=7; b.sides[1].hp=7
		check(b.play(caster,0) and b.outcome==2,"Simultaneous lethal is a draw for either caster")
		check(not b.end_turn(caster) and not b.power(-1,caster),"Draw terminates actions")
	var b=preload("res://battle.gd").new(model.cards,deck,deck,30,30,model.world.classes[0],4)
	b.sides[0].mana=10; b.sides[0].hand=["fire-worldfire"]
	b.sides[0].hp=7; b.sides[0].armor=1; b.sides[1].hp=7
	check(b.play(0,0) and b.outcome==0 and b.sides[0].hp==1,"Armor prevents own lethal")
	b=preload("res://battle.gd").new(model.cards,deck,deck,30,30,model.world.classes[0],4)
	b.sides[0].mana=10; b.sides[0].hand=["fire-worldfire"]
	b.sides[0].hp=7; b.sides[1].hp=8
	check(b.ai_choice(0).kind!="play","AI avoids a self-lethal board clear")
	check(b.play(0,0) and b.outcome==1,"Only caster lethal is a loss")
	print("DRAWS: ",passed," passed; ",failures," failed")
	quit(1 if failures else 0)
