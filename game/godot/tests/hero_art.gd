extends SceneTree
const Main=preload("res://main.tscn")
const Battle=preload("res://battle.gd")
var game
var failed=0
var checks=0
var evidence="res://../evidence/godot-hero-art-2026-09-20"
func _initialize(): call_deferred("run")
func check(ok: bool, label: String):
	checks+=1
	if not ok: failed+=1; printerr("FAIL: "+label)
func capture(label: String):
	await process_frame
	await process_frame
	await create_timer(.2).timeout
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png(evidence+"/"+label+".png")
func run():
	evidence=ProjectSettings.globalize_path(evidence).simplify_path()
	DirAccess.make_dir_recursive_absolute(evidence)
	root.size=Vector2i(1280,800)
	game=Main.instantiate()
	game.model.save_path="user://hero-art-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	for job in game.model.world.classes:
		game.model.new_profile(job.id,"fire")
		game.battle=Battle.new(game.model.cards,game.model.profile.deck,game.model.world.encounter.deck,30,12,job,42)
		game.page="battle"
		game.battle.sides[0].mana=2
		game.battle.sides[0].max_mana=2
		game.render()
		var power=game.duel_board.get_node("HeroPower")
		check(power.portrait!=null and game.duel_board.get_node("PlayerHeroPortrait").portrait!=null,job.id+" has portrait and power artwork")
		await capture(job.id+"-ready")
		power.pressed.emit()
		if job.id=="wizard":
			check(game.selection=="power","illustrated Spark opens targeting")
			game.target_enemy(-1)
		var yours=game.battle.sides[0]
		check(yours.mana==0 and yours.power_used and game.duel_board.get_node("HeroPower").disabled,job.id+" artwork button spends mana and disables after use")
		check(yours.armor==2 if job.id=="warrior" else game.battle.sides[1].hp==(10 if job.id=="ranger" else 11),job.id+" power resolves correct effect")
		await capture(job.id+"-used")
	root.size=Vector2i(1024,720)
	await capture("wizard-small-window")
	check(game.body.size.y<=game.size.y-24,"illustrated heroes fit small-window battle")
	var save_path=game.model.save_path
	game.queue_free()
	await create_timer(.2).timeout
	DirAccess.remove_absolute(save_path)
	print("Hero artwork interaction checks: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
