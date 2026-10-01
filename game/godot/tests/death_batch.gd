extends SceneTree
var checks=0
var failed=0
var model=preload("res://model.gd").new()
func check(ok: bool,label: String):
	checks+=1
	if not ok: failed+=1; push_error(label)
func fixture():
	var deck=preload("res://collection.gd").practice_deck(model.cards,"fire")
	return preload("res://battle.gd").new(model.cards,deck,deck,30,30,model.world.classes[0],1)
func _initialize():
	var b=fixture()
	b.summon(0,"fire-coalback-pup"); b.summon(1,"fire-coalback-pup")
	b.sides[0].board[0].deathrattle=[{"effect":"silenceEnemies"}]
	b.sides[0].board[0].hp=0; b.sides[1].board[0].hp=0
	b.clean()
	check(b.sides[1].board.size()==1 and b.sides[1].board[0].id=="home-breeze-finch","Silence cannot erase an already queued deathrattle")
	b=fixture()
	b.summon(0,"fire-coalback-pup"); b.summon(0,"fire-coalback-pup"); b.summon(1,"fire-coalback-pup")
	b.sides[0].board[0].deathrattle=[{"effect":"damageEnemies","amount":10}]
	b.sides[0].board[1].deathrattle=[{"effect":"damageEnemies","amount":10}]
	b.sides[0].board[0].hp=0; b.sides[0].board[1].hp=0
	b.clean()
	check(b.sides[1].board.size()==1 and b.sides[1].board[0].id=="home-breeze-finch","Chained summon waits until existing death batch completes")
	check(b.log.filter(func(line): return "triggers Deathrattle" in line).size()==3,"Each death triggers exactly once across batches")
	b=fixture()
	b.summon(0,"fire-coalback-pup"); b.summon(0,"fire-coalback-pup"); b.summon(0,"home-breeze-finch")
	b.sides[0].board[0].deathrattle=[{"effect":"damageBoard","amount":10}]
	b.sides[0].board[1].deathrattle=[{"effect":"healBoard","amount":20},{"effect":"buffAll","attack":2,"health":20}]
	b.sides[0].board[0].hp=0; b.sides[0].board[1].hp=0
	b.clean()
	check(b.sides[0].board.is_empty(),"Mortally wounded creature cannot be revived by later heal or buff in batch")
	check(b.death_queue.is_empty() and b.resolving_death.is_empty(),"Batch drains all continuation state")
	print("DEATH BATCH: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
