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
	game.model.save_path="user://healing-ui-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.model.new_profile("warrior","water"); game.page="deck"
	game.start_practice("water","",false,0); game.confirm_opening()
	var b=game.battle
	for owner in [0,1]:
		b.sides[owner].hp=29
		b.summon(owner,"water-reef-otter")
		game.after_action()
		while game.feedback_busy() or game.effect_schedule_until>Time.get_ticks_usec()/1000000.0:
			await create_timer(.05).timeout
		var otter=b.sides[owner].board[0]
		otter.ready=true; otter.summoning_sick=false; b.active=owner
		var cursor=b.timeline.size()
		b.attack(owner,otter.uid,-1); game.after_action()
		var events=b.timeline.slice(cursor)
		check(events[0].kind=="combat" and events[-1].kind=="heal" and events[-1].sequence==events[0].sequence+events.size()-1,"Combat precedes Lifesteal with consecutive timeline positions")
		var labels=game.get_children().filter(func(n): return n is Label and n.text=="+1")
		check(labels.size()==1 and b.sides[owner].hp==30,"Lifesteal displays only actual missing health for each side")
		check(labels[0].get_theme_color("font_color")==Color("a8e8b0"),"Healing uses green positive feedback")
		check(not labels[0].visible and game.get_node_or_null("AttackLunge")!=null,"Attack begins before Lifesteal becomes visible")
		await create_timer(.3).timeout
		check(labels[0].visible,"Lifesteal follows the attack impact")
		await create_timer(.65).timeout
		otter.hp=1
		b.resolve_effects(owner,[{"effect":"healBoard","amount":20}],b.cards[otter.id]); game.after_action()
		check(game.get_children().filter(func(n): return n is Label and n.text=="+2").size()==1,"Board healing shows restored amount")
		await create_timer(.75).timeout
		var count=b.healing_events.size()
		b.resolve_effects(owner,[{"effect":"healBoard","amount":20}],b.cards[otter.id]); game.after_action()
		check(b.healing_events.size()==count,"Full health produces no misleading healing event")
	game.queue_free(); await process_frame; await create_timer(.1).timeout
	print("HEALING UI: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
