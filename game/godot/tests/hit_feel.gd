extends SceneTree
## Attack-feel variations: each one plays, lands on time, shows its effects, and cleans up.
var checks=0
var failed=0
func check(ok: bool,label: String):
	checks+=1
	if not ok: failed+=1; push_error(label)
func _initialize(): call_deferred("run")

func shot(folder: String,file: String):
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png(folder.path_join(file))

func run():
	var folder=ProjectSettings.globalize_path("res://").path_join("../evidence/hit-feel-2026-10-01")
	DirAccess.make_dir_recursive_absolute(folder)
	var game=preload("res://main.tscn").instantiate()
	game.model.save_path="user://hit-feel-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.model.new_profile("warrior","air"); game.page="deck"
	game.start_practice("air","",false,0); game.confirm_opening()
	var b=game.battle
	var feel=game.hit_feel
	b.summon(0,"water-reef-otter"); b.summon(1,"home-breeze-finch"); game.after_action()
	await create_timer(1.0).timeout
	var attacker=b.sides[0].board[0]
	var defender=b.sides[1].board[0]
	check(feel.variant==0,"Original feel is the default")
	for v in [1,2,3,0]:
		feel.set_variant(v)
		defender.hp=30; attacker.hp=30
		attacker.ready=true; attacker.summoning_sick=false
		var fights=b.combat_events.size()
		b.attack(0,attacker.uid,defender.uid); game.after_action()
		check(b.combat_events.size()==fights+1,"Variant %d: the attack resolved" % v)
		check(game.has_node("AttackLunge"),"Variant %d: the attacker lunges" % v)
		await create_timer(feel.IMPACT[v]+.04).timeout
		shot(folder,"variant-%d-impact.png" % v)
		check(game.battle_audio.last_cue==feel.CUES[v],"Variant %d: plays its own hit sound" % v)
		if v!=0:
			check(game.get_children().any(func(n): return String(n.name).begins_with("HitEffect")),"Variant %d: impact effect appears on the hit" % v)
			check(game.get_children().any(func(n): return String(n.name).begins_with("DamageFeedback") and n.visible),"Variant %d: damage number appears on the hit" % v)
		await create_timer(.12).timeout
		check(game.target_widgets[defender.uid].current_health==30-int(attacker.atk),"Variant %d: shown health drops when the hit lands" % v)
		await create_timer(1.6).timeout
		check(game.battle_effects.filter(func(n): return is_instance_valid(n)).is_empty(),"Variant %d: effects clean up" % v)
		check(root.canvas_transform==Transform2D.IDENTITY,"Variant %d: screen shake settles" % v)
		var face=game.target_widgets[defender.uid]
		check(face.scale.is_equal_approx(Vector2.ONE) and absf(face.rotation)<.01,"Variant %d: target returns to rest" % v)
		check(is_equal_approx(game.duel_board.friendly_faces[attacker.uid].modulate.a,1.0),"Variant %d: attacker is fully visible again" % v)
	# a hit on the enemy hero, and a killing blow, in the heaviest variant
	feel.set_variant(2)
	attacker.ready=true; attacker.summoning_sick=false
	var hero_before=b.sides[1].hp
	b.attack(0,attacker.uid,-1); game.after_action()
	await create_timer(feel.IMPACT[2]+.04).timeout
	shot(folder,"variant-2-hero.png")
	check(b.sides[1].hp<hero_before,"Hero hit resolves")
	await create_timer(1.6).timeout
	feel.set_variant(3)
	defender.hp=1; attacker.ready=true; attacker.summoning_sick=false
	b.attack(0,attacker.uid,defender.uid); game.after_action()
	await create_timer(feel.IMPACT[3]+.04).timeout
	shot(folder,"variant-3-kill.png")
	await create_timer(1.8).timeout
	check(b.sides[1].board.is_empty(),"Killing blow removes the defender")
	check(game.battle_effects.filter(func(n): return is_instance_valid(n)).is_empty() and root.canvas_transform==Transform2D.IDENTITY,"Killing blow cleans up")
	# keys switch the feel during a battle
	for pair in [[KEY_F3,2],[KEY_F4,3],[KEY_F2,1],[KEY_F1,0]]:
		var key=InputEventKey.new(); key.keycode=pair[0]; key.pressed=true
		Input.parse_input_event(key)
		await process_frame; await process_frame
		check(feel.variant==pair[1],"Function key selects variant %d" % pair[1])
	check(game.get_node("HitFeelLabel").visible,"Current feel is labelled in battle")
	# leaving mid-attack must not leave a shaken screen behind
	feel.set_variant(2)
	b.summon(1,"home-breeze-finch"); game.after_action(); await create_timer(.6).timeout
	attacker.ready=true; attacker.summoning_sick=false
	b.attack(0,attacker.uid,b.sides[1].board[0].uid); game.after_action()
	await create_timer(feel.IMPACT[2]+.05).timeout
	game.page="deck"; game.render(); await create_timer(.4).timeout
	check(game.battle_effects.filter(func(n): return is_instance_valid(n)).is_empty(),"Effects clear on leaving battle")
	check(root.canvas_transform==Transform2D.IDENTITY,"Shake stops on leaving battle")
	check(not game.get_node("HitFeelLabel").visible,"Label hides outside battle")
	game.queue_free(); await process_frame; await create_timer(.2).timeout
	print("HIT FEEL: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
