extends SceneTree
var checks=0
var failed=0
func check(ok: bool,label: String):
	checks+=1
	if not ok: failed+=1; push_error(label)
func _initialize():
	var m=preload("res://model.gd").new()
	var deck=preload("res://collection.gd").practice_deck(m.cards,"air")
	var b=preload("res://battle.gd").new(m.cards,deck,deck,30,30,m.world.classes[0],1)
	b.sides[1].secrets=["air-fresh-breeze"]
	b.sides[0].mana=10; b.sides[0].hand=["air-gust-bolt","fire-flame-lance"]
	check(b.play(0,0) and b.sides[1].hp==30 and b.sides[0].mana==9,"Counter consumes card and mana without damage")
	check(b.sides[0].get("overload",0)==0 and b.sides[1].secrets.is_empty(),"Counter prevents Overload and consumes Secret")
	check(b.play(0,0) and b.sides[1].hp==25,"Countered card still enables Combo")
	b.sides[1].secrets=["air-fresh-breeze"]; b.sides[0].hand=["earth-earthen-spear"]
	check(b.play(0,0) and b.sides[1].secrets.size()==1 and b.sides[0].weapon.attack==3,"Weapon is not a spell and bypasses counter")
	b.sides[0].hand=["earth-pebble-ward"]
	check(b.play(0,0) and b.sides[0].get("secrets",[]).is_empty(),"Countered Secret never becomes active")
	b.sides[0].secrets=["air-fresh-breeze"]; b.sides[0].hand=["the-coin"]
	check(b.play(0,0) and b.sides[0].secrets.size()==1,"Own spell cannot trigger own counter")
	print("COUNTERSPELL: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
