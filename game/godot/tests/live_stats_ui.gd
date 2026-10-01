extends SceneTree
var checks=0
var failed=0
func check(ok: bool,label: String):
	checks+=1
	if not ok: failed+=1; push_error(label)
func _initialize(): call_deferred("run")
func run():
	var game=preload("res://main.tscn").instantiate()
	game.model.save_path="user://live-stats-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.model.new_profile("warrior","air"); game.page="deck"
	game.start_practice("air","",false,0); game.confirm_opening()
	var b=game.battle
	b.summon(0,"home-breeze-finch"); game.after_action()
	await create_timer(.5).timeout
	var uid=b.sides[0].board[0].uid
	b.record_event("secret",{"owner":0,"id":"earth-pebble-ward"})
	b.deal_damage(1,0,uid,1,{"type":"spell","element":"fire"})
	b.heal_character(0,uid,1); b.buff_creature(0,uid,2,2)
	game.after_action()
	check(game.target_widgets[uid].current_health==2 and game.target_widgets[uid].current_attack==2,"Stats retain pre-effect values during Secret")
	game.render()
	check(game.target_widgets[uid].current_health==2,"Redraw cannot skip queued stat updates")
	await create_timer(2.02).timeout
	check(game.target_widgets[uid].current_health==1,"Damage snapshot appears at spell hit")
	await create_timer(.22).timeout
	check(game.target_widgets[uid].current_health==2,"Heal restores displayed health in order")
	await create_timer(.23).timeout
	check(game.target_widgets[uid].current_health==4 and game.target_widgets[uid].current_attack==4,"Buff snapshot appears last")
	check(game.creature_feedback.stat_steps.is_empty(),"Completed stat queue clears")
	game.queue_free(); await process_frame; await create_timer(.2).timeout
	print("LIVE STATS UI: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
