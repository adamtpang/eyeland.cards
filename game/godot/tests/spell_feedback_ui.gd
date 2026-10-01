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
	game.model.save_path="user://spell-fx-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.model.new_profile("warrior","air"); game.page="deck"
	game.start_practice("air","",false,0); game.confirm_opening()
	var b=game.battle
	b.sides[0].hand=["air-gust-bolt"]; b.sides[0].mana=10
	game.render(); await process_frame; await process_frame
	game.play_card(0); game.target_enemy(-1)
	check(game.get_node_or_null("SpellHit")!=null,"Player targeted spell shows elemental bolt")
	var labels=game.get_children().filter(func(n): return n is Label and n.text=="−3")
	check(labels.size()==1,"Targeted spell produces one damage number")
	check(labels[0].z_index>game.creature_feedback.z_index,"Damage numbers stay above animated creature portraits")
	var count=game.get_child_count(); game.show_spell_hits()
	check(game.get_child_count()==count,"Spell event is not replayed")
	await wait_for_feedback(game)
	b.summon(0,"water-shellback-tortoise"); b.summon(0,"home-breeze-finch")
	b.active=1; b.sides[1].hand=["water-crashing-surf"]; b.sides[1].mana=10
	game.render(); await process_frame; await process_frame
	b.play(1,0); game.after_action()
	var bolts=game.get_children().filter(func(n): return n is Line2D)
	labels=game.get_children().filter(func(n): return n is Label and n.text=="−3")
	check(bolts.size()==2,"Opponent area spell reaches both targets")
	check(labels.size()==1,"Shield absorbs hit without false damage number")
	await wait_for_feedback(game)
	check(game.get_children().filter(func(n): return n is Line2D).is_empty(),"Spell bolts clean up")
	b.active=0; b.sides[0].hand=["air-gust-bolt"]; b.sides[0].mana=1
	game.render(); game.play_card(0); game.target_enemy(-1)
	game.attack_lunge("home-breeze-finch",Vector2(300,300),Vector2(500,200))
	check(game.battle_effects.size()>=3,"Active bolt, number and lunge are tracked")
	game.page="deck"; game.render()
	check(game.battle_effects.is_empty() and game.battle_effect_tweens.is_empty(),"Leaving battle cancels effect nodes and tweens")
	check(game.get_node_or_null("SpellHit")==null and game.get_node_or_null("AttackLunge")==null and game.get_node_or_null("DamageFeedback")==null,"No combat overlay remains over collection")
	await wait_for_feedback(game)
	check(game.battle_effects.is_empty(),"Canceled effects do not return")
	game.queue_free(); await process_frame; await create_timer(.1).timeout
	print("SPELL FEEDBACK UI: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)

func wait_for_feedback(game):
	var deadline=Time.get_ticks_msec()+5000
	while game.feedback_busy() and Time.get_ticks_msec()<deadline:
		await create_timer(.05).timeout
