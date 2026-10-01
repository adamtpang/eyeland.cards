extends SceneTree
var checks=0
var failures=0
func check(ok: bool,label: String):
	checks+=1
	if not ok: failures+=1; push_error(label)
func _initialize():
	var m=preload("res://model.gd").new()
	var deck=preload("res://collection.gd").practice_deck(m.cards,"fire")
	var b=preload("res://battle.gd").new(m.cards,deck,deck,30,30,m.world.classes[0],1)
	b.sides[0].mana=10; b.sides[0].hand=["fire-flame-lance","fire-flame-lance"]
	check(b.play(0,0) and b.sides[1].hp==27,"First card uses base damage")
	check(b.play(0,0) and b.sides[1].hp==22,"Second card replaces base effect with Combo")
	b.end_turn(0); b.end_turn(1)
	b.sides[0].mana=0; b.sides[0].hand=["fire-flame-lance","the-coin"]
	check(not b.play(0,0) and b.sides[0].cards_played==0,"Turn reset and rejected play do not enable Combo")
	b.sides[0].mana=2
	check(b.power() and b.sides[0].cards_played==0,"Hero power does not count as a card")
	b.sides[0].mana=2
	check(b.play(0,1) and b.sides[0].cards_played==1,"Coin counts as a card")
	check(b.play(0,0) and b.sides[1].hp==17,"Coin activates Combo")
	b.end_turn(0)
	check(b.sides[1].cards_played==0,"Opponent has independent count")
	b.sides[1].mana=10; b.sides[1].hand=["fire-flame-lance"]
	check(b.play(1,0) and b.sides[0].hp==29,"Opponent first card uses base damage through armor")
	print("COMBO: %d / %d passed" % [checks-failures,checks])
	quit(1 if failures else 0)
