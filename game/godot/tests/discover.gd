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
	b.sides[0].hand=["air-windfall"]; b.sides[0].mana=2
	check(b.play(0,0) and b.pending_choice.offers.size()==3,"Discover offers three cards after payment")
	var offers=b.pending_choice.offers.duplicate()
	check(offers[0]!=offers[1] and offers[1]!=offers[2] and offers[0]!=offers[2] and offers.all(func(id): return m.cards[id].element=="air" and m.cards[id].type=="minion"),"Offers are distinct and from eligible pool")
	check(not b.end_turn(0) and not b.power() and not b.choose_discover(1,0) and not b.choose_discover(0,3),"Pending choice blocks actions and invalid selections")
	check(b.choose_discover(0,1) and b.sides[0].hand==[offers[1]] and b.pending_choice.is_empty(),"Only chosen card enters hand")
	b.resolve_effects(0,[{"effect":"discover"},{"effect":"gainArmor","amount":4}],m.cards["air-windfall"])
	check(b.sides[0].armor==0,"Following effects pause")
	b.sides[0].hand.resize(10); b.sides[0].hand.fill("home-breeze-finch")
	check(b.choose_discover(0,0) and b.sides[0].hand.size()==10 and b.sides[0].armor==4,"Full hand burns choice then resumes effects")
	b.sides[0].hand=["air-windfall"]; b.sides[0].mana=2; b.sides[1].secrets=["air-fresh-breeze"]
	check(b.play(0,0) and b.pending_choice.is_empty(),"Countered Discover produces no offers")
	print("DISCOVER: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
