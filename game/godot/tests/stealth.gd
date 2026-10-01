extends SceneTree
func _initialize():
	var model=preload("res://model.gd").new()
	var deck=preload("res://collection.gd").practice_deck(model.cards,"fire")
	var b=preload("res://battle.gd").new(model.cards,deck,deck,30,30,model.world.classes[2],1)
	b.summon(1,"fire-cinder-moth")
	var hidden=b.sides[1].board[0]
	hidden.taunt=true
	assert(not b.targets(0,false).has(hidden.uid) and b.targets(0,true).has(-1))
	b.sides[0].mana=10; b.sides[0].hand=["home-spark"]
	assert(not b.play(0,0,hidden.uid) and b.sides[0].mana==10)
	assert(not b.power(hidden.uid))
	b.start_turn(1)
	assert(b.attack(1,hidden.uid,-1) and not hidden.stealth)
	assert(b.targets(0,false).has(hidden.uid))
	b.summon(1,"fire-cinder-moth")
	b.start_turn(0); b.sides[0].mana=10; b.sides[0].hand=["fire-brushfire"]
	assert(b.play(0,0) and b.sides[1].board.is_empty())
	print("STEALTH: 6 / 6 passed")
	quit()
