extends SceneTree
var checks=0
var failed=0
func check(ok: bool,label: String):
	checks+=1
	if not ok: failed+=1; push_error(label)
func _initialize(): call_deferred("run")
func run():
	var game=preload("res://main.tscn").instantiate()
	game.model.save_path="user://thaw-timing-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.model.new_profile("warrior","air"); game.page="deck"
	game.start_practice("air","",false,0); game.confirm_opening()
	var b=game.battle
	b.summon(1,"home-breeze-finch"); game.after_action()
	await create_timer(.6).timeout
	var m=b.sides[1].board[0]; m.summoning_sick=false
	b.record_event("secret",{"owner":1,"id":"earth-pebble-ward"})
	b.resolve_effects(0,[{"effect":"freezeTarget"},{"effect":"freezeEnemies"}],b.cards["home-spark"],-1)
	game.after_action()
	check(game.target_widgets[-1].modulate==Color.WHITE and game.target_widgets[m.uid].status=="","Hero and creature wait for queued Freeze")
	await create_timer(2.3).timeout
	check(game.target_widgets[-1].modulate==Color("8ecde8") and game.target_widgets[m.uid].status=="FROZEN","Freeze appears on both character types")
	b.active=1; b.end_turn(1); game.after_action()
	check(not b.sides[1].frozen and not m.frozen,"Missed attack opportunity thaws both")
	check(game.target_widgets[-1].modulate==Color.WHITE and game.target_widgets[m.uid].status=="","Thaw clears portrait tint and creature status")
	check(not "Frozen:" in game.target_widgets[-1].tooltip_text,"Hero hover clears frozen instruction")
	game.queue_free(); await process_frame; await create_timer(.2).timeout
	print("THAW TIMING UI: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
