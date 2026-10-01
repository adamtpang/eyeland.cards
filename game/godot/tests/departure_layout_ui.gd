extends SceneTree
var checks=0
var failed=0
func check(ok: bool,label: String):
	checks+=1
	if not ok: failed+=1; push_error(label)
func _initialize(): call_deferred("run")
func run():
	var game=preload("res://main.tscn").instantiate()
	game.model.save_path="user://departure-layout-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.model.new_profile("warrior","air"); game.page="deck"
	game.start_practice("air","",false,0); game.confirm_opening()
	var b=game.battle
	for i in range(3): b.summon(0,"home-breeze-finch")
	game.after_action(); await create_timer(1.2).timeout
	var uid=b.sides[0].board[2].uid
	var before=game.target_widgets[uid].global_position.x-game.creature_feedback.global_position.x
	b.sides[0].board[1].hp=0; b.sides[0].board[2].hp=0; b.clean(); game.after_action()
	var ghost=game.creature_feedback.get_children().filter(func(n): return n.get_meta("uid",-1)==uid)[0]
	check(absf(ghost.position.x-before)<1,"Second departing portrait begins at original slot")
	await create_timer(.45).timeout
	check(is_instance_valid(ghost) and ghost.position.x<before and ghost.position.x>before-game.duel_board.gap()/2,"Later departure follows earlier death layout")
	game.render()
	check(game.creature_feedback.get_children().filter(func(n): return n.get_meta("uid",-1)==uid).size()==1,"Redraw does not duplicate departing portrait")
	await create_timer(.4).timeout
	check(game.creature_feedback.get_child_count()==0,"Chained departures remove both portraits")
	game.queue_free(); await process_frame; await create_timer(.2).timeout
	print("DEPARTURE LAYOUT UI: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
