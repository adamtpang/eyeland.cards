extends SceneTree
var checks=0
var failed=0
func check(ok: bool,label: String):
	checks+=1
	if not ok: failed+=1; push_error(label)
func _initialize(): call_deferred("run")
func run():
	var game=preload("res://main.tscn").instantiate()
	game.model.save_path="user://hero-stats-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.model.new_profile("warrior","air"); game.page="deck"
	game.start_practice("air","",false,0); game.confirm_opening()
	await create_timer(.5).timeout
	var b=game.battle
	b.sides[1].secrets=["earth-pebble-ward"]
	b.sides[0].weapon={"attack":3,"durability":2}
	b.attack(0,-1,-1); game.after_action()
	check(game.duel_board.get_node("HeroStats1").get_meta("state").armor==0,"Hero Armor stays unchanged during Secret reveal")
	game.render()
	check(game.duel_board.get_node("HeroStats1").get_meta("state").armor==0,"Redraw preserves queued hero state")
	await create_timer(2.0).timeout
	check(game.duel_board.get_node("HeroStats1").get_meta("state").armor==8,"Secret grants visible Armor before combat damage")
	await create_timer(.25).timeout
	check(game.duel_board.get_node("HeroStats1").get_meta("state").armor==5,"Weapon damage consumes displayed Armor after impact")
	check(game.creature_feedback.hero_steps.is_empty(),"Completed hero snapshots clear")
	game.queue_free(); await process_frame; await create_timer(.2).timeout
	print("HERO STATS UI: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
