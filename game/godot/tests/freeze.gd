extends SceneTree
var passed=0
var failed=0
func check(ok: bool,label: String):
	if ok: passed+=1
	else: failed+=1; push_error(label)
func _initialize():
	var m=preload("res://model.gd").new()
	var deck=preload("res://collection.gd").practice_deck(m.cards,"water")
	var b=preload("res://battle.gd").new(m.cards,deck,deck,30,30,m.world.classes[0],1)
	b.summon(1,"water-shellback-tortoise")
	b.sides[0].hand=["water-crashing-surf"]; b.sides[0].mana=5
	check(b.play(0,0) and b.sides[1].board[0].frozen and b.sides[1].board[0].hp==4,"Freeze works through Divine Shield")
	var frozen=b.sides[1].board[0]
	b.end_turn(0)
	check(b.attack_targets(1,frozen.uid).is_empty() and not b.attack(1,frozen.uid,-1),"Frozen creature cannot attack on its turn")
	b.end_turn(1)
	check(not frozen.frozen,"Thaws after missing owner's attack")
	b.end_turn(0)
	check(not b.attack_targets(1,frozen.uid).is_empty(),"Creature can attack following turn")
	b.attack(1,frozen.uid,-1); frozen.frozen=true
	b.end_turn(1)
	check(frozen.frozen,"Freeze after attacking persists")
	b.end_turn(0); b.end_turn(1)
	check(not frozen.frozen,"Post-attack freeze expires after next missed turn")
	b.summon(0,"home-breeze-finch")
	var fresh=b.sides[0].board[0]; fresh.frozen=true
	b.end_turn(0)
	check(fresh.frozen,"Summoning sickness does not consume Freeze")
	b.end_turn(1); b.end_turn(0)
	check(not fresh.frozen,"Fresh minion thaws after its first eligible turn")
	b.start_turn(0); b.summon(0,"fire-ember-ram")
	var rush=b.sides[0].board[-1]; rush.frozen=true
	b.end_turn(0)
	check(not rush.frozen,"Rush can miss its immediate attack and thaw")
	b.start_turn(0); b.summon(0,"air-zephyr-dancer"); b.start_turn(0)
	var wind=b.sides[0].board[-1]
	b.sides[1].board=[]
	b.attack(0,wind.uid,-1); wind.frozen=true
	check(b.attack_targets(0,wind.uid).is_empty(),"Freeze blocks remaining Windfury attack")
	b.end_turn(0)
	check(not wind.frozen,"Windfury thaws after missing remaining attack")
	b.start_turn(0); b.attack(0,wind.uid,-1); b.attack(0,wind.uid,-1); wind.frozen=true
	b.end_turn(0)
	check(wind.frozen,"Freeze after both Windfury attacks persists")
	print("FREEZE: ",passed," passed; ",failed," failed")
	quit(1 if failed else 0)
