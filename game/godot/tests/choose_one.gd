extends SceneTree
var checks=0
var failed=0
func check(ok: bool,label: String):
	checks+=1
	if not ok: failed+=1; push_error(label)
func _initialize():
	var m=preload("res://model.gd").new()
	var deck=preload("res://collection.gd").practice_deck(m.cards,"earth")
	var b=preload("res://battle.gd").new(m.cards,deck,deck,30,30,m.world.classes[0],1)
	b.sides[0].mana=10; b.sides[0].hand=["earth-deep-roots","earth-deep-roots"]
	check(not b.play(0,0) and not b.play(0,0,-1,-1,2) and b.sides[0].mana==10,"Missing or invalid choice preserves resources")
	check(b.play(0,0,-1,-1,0) and b.sides[0].max_mana==2 and b.sides[0].armor==0,"Ramp option resolves only ramp")
	check(b.play(0,0,-1,-1,1) and b.sides[0].armor==6 and b.sides[0].max_mana==2,"Armor option resolves only armor")
	b.sides[0].hand=["earth-deep-roots"]; b.sides[1].secrets=["air-fresh-breeze"]
	check(b.play(0,0,-1,-1,1) and b.sides[0].armor==6,"Counter prevents selected effect")
	print("CHOOSE ONE: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
