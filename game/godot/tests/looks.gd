extends SceneTree
## Day and night looks: every look renders the battle and collection without errors,
## switches with F5, and keeps the battle inside the window. Saves screenshots as evidence.
const UIStyle=preload("res://skin.gd")
var checks=0
var failed=0
func check(ok: bool,label: String):
	checks+=1
	if not ok: failed+=1; push_error(label)
func _initialize(): call_deferred("run")

func shot(folder: String,file: String):
	if DisplayServer.get_name()=="headless": return
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png(folder.path_join(file))

func run():
	var folder=ProjectSettings.globalize_path("res://").path_join("../evidence/looks-2026-10-01")
	DirAccess.make_dir_recursive_absolute(folder)
	var game=preload("res://main.tscn").instantiate()
	game.model.save_path="user://looks-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	check(UIStyle.mode=="day","Tests start in the day look")
	game.model.new_profile("warrior","air"); game.page="deck"; game.render()
	await create_timer(.4).timeout
	for look in ["day","night","classic"]:
		game.choose_look(look); game.render()
		await create_timer(.3).timeout
		shot(folder,"collection-%s.png" % look)
		check(UIStyle.P==UIStyle.LOOKS[look] and UIStyle.TEXT==UIStyle.LOOKS[look].text,"%s: tokens are active" % look)
	game.choose_look("day")
	game.start_practice("air","",false,0); game.confirm_opening()
	var b=game.battle
	for id in ["water-reef-otter","home-shore-guard"]: b.summon(0,id)
	for id in ["home-breeze-finch","home-resin-crab","home-emberling"]: b.summon(1,id)
	b.sides[0].mana=5; b.sides[0].max_mana=5
	game.after_action()
	await create_timer(1.2).timeout
	for look in ["day","night","classic"]:
		game.choose_look(look); game.render()
		await create_timer(.4).timeout
		shot(folder,"battle-%s.png" % look)
		check(game.body.size.y<=game.size.y-24,"%s: battle fits the window" % look)
		check(is_instance_valid(game.duel_board) and game.duel_board.hand_faces.size()>0,"%s: hand is drawn" % look)
		var face=game.duel_board.hand_faces[0]
		check(face.material!=null and is_equal_approx(face.material.get_shader_parameter("style"),float(UIStyle.P.art_style)),"%s: card art uses the look's art style" % look)
	game.choose_look("day"); game.render(); await process_frame
	for expected in ["night","classic","day"]:
		var key=InputEventKey.new(); key.keycode=KEY_F5; key.pressed=true
		Input.parse_input_event(key)
		await process_frame; await process_frame
		check(UIStyle.mode==expected,"F5 switches to %s" % expected)
	game.queue_free(); await process_frame; await create_timer(.2).timeout
	UIStyle.set_mode("day")
	print("LOOKS: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
