extends SceneTree
var checks=0
var failed=0
func check(ok: bool,label: String):
	checks+=1
	if not ok: failed+=1; push_error(label)
func _initialize(): call_deferred("run")
func run():
	var game=preload("res://main.tscn").instantiate()
	game.model.save_path="user://moving-effects-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.model.new_profile("warrior","air"); game.page="deck"
	game.start_practice("air","",false,0); game.confirm_opening()
	var b=game.battle
	b.summon(0,"home-breeze-finch"); game.after_action()
	await create_timer(.6).timeout
	var first=b.sides[0].board[0].uid
	var original=game.target_widgets[first].get_global_rect().get_center()
	b.summon(0,"home-breeze-finch")
	var second=b.sides[0].board[1].uid
	b.deal_damage(1,0,first,1,{"type":"spell","element":"fire"})
	b.deal_damage(1,0,second,1,{"type":"spell","element":"fire"}); game.after_action()
	var bolts=game.get_children().filter(func(n): return n is Line2D)
	check(bolts.size()==2,"Hit feedback is retained for a creature absent before redraw")
	await create_timer(.36).timeout
	var endpoint=game.get_global_transform()*bolts[0].points[1]
	var current=game.target_widgets[first].get_global_rect().get_center()
	check(endpoint.distance_to(current)<2 and endpoint.distance_to(original)>40,"Queued bolt uses moved target position at playback")
	await create_timer(.2).timeout
	endpoint=game.get_global_transform()*bolts[1].points[1]
	check(endpoint.distance_to(game.target_widgets[second].get_global_rect().get_center())<2,"Same-action summon receives bolt at its actual position")
	game.page="deck"; game.render(); await create_timer(.3).timeout
	check(game.battle_effects.is_empty(),"Delayed geometry callbacks cancel when leaving")
	game.queue_free(); await process_frame; await create_timer(.2).timeout
	print("MOVING EFFECTS UI: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
