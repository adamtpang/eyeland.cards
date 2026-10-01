extends SceneTree
var checks=0
var failed=0
func check(ok: bool,label: String):
	checks+=1
	if not ok: failed+=1; push_error(label)
func _initialize():
	var m=preload("res://model.gd").new()
	var deck=preload("res://collection.gd").practice_deck(m.cards,"earth")
	for hero in [false,true]:
		var b=preload("res://battle.gd").new(m.cards,deck,deck,30,30,m.world.classes[0],1)
		var trap=m.cards["earth-pebble-ward"].duplicate(true)
		trap.id="test-choice"; trap.name="Choice Trap"
		trap.secret.effects=[{"effect":"discover"},{"effect":"gainArmor","amount":2}]
		b.cards[trap.id]=trap
		b.sides[1].secrets=[trap.id,"earth-pebble-ward"]
		var uid=-1
		if hero: b.sides[0].weapon={"attack":2,"durability":2}
		else:
			b.summon(0,"home-breeze-finch")
			var attacker=b.sides[0].board[0]
			attacker.ready=true; attacker.summoning_sick=false; uid=attacker.uid
		check(b.attack(0,uid,-1) and not b.pending_choice.is_empty(),"Attack pauses for defender choice")
		check(b.sides[1].armor==0 and b.sides[1].hp==30 and b.sides[1].secrets==["earth-pebble-ward"],"No later Secret or damage before choice")
		check(not b.end_turn(0) and not b.attack(0,uid,-1),"Other actions blocked during choice")
		check(b.choose_discover(1,0) and b.pending_attack.is_empty(),"Choice resumes pending attack")
		check(b.sides[1].armor==8 and b.sides[1].secrets.is_empty(),"Remaining effect then later Secret then combat")
		b.resume_attack()
		check(b.sides[1].armor==8 and (not hero or b.sides[0].weapon.durability==1),"Combat and durability consumed once")
	print("SECRET CHOICE: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
