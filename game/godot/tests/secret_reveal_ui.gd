extends SceneTree
var failures=0
var checks=0
func check(ok: bool,label: String):
	checks+=1
	if not ok: failures+=1; push_error(label)
func _initialize(): call_deferred("run")
func run():
	root.size=Vector2i(1280,800)
	var game=preload("res://main.tscn").instantiate()
	game.model.save_path="user://reveal-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.model.new_profile("warrior","air"); game.page="deck"
	game.start_practice("air","",false,0); game.confirm_opening()
	var b=game.battle
	b.sides[1].secrets=["earth-pebble-ward"]
	game.after_action()
	check(game.secret_reveal.get_child_count()==0,"Hidden Secret has no reveal portrait")
	b.sides[0].weapon={"attack":2,"durability":2}
	b.attack(0,-1,-1); game.after_action()
	await create_timer(.3).timeout
	var face=game.secret_reveal.get_child(0)
	check(face.card.id=="earth-pebble-ward" and face.modulate.a==1,"Triggered Secret reveals full card")
	check(game.battle_audio.last_cue=="secret","Secret sound precedes delayed attack sound")
	check(not game.get_node("AttackLunge").visible and not game.get_node("DamageFeedback").visible,"Attack and damage wait for readable Secret reveal")
	check(face.mouse_filter==Control.MOUSE_FILTER_IGNORE,"Reveal does not intercept battle input")
	game.after_action()
	check(game.secret_reveal.get_child_count()==1 and game.secret_reveal.queued.is_empty(),"Repeated render does not duplicate reveal")
	await process_frame; await process_frame
	if DisplayServer.get_name()!="headless":
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../evidence/secret-reveal.png"))
	await create_timer(1.8).timeout
	check(game.secret_reveal.get_child_count()==0,"Reveal dismisses automatically")
	check(game.get_node("DamageFeedback").visible,"Combat impact follows the reveal")
	check(game.battle_audio.last_cue=="attack","Attack sound follows reveal at combat impact")
	game.page="deck"; game.render()
	await create_timer(.3).timeout
	check(game.battle_effects.is_empty() and not game.secret_reveal.showing,"Leaving clears delayed combat and Secret presentation")
	game.queue_free(); await process_frame; await create_timer(.1).timeout
	print("SECRET REVEAL UI: %d / %d passed" % [checks-failures,checks])
	quit(1 if failures else 0)
