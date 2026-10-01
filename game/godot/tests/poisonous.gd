extends SceneTree
func _initialize():
	var m=preload("res://model.gd").new()
	var deck=preload("res://collection.gd").practice_deck(m.cards,"water")
	var b=preload("res://battle.gd").new(m.cards,deck,deck,30,30,m.world.classes[0],1)
	b.summon(0,"water-dewdrop-newt"); b.summon(1,"home-cloudling")
	var poison=b.sides[0].board[0]
	b.start_turn(0)
	assert(b.attack(0,poison.uid,b.sides[1].board[0].uid) and b.sides[1].board.is_empty())
	b.summon(0,"water-dewdrop-newt"); b.summon(1,"water-shellback-tortoise")
	poison=b.sides[0].board[0]; b.start_turn(0)
	assert(b.attack(0,poison.uid,b.sides[1].board[0].uid) and b.sides[1].board[0].hp==4)
	b.summon(0,"home-mossling"); b.summon(1,"water-dewdrop-newt")
	b.sides[1].board[0].taunt=false; b.start_turn(0)
	var attacker=b.sides[0].board[0]
	assert(b.attack(0,attacker.uid,b.sides[1].board[1].uid) and b.sides[0].board.is_empty())
	b.summon(0,"water-dewdrop-newt"); b.sides[1].board=[]; b.start_turn(0)
	assert(b.attack(0,b.sides[0].board[0].uid,-1) and b.sides[1].hp==29 and b.outcome==-1)
	print("POISONOUS: 4 / 4 passed")
	quit()
