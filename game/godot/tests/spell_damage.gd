extends SceneTree
func _initialize():
	var model=preload("res://model.gd").new()
	var deck=preload("res://collection.gd").practice_deck(model.cards,"air")
	var b=preload("res://battle.gd").new(model.cards,deck,deck,30,30,model.world.classes[2],1)
	b.summon(0,"air-wind-archivist"); b.summon(0,"air-wind-archivist")
	assert(b.spell_damage(0)==2)
	b.sides[0].hand=["home-spark"]; b.sides[0].mana=10
	assert(b.play(0,0) and b.sides[1].hp==26)
	b.sides[0].mana=10
	assert(b.power() and b.sides[1].hp==25)
	b.sides[0].hand=["fire-flare-fox"]; b.sides[0].mana=10
	assert(b.play(0,0) and b.sides[1].hp==24)
	b.summon(1,"home-cloudling")
	b.sides[0].hand=["fire-brushfire"]; b.sides[0].mana=10
	assert(b.play(0,0) and b.sides[1].board.is_empty())
	b.hurt(0,b.sides[0].board[0].uid,99); b.clean()
	assert(b.spell_damage(0)==1)
	print("SPELL DAMAGE: 6 / 6 passed")
	quit()
