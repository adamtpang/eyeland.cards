extends SceneTree
var checks=0
var failed=0
func check(ok: bool,label: String):
	checks+=1
	if not ok: failed+=1; push_error(label)
func _initialize(): call_deferred("run")
func run():
	var game=preload("res://main.tscn").instantiate()
	game.model.save_path="user://final-feedback-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.model.new_profile("warrior","air"); game.page="deck"
	game.start_practice("air","",false,0); game.confirm_opening()
	await process_frame; await process_frame
	var b=game.battle
	b.resolve_effects(0,[{"effect":"summon","card":"home-breeze-finch","amount":1},{"effect":"damageBoard","amount":4}],b.cards["home-spark"])
	b.clean(); b.outcome=0; game.after_action()
	check(game.battle_audio.last_cue!="victory","Victory sound waits for final presentation")
	check(game.page=="battle" and game.thinking,"Result waits for pending intermediate-creature playback")
	await create_timer(.74).timeout
	check(game.page=="battle" and game.creature_feedback.get_child_count()>0,"Longer feedback is not cut off by fixed final-hit delay")
	await create_timer(.4).timeout
	check(game.page=="result" and not game.thinking,"Result appears after animation finishes")
	check(game.battle_audio.last_cue=="victory","Victory cue begins on results")
	check(game.creature_feedback.get_child_count()==0,"Result has no leftover creature overlay")
	game.queue_free(); await process_frame; await create_timer(.2).timeout
	print("FINAL FEEDBACK UI: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
