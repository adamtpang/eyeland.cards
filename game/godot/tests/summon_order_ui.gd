extends SceneTree
var checks=0
var failed=0
func check(ok: bool,label: String):
	checks+=1
	if not ok: failed+=1; push_error(label)
func _initialize(): call_deferred("run")
func run():
	var game=preload("res://main.tscn").instantiate()
	game.model.save_path="user://summon-order-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.model.new_profile("warrior","air"); game.page="deck"
	game.start_practice("air","",false,0); game.confirm_opening()
	await create_timer(.5).timeout
	var b=game.battle
	b.record_event("secret",{"owner":0,"id":"earth-pebble-ward"})
	b.summon(0,"home-breeze-finch"); b.summon(0,"home-breeze-finch")
	var removed=b.sides[0].board[0].uid
	var survivor=b.sides[0].board[1].uid
	b.deal_damage(1,0,removed,3,{"type":"spell","element":"fire"}); b.clean(); game.after_action()
	var ghost=game.creature_feedback.get_node("TransientCreature")
	check(not ghost.visible and not game.target_widgets[survivor].visible,"Both transient and surviving summon wait behind Secret")
	game.render()
	check(not game.target_widgets[survivor].visible,"Redraw preserves delayed summon visibility")
	await create_timer(2.35).timeout
	check(ghost.visible and ghost.current_health==2 and game.target_widgets[survivor].visible,"Both summons appear before killing hit")
	await create_timer(.45).timeout
	check(is_instance_valid(ghost) and ghost.current_health==0,"Transient damage and death use shared schedule")
	await create_timer(.5).timeout
	check(game.creature_feedback.get_child_count()==0 and game.target_widgets[survivor].visible,"Dead transient clears while surviving creature stays")
	game.queue_free(); await process_frame; await create_timer(.2).timeout
	print("SUMMON ORDER UI: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
