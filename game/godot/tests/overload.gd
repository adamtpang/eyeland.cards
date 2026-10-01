extends SceneTree
var checks=0
var failures=0
func check(ok: bool,label: String):
	checks+=1
	if not ok: failures+=1; push_error(label)
func _initialize():
	var m=preload("res://model.gd").new()
	var deck=preload("res://collection.gd").practice_deck(m.cards,"air")
	var b=preload("res://battle.gd").new(m.cards,deck,deck,30,30,m.world.classes[0],1)
	b.sides[0].hand=["air-gust-bolt","air-gust-bolt"]
	b.sides[0].mana=2; b.sides[0].max_mana=2
	check(b.play(0,0) and b.sides[0].mana==1 and b.sides[0].overload==1,"Overload queues without extra current cost")
	check(b.play(0,0) and b.sides[0].overload==2,"Multiple overload cards stack")
	b.end_turn(0)
	check(b.sides[1].locked_mana==0,"Opponent mana unaffected")
	b.end_turn(1)
	check(b.sides[0].max_mana==3 and b.sides[0].mana==1 and b.sides[0].locked_mana==2 and b.sides[0].overload==0,"Next turn locks and clears pending debt")
	b.sides[0].hand=["the-coin"]
	check(b.play(0,0) and b.sides[0].mana==2 and b.sides[0].locked_mana==2,"Coin grants temporary mana without unlocking crystals")
	b.end_turn(0); b.end_turn(1)
	check(b.sides[0].mana==4 and b.sides[0].locked_mana==0,"Locks expire after one turn")
	b.sides[0].overload=20; b.start_turn(0)
	check(b.sides[0].mana==0 and b.sides[0].locked_mana==5,"Excess debt cannot produce negative mana")
	b.start_turn(0)
	check(b.sides[0].mana==6,"Excess debt does not spill into later turns")
	b.sides[0].hand=["air-gust-bolt"]; b.sides[0].mana=0
	check(not b.play(0,0) and b.sides[0].overload==0,"Rejected card does not incur debt")
	print("OVERLOAD: %d / %d passed" % [checks-failures,checks])
	quit(1 if failures else 0)
