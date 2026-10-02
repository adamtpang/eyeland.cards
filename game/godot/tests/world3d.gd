extends SceneTree
const Main=preload("res://main.tscn")
var game
var checks=0
var failed=0
var evidence="res://../evidence/godot-third-person-2026-09-20"

func check(ok: bool,message: String):
	checks+=1
	if not ok: failed+=1; printerr("FAIL: "+message)

func _initialize(): call_deferred("run")

func key(code: int,down: bool):
	var event=InputEventKey.new()
	event.keycode=code
	event.pressed=down
	root.push_input(event)

func shot(name_value: String):
	await process_frame
	await process_frame
	if DisplayServer.get_name()!="headless":
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png(evidence+"/"+name_value+".png")

func run():
	create_timer(60).timeout.connect(func(): printerr("3D test timeout"); quit(1))
	evidence=ProjectSettings.globalize_path(evidence).simplify_path()
	DirAccess.make_dir_recursive_absolute(evidence)
	root.size=Vector2i(1280,800)
	game=Main.instantiate()
	game.model.save_path="user://world3d-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.begin()
	await create_timer(1).timeout
	var world=game.world3d
	check(world.player.is_on_floor(),"actual CharacterBody3D grounded on terrain")
	await shot("third-person-home")
	var start=world.player.position
	key(KEY_D,true)
	await create_timer(.5).timeout
	key(KEY_D,false)
	var walk_distance=world.player.position.distance_to(start)
	check(walk_distance>1.2,"camera-relative walking moves body")
	check(absf(world.yaw)>.3,"camera automatically turns behind sideways movement")
	check(absf(world.player.position.z-start.z)<.2,"automatic camera orbit does not curve a held movement direction")
	var stopped_yaw=world.yaw
	await create_timer(.2).timeout
	check(absf(world.yaw-stopped_yaw)<.01,"camera stays stable when idle")
	start=world.player.position
	key(KEY_SHIFT,true)
	key(KEY_D,true)
	await create_timer(.5).timeout
	key(KEY_D,false)
	key(KEY_SHIFT,false)
	check(world.player.position.distance_to(start)>walk_distance*1.3,"sprint is faster than walking")
	await create_timer(.3).timeout
	var grounded_y=world.player.position.y
	key(KEY_SPACE,true)
	key(KEY_SPACE,false)
	await create_timer(.2).timeout
	check(world.player.position.y>grounded_y+.5 and not world.player.is_on_floor(),"space launches physical jump")
	await shot("third-person-jump")
	await create_timer(1).timeout
	check(world.player.is_on_floor(),"gravity lands on terrain")
	var yaw=world.yaw
	var click=InputEventMouseButton.new()
	click.button_index=MOUSE_BUTTON_RIGHT
	click.pressed=true
	world.input_event(click)
	var motion=InputEventMouseMotion.new()
	motion.relative=Vector2(70,-20)
	world.input_event(motion)
	click.pressed=false
	world.input_event(click)
	check(world.yaw!=yaw,"mouse orbit changes actual camera")
	world.yaw=0
	world.player.position=Vector3(-18,1,-3.3)
	await create_timer(.4).timeout
	key(KEY_W,true)
	await create_timer(1.4).timeout
	key(KEY_W,false)
	check(world.player.position.z>-6,"cottage collision blocks walking through walls")
	world.player.position=Vector3(-18,1,-4)
	await create_timer(.3).timeout
	key(KEY_E,true)
	key(KEY_E,false)
	check(game.model.profile.met_home,"E talks to family in 3D")
	world=game.world3d
	world.player.position=Vector3(18,1,-3)
	await create_timer(.3).timeout
	await shot("third-person-crab")
	key(KEY_E,true)
	key(KEY_E,false)
	check(game.page=="battle","3D encounter opens card battle")
	check(game.model.profile.has("world_position"),"3D position saved")
	game.retreat()
	game.page="map"
	game.render()
	await create_timer(.5).timeout
	check(game.near_location("encounter"),"retreat returns to the island beside the creature, with no penalty")
	world=game.world3d
	world.held[KEY_W]=true
	game._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(world.held.is_empty(),"focus loss stops movement")
	var saved=world.player.position
	game.save_world_position(saved)
	var restored=preload("res://model.gd").new()
	restored.save_path=game.model.save_path
	check(restored.load_profile() and Vector3(restored.profile.world_position[0],restored.profile.world_position[1],restored.profile.world_position[2]).distance_to(saved)<.01,"3D position survives save reload")
	var save_path=game.model.save_path
	game.queue_free()
	await create_timer(.3).timeout
	DirAccess.remove_absolute(save_path)
	print("Third-person checks: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
