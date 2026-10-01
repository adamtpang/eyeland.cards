extends SceneTree
var checks=0
var failed=0
func check(ok: bool,label: String):
	checks+=1
	if not ok: failed+=1; push_error(label)
func _initialize():
	var m=preload("res://model.gd").new()
	var deck=preload("res://collection.gd").practice_deck(m.cards,"earth")
	for shield in [false,true]:
		var b=preload("res://battle.gd").new(m.cards,deck,deck,30,30,m.world.classes[0],1)
		# Synthetic Secret exercises interruption using an existing supported effect.
		var trap=m.cards["earth-pebble-ward"].duplicate(true)
		trap.id="test-trap"; trap.name="Test Trap"
		trap.secret.effects=[{"effect":"damageEnemies","amount":10}]
		b.cards[trap.id]=trap
		b.sides[1].secrets=[trap.id,"earth-pebble-ward"]
		b.summon(0,"home-breeze-finch")
		var attacker=b.sides[0].board[0]
		attacker.ready=true; attacker.summoning_sick=false; attacker.divine_shield=shield
		check(b.attack(0,attacker.uid,-1),"Declared attack accepted")
		if shield:
			check(b.sides[0].board.size()==1 and not attacker.divine_shield,"Shield absorbs Secret damage")
			check(b.sides[1].secrets.is_empty() and b.sides[1].armor==6,"Survivor continues through second Secret and combat")
		else:
			check(b.sides[0].board.is_empty() and b.sides[1].hp==30,"Removed attacker deals no ghost damage")
			check(b.sides[1].secrets==["earth-pebble-ward"] and b.sides[1].armor==0,"Canceled attack leaves later Secret unrevealed")
		check(b.log.find("Secret revealed: Test Trap.")>=0,"First Secret revealed")
	print("SECRET INTERRUPTION: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
