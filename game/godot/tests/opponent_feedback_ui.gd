extends SceneTree
var checks=0
var failed=0
func check(ok: bool,label: String):
	checks+=1
	if not ok: failed+=1; push_error(label)
func _initialize(): call_deferred("run")
func run():
	root.size=Vector2i(1280,800)
	var game=preload("res://main.tscn").instantiate()
	game.model.save_path="user://opponent-fx-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.model.new_profile("warrior","air"); game.page="deck"
	game.start_practice("air","",false,0); game.confirm_opening()
	var b=game.battle
	b.summon(1,"home-breeze-finch")
	var attacker=b.sides[1].board[0]
	attacker.ready=true; attacker.summoning_sick=false
	b.active=1; game.render(); await process_frame; await process_frame
	b.attack(1,attacker.uid,-1); game.after_action()
	check(game.get_node_or_null("AttackLunge")!=null,"Opponent creature gets attack lunge")
	check(game.get_node("DamageFeedback").text=="−2","Opponent damage appears on player hero")
	var count=game.get_child_count(); game.show_opponent_attacks()
	check(game.get_child_count()==count,"Repeated observer does not replay combat")
	await wait_for_feedback(game)
	check(game.get_node_or_null("AttackLunge")==null and game.get_node_or_null("DamageFeedback")==null,"Attack feedback clears")
	b.sides[1].weapon={"attack":3,"durability":2}; game.render()
	await process_frame; await process_frame
	var portrait=game.target_widgets[-1].portrait
	b.attack(1,-1,-1); game.after_action()
	check(game.get_node("AttackLunge").texture==portrait,"Opponent hero lunge uses opponent portrait")
	check(game.get_node("DamageFeedback").text=="−3","Weapon damage appears correctly")
	game.queue_free(); await process_frame; await create_timer(.1).timeout
	print("OPPONENT FEEDBACK UI: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)

func wait_for_feedback(game):
	var deadline=Time.get_ticks_msec()+5000
	while game.feedback_busy() and Time.get_ticks_msec()<deadline:
		await create_timer(.05).timeout
