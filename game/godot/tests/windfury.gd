extends SceneTree
func _initialize():
	var model=preload("res://model.gd").new()
	var deck=preload("res://collection.gd").practice_deck(model.cards,"air")
	var b=preload("res://battle.gd").new(model.cards,deck,deck,30,30,model.world.classes[0],1)
	b.summon(0,"air-zephyr-dancer")
	var m=b.sides[0].board[0]
	assert(not b.attack(0,m.uid,-1),"Windfury does not bypass summoning sickness")
	b.start_turn(0)
	assert(b.attack(0,m.uid,-1) and m.ready)
	assert(b.attack(0,m.uid,-1) and not m.ready)
	assert(not b.attack(0,m.uid,-1) and b.sides[1].hp==24)
	b.start_turn(0)
	assert(m.attacks_used==0 and b.attack(0,m.uid,-1) and b.attack(0,m.uid,-1))
	print("WINDFURY: 5 / 5 passed")
	quit()
