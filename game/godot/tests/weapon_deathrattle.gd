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
	b.cards["earth-earthen-spear"].deathrattle=[{"effect":"gainArmor","amount":2}]
	b.sides[0].mana=10; b.sides[0].hand=["earth-earthen-spear","earth-earthen-spear"]
	b.play(0,0); b.play(0,0)
	check(b.sides[0].armor==2 and b.sides[0].weapon.durability==2,"Replacement triggers old Deathrattle while new weapon stays equipped")
	b.clean(); check(b.sides[0].armor==2,"Replacement Deathrattle only fires once")
	b.sides[0].weapon.durability=1
	b.summon(1,"fire-coalback-pup")
	var pup=b.sides[1].board[0]
	check(b.attack(0,-1,pup.uid) and b.sides[0].weapon.is_empty() and b.sides[0].armor==2,"Retaliation spends old armor before weapon Deathrattle restores two")
	var weapon_log=b.log.rfind("Earthen Spear triggers Deathrattle.")
	var pup_log=b.log.rfind("Coalback Pup triggers Deathrattle.")
	check(weapon_log>=0 and pup_log>weapon_log,"Simultaneous weapon/minion deaths use shared entry order")
	b.sides[0].hand=["earth-earthen-spear"]; b.sides[0].mana=3
	b.cards["earth-earthen-spear"].deathrattle=[{"effect":"discover"},{"effect":"gainArmor","amount":3}]
	b.play(0,0); b.destroy_weapon(0); b.clean()
	check(not b.pending_choice.is_empty() and b.sides[0].weapon.is_empty(),"Weapon death can pause for Discover after removing weapon")
	b.choose_discover(0,0)
	check(b.sides[0].armor==5 and b.death_queue.is_empty() and b.weapon_deaths.is_empty(),"Weapon continuation resolves remaining effects once")
	print("WEAPON DEATHRATTLE: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
