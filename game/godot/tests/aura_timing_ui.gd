extends SceneTree
var checks=0
var failed=0
func check(ok: bool,label: String):
	checks+=1
	if not ok: failed+=1; push_error(label)
func _initialize(): call_deferred("run")
func run():
	var game=preload("res://main.tscn").instantiate()
	game.model.save_path="user://aura-timing-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.model.new_profile("warrior","air"); game.page="deck"
	game.start_practice("air","",false,0); game.confirm_opening()
	var b=game.battle
	b.summon(0,"home-breeze-finch"); game.after_action()
	await create_timer(.6).timeout
	var uid=b.sides[0].board[0].uid
	b.record_event("secret",{"owner":0,"id":"earth-pebble-ward"})
	b.summon(0,"fire-cinder-captain"); game.after_action()
	check(game.target_widgets[uid].current_attack==2,"Aura does not appear before its source summon")
	await create_timer(2.55).timeout
	check(game.target_widgets[uid].current_attack==3 and "Active auras: +1" in game.target_widgets[uid].tooltip_text,"Aura and hover update after summon")
	var captain=b.sides[0].board[1]
	b.deal_damage(1,0,captain.uid,20,{"type":"spell","element":"fire"}); b.clean(); game.after_action()
	check(game.target_widgets[uid].current_attack==3,"Aura persists visually until source death")
	await create_timer(.75).timeout
	check(game.target_widgets[uid].current_attack==2 and not "Active auras:" in game.target_widgets[uid].tooltip_text,"Source death removes aura stats and hover")
	game.queue_free(); await process_frame; await create_timer(.2).timeout
	print("AURA TIMING UI: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
