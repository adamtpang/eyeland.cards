extends SceneTree
var checks=0
var failed=0
func check(ok: bool,label: String):
	checks+=1
	if not ok: failed+=1; push_error(label)
func _initialize(): call_deferred("run")
func run():
	var game=preload("res://main.tscn").instantiate()
	game.model.save_path="user://death-order-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.model.new_profile("warrior","air"); game.page="deck"
	game.start_practice("air","",false,0); game.confirm_opening()
	var b=game.battle
	b.summon(1,"home-breeze-finch"); game.after_action()
	await create_timer(.5).timeout
	var uid=b.sides[1].board[0].uid
	b.record_event("secret",{"owner":1,"id":"earth-pebble-ward"})
	b.deal_damage(0,1,uid,3,{"type":"spell","element":"fire"}); b.clean()
	game.after_action()
	var ghost=game.creature_feedback.get_node("DepartingCreature")
	check(ghost.current_health==2 and ghost.modulate.a==1,"Removed creature retains pre-hit portrait during reveal")
	await create_timer(1.5).timeout
	check(is_instance_valid(ghost) and ghost.current_health==2 and ghost.modulate.a==1,"Death cannot overtake preceding Secret")
	await create_timer(.8).timeout
	check(is_instance_valid(ghost) and ghost.current_health==0 and ghost.modulate.a<1,"Creature dies after killing spell feedback begins")
	await create_timer(.4).timeout
	check(game.creature_feedback.get_child_count()==0,"Ordered death cleans up")
	game.queue_free(); await process_frame; await create_timer(.2).timeout
	print("DEATH ORDER UI: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
