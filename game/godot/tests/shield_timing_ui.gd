extends SceneTree
var checks=0
var failed=0
func check(ok: bool,label: String):
	checks+=1
	if not ok: failed+=1; push_error(label)
func _initialize(): call_deferred("run")
func run():
	var game=preload("res://main.tscn").instantiate()
	game.model.save_path="user://shield-timing-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.model.new_profile("warrior","air"); game.page="deck"
	game.start_practice("air","",false,0); game.confirm_opening()
	var b=game.battle
	b.summon(1,"water-shellback-tortoise"); game.after_action()
	await create_timer(.6).timeout
	var m=b.sides[1].board[0]
	var hp=m.hp
	b.record_event("secret",{"owner":1,"id":"earth-pebble-ward"})
	b.deal_damage(0,1,m.uid,3,{"type":"spell","element":"fire"}); game.after_action()
	check(game.target_widgets[m.uid].shield_active and not m.divine_shield,"Display retains Shield while queued engine hit has resolved")
	game.render()
	check(game.target_widgets[m.uid].shield_active,"Redraw preserves pending Shield")
	await create_timer(2.1).timeout
	check(not game.target_widgets[m.uid].shield_active and game.target_widgets[m.uid].current_health==hp,"Impact removes Shield without damaging displayed health")
	check(game.get_children().filter(func(n): return n is Label and n.text=="−3").is_empty(),"Absorbed damage has no false damage number")
	game.queue_free(); await process_frame; await create_timer(.2).timeout
	print("SHIELD TIMING UI: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
