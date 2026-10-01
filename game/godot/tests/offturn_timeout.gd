extends SceneTree
var checks=0
var failed=0
func check(ok: bool,label: String):
	checks+=1
	if not ok: failed+=1; push_error(label)
func _initialize(): call_deferred("run")
func run():
	var game=preload("res://main.tscn").instantiate()
	game.model.save_path="user://choice-timeout-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.model.new_profile("warrior","air"); game.page="deck"
	game.start_practice("air","",false,0); game.confirm_opening()
	var b=game.battle
	b.active=1; game.thinking=true
	b.resolve_effects(0,[{"effect":"discover"}],b.cards["air-windfall"])
	game.after_action()
	var selected=b.pending_choice.offers[0]
	game._process(1.0)
	check(game.choice_clock_running and game.choice_timer_label.text=="74s","Off-turn choice displays active countdown")
	var own_clock=game.clock_left
	game._process(74.1)
	check(b.pending_choice.is_empty() and b.sides[0].hand.has(selected),"Expiry chooses first offered card")
	check(b.active==1 and game.clock_left==own_clock,"Timeout preserves opponent turn and player turn budget")
	game._process(.1)
	b.resolve_effects(0,[{"effect":"discover"}],b.cards["air-windfall"]); game.after_action(); game._process(1.0)
	check(game.choice_clock_left==74.0,"Later independent off-turn choice receives fresh countdown")
	game.duel_board.get_node("DiscoverOption1").pressed.emit()
	check(b.pending_choice.is_empty(),"Manual selection remains available before timeout")
	b.active=0; game.thinking=false; game.clock_left=.1
	b.record_event("secret",{"owner":1,"id":"earth-pebble-ward"})
	b.resolve_effects(0,[{"effect":"discover"}],b.cards["air-windfall"])
	selected=b.pending_choice.offers[0]
	game.after_action(); game._process(.2)
	check(not b.pending_choice.is_empty() and b.active==0,"Expired own-turn clock waits for preceding reveal")
	check(game.duel_board.get_node_or_null("DiscoverOption0")==null,"Expired clock does not expose choices through reveal")
	game.choose_presented_card(1)
	check(not b.pending_choice.is_empty(),"Early callback cannot bypass expired-clock presentation gate")
	var deadline=Time.get_ticks_msec()+5000
	while not b.pending_choice.is_empty() and Time.get_ticks_msec()<deadline:
		await create_timer(.05).timeout
	check(b.pending_choice.is_empty() and b.sides[0].hand.has(selected) and b.active==1,"After reveal expiry selects first offer and passes turn without stalling")
	game.queue_free(); await process_frame; await create_timer(.3).timeout
	print("OFFTURN TIMEOUT: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
