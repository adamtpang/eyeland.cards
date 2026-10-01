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
	b.summon(0,"air-wispwing"); b.summon(0,"fire-coalback-pup")
	b.sides[0].board[0].deathrattle=[{"effect":"discover"},{"effect":"summon","card":"home-breeze-finch","amount":1}]
	for minion in b.sides[0].board: minion.hp=0
	b.clean()
	check(b.pending_choice.owner==0 and b.sides[0].board.is_empty() and b.death_queue.size()==1,"Choice pauses remaining death batch")
	b.clean()
	check(b.death_queue.size()==1,"Repeated cleanup cannot consume queued triggers")
	b.choose_discover(0,0)
	check(b.pending_choice.is_empty() and b.death_queue.is_empty() and b.sides[0].board.size()==2,"Selection resumes current effect then next Deathrattle")
	check(b.log.filter(func(line): return "triggers Deathrattle" in line).size()==2,"Each Deathrattle triggers once")
	check(b.sides[0].board[0].uid<b.sides[0].board[1].uid,"Replacement summons retain order after pause")
	print("DEATH CHOICE: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
