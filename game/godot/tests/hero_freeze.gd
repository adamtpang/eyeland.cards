extends SceneTree
var checks=0
var failed=0
func check(ok: bool,label: String):
	checks+=1
	if not ok: failed+=1; push_error(label)
func _initialize():
	var m=preload("res://model.gd").new()
	var deck=preload("res://collection.gd").practice_deck(m.cards,"water")
	var b=preload("res://battle.gd").new(m.cards,deck,deck,30,30,m.world.classes[0],1)
	b.sides[1].weapon={"attack":3,"durability":2}
	b.sides[0].hand=["water-undertow"]; b.sides[0].mana=2
	check(b.play(0,0,-1) and b.sides[1].frozen and b.sides[1].hp==27,"Undertow freezes enemy hero after damage")
	b.end_turn(0)
	check(not b.attack(1,-1,-1) and b.sides[1].weapon.durability==2,"Frozen hero cannot spend attack or durability")
	b.end_turn(1)
	check(not b.sides[1].frozen,"Hero thaws after missed attack")
	b.end_turn(0)
	check(b.attack(1,-1,-1),"Hero attacks following turn")
	b.sides[1].frozen=true; b.end_turn(1)
	check(b.sides[1].frozen,"Freeze after attack persists")
	b.end_turn(0); b.end_turn(1)
	check(not b.sides[1].frozen,"Post-attack freeze expires after next missed turn")
	b.sides[0].frozen=true; b.end_turn(0)
	check(not b.sides[0].frozen,"Unarmed hero also thaws")
	print("HERO FREEZE: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
