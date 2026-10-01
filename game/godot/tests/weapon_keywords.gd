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
	var c=b.cards["earth-earthen-spear"]
	c.lifesteal=true; c.windfury=true; c.poisonous=true
	c.onPlay=[{"effect":"equipWeapon","attack":3,"durability":4}]
	b.sides[0].hand=[c.id]; b.sides[0].mana=3; b.sides[0].hp=20
	b.play(0,0)
	b.summon(1,"home-breeze-finch")
	var target=b.sides[1].board[0]; target.hp=10; target.max_hp=10
	check(b.attack(0,-1,target.uid) and b.sides[1].board.is_empty(),"Poisonous weapon destroys damaged minion")
	check(b.sides[0].hp==21,"Weapon Lifesteal heals after retaliation")
	check(b.attack(0,-1,-1) and b.sides[0].hp==24 and b.sides[0].weapon.durability==2,"Windfury weapon grants second swing with Lifesteal and durability use")
	check(not b.attack(0,-1,-1),"Windfury weapon rejects third swing")
	b.end_turn(0); b.end_turn(1)
	b.attack(0,-1,-1); b.sides[0].frozen=true
	check(not b.attack(0,-1,-1),"Freeze blocks remaining Windfury swing")
	b.end_turn(0)
	check(not b.sides[0].frozen,"Missing remaining Windfury attack clears Freeze at end of turn")
	print("WEAPON KEYWORDS: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
