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
	b.sides[0].mana=10; b.sides[0].hand=["earth-earthen-spear"]
	check(b.play(0,0) and b.sides[0].weapon.attack==3,"Weapon card equips real weapon state")
	b.summon(1,"home-shore-guard"); var guard=b.sides[1].board[0]
	check(not b.attack(0,-1,-1) and b.sides[0].weapon.durability==2,"Taunt blocks hero face attack without spending durability")
	var retaliation=guard.atk
	check(b.attack(0,-1,guard.uid) and b.sides[0].hp==30-retaliation and b.sides[0].weapon.durability==1,"Hero attack takes retaliation and spends durability")
	check(not b.attack(0,-1,-1),"One hero attack per turn")
	b.end_turn(0); b.end_turn(1); b.sides[1].board=[]
	check(b.attack(0,-1,-1) and b.sides[1].hp==27 and b.sides[0].weapon.is_empty(),"Last durability breaks weapon after dealing damage")
	check(b.attack_targets(0,-1).is_empty(),"Unarmed hero has no attack")
	for i in range(7): b.summon(0,"home-breeze-finch")
	b.sides[0].hand=["earth-earthen-spear"]; b.sides[0].mana=3
	check(b.play(0,0) and b.sides[0].board.size()==7,"Weapon equips with full minion board")
	check(preload("res://collection.gd").query(m.cards,{}, {"type":"weapon"})==["earth-earthen-spear"],"Weapon collection filter")
	var old_weapon=b.sides[0].weapon
	old_weapon.durability=1
	b.sides[0].hand=["earth-earthen-spear"]; b.sides[0].mana=3
	check(b.play(0,0) and b.sides[0].weapon.durability==2 and old_weapon.durability==1,"Replacement creates fresh weapon without mutating discarded weapon")
	check(b.sides[0].get("hero_attacks",0)==1 and not b.attack(0,-1,-1),"Replacing spent weapon grants no extra attack")
	check(b.log.has("Previous weapon replaced."),"History explains weapon replacement")
	b.end_turn(0); b.end_turn(1)
	b.sides[0].frozen=true; b.sides[0].hand=["earth-earthen-spear"]; b.sides[0].mana=3
	check(b.play(0,0) and not b.attack(0,-1,-1) and b.sides[0].weapon.durability==2,"Replacement does not remove Freeze or spend durability")
	b.end_turn(0); b.end_turn(1)
	check(b.attack(0,-1,-1) and b.sides[0].weapon.durability==1,"Replacement becomes usable after Freeze expires")
	print("WEAPONS: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
