extends SceneTree
var checks=0
var failed=0
func check(ok: bool,label: String):
	checks+=1
	if not ok: failed+=1; push_error(label)
func _initialize(): call_deferred("run")
func run():
	var game=preload("res://main.tscn").instantiate()
	game.model.save_path="user://multi-layout-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.model.new_profile("warrior","air"); game.page="deck"
	game.start_practice("air","",false,0); game.confirm_opening()
	var b=game.battle
	b.summon(0,"home-breeze-finch"); game.after_action()
	await create_timer(.6).timeout
	var uid=b.sides[0].board[0].uid
	var before=game.target_widgets[uid].position.x
	b.record_event("secret",{"owner":0,"id":"earth-pebble-ward"})
	b.summon(0,"home-breeze-finch"); b.summon(0,"home-breeze-finch"); game.after_action()
	await create_timer(2.18).timeout
	check(absf(game.target_widgets[uid].position.x-(before-52.5))<2,"First summon produces two-creature intermediate layout")
	game.render()
	check(absf(game.target_widgets[uid].position.x-(before-52.5))<2,"Redraw retains intermediate layout")
	await create_timer(.14).timeout
	check(game.target_widgets[uid].position.x<before-52.5 and game.target_widgets[uid].position.x>before-105,"Second summon slides from intermediate to final layout")
	await create_timer(.35).timeout
	check(absf(game.target_widgets[uid].position.x-(before-105))<1,"Three-creature layout settles")
	check(game.creature_feedback.movement_tracks.is_empty(),"Completed multi-step movement clears")
	game.queue_free(); await process_frame; await create_timer(.2).timeout
	print("MULTI LAYOUT UI: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
