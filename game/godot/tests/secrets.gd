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
	b.sides[0].mana=10; b.sides[0].hand=["earth-pebble-ward","earth-pebble-ward"]
	check(b.play(0,0) and b.sides[0].armor==0,"Secret waits for trigger")
	check(not b.play(0,0) and b.sides[0].hand.size()==1,"Duplicate secret is rejected")
	b.trigger_attack_secrets(0,-1)
	check(b.sides[0].secrets.size()==1,"Secret does not trigger on owner turn")
	b.end_turn(0); b.sides[1].weapon={"attack":3,"durability":2}
	check(b.attack(1,-1,-1) and b.sides[0].hp==30 and b.sides[0].armor==5,"Secret resolves before attack damage")
	check(b.sides[0].secrets.is_empty(),"Secret consumed once")
	b.sides[1].hand=["earth-pebble-ward"]; b.sides[1].mana=2
	check(b.play(1,0) and b.log[-1].contains("a Secret") and not b.log[-1].contains("Pebble Ward"),"Opponent play log hides identity")
	b.end_turn(1); b.sides[0].mana=10
	check(b.play(0,0),"Consumed secret may be replayed")
	for i in range(4): b.sides[0].secrets.append("test-%d" % i)
	b.cards["test-secret"]=b.cards["earth-pebble-ward"].duplicate(true); b.cards["test-secret"].id="test-secret"
	b.sides[0].hand=["test-secret"]
	check(not b.can_play(0,0),"Five-secret limit")
	print("SECRETS: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
