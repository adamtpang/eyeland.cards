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
		await create_timer(2.3).timeout
		shot(folder,"battle-%s.png" % look)
		check(game.stage_active()==(look!="classic"),"%s: battle is staged on the island (classic keeps its table)" % look)
		if game.stage_active():
			var stage=game.battle_stage
			check(stage.get_node("StageCamera").current and stage.rival!=null and stage.night==(look=="night"),"%s: stage has its camera, an enemy and the right light" % look)
			stage.stage_event("hero_attack")
			await process_frame
			check(stage.animator.current_animation!="Idle","%s: the hero swings when you attack" % look)
		check(game.body.size.y<=game.size.y-24,"%s: battle fits the window" % look)
		check(is_instance_valid(game.duel_board) and game.duel_board.hand_faces.size()>0,"%s: hand is drawn" % look)
		var face=game.duel_board.hand_faces[0]
		check(face.material!=null and is_equal_approx(face.material.get_shader_parameter("style"),float(UIStyle.P.art_style)),"%s: card art uses the look's art style" % look)
	# attacks in the card battle reach the stage characters
	game.choose_look("day"); game.render(); await create_timer(.3).timeout
	var striker=b.sides[0].board[0]
	striker.ready=true; striker.summoning_sick=false
	b.attack(0,striker.uid,-1); game.after_action()
	await create_timer(.6).timeout
	check(game.battle_stage.last_stage_event=="enemy_hit","A hit on the enemy hero makes the stage enemy flinch")
	shot(folder,"battle-day-attack.png")
	# the island: a full-window 3D view behind the HUD
	game.battle.outcome=1; game.after_action(); await create_timer(1.2).timeout
	check(game.page=="result" and game.stage_active() and game.battle_stage.last_stage_event=="lose","The result plays out on the stage")
	shot(folder,"battle-day-result.png")
	game.page="map"
	game.choose_look("day"); game.render()
	await create_timer(1.2).timeout
	var world=game.world3d
	shot(folder,"island-day.png")
	check(is_instance_valid(world) and world.player.is_on_floor(),"Island loads and the hero stands on it")
	check(not game.stage_active() and not is_instance_valid(game.battle_host),"The battle stage is removed after the battle")
	check(game.world_host.get_index()==0 and game.world_host.size.is_equal_approx(game.size),"The world fills the window behind the HUD")
	check(world.animator!=null and world.animator.current_animation=="Idle","Animated hero model is idling")
	check(is_zero_approx(world.mix) and not world.night,"Island starts in daylight")
	check(world.grass_blades>500,"Meadow has swaying grass")
	check(world.crab_claws.size()==2 and world.crab_legs.size()==6,"Resin Crab has claws and legs")
	check(world.pet_animator!=null and world.pet_animator.is_playing(),"Companion is an animated creature model")
	check(world.audio.waves.playing and world.audio.counts.get("land",0)==0,"Sea ambience is playing, with no thud on arrival")
	# walking makes footsteps
	var walk=InputEventKey.new(); walk.keycode=KEY_D; walk.pressed=true
	root.push_input(walk)
	await create_timer(1.3).timeout
	walk=InputEventKey.new(); walk.keycode=KEY_D; walk.pressed=false
	root.push_input(walk)
	check(world.audio.counts.get("step",0)>=2,"Walking plays footsteps")
	world.player.position=Vector3(0,1,4.5)
	await create_timer(.9).timeout
	shot(folder,"island-day-camp.png")
	check(game.world_plate.visible and game.world_action.text.begins_with("Rest"),"Nearby action plate appears")
	# E opens a visible dialogue box, E again closes it, and walking away closes it too
	for press in [true,false,true]:
		var talk=InputEventKey.new(); talk.keycode=KEY_E; talk.pressed=true
		root.push_input(talk)
		await process_frame; await process_frame
		check((game.body.find_child("Dialogue",true,false)!=null)==press,"E %s the dialogue box" % ("opens" if press else "closes"))
	shot(folder,"island-dialogue.png")
	world.player.position=Vector3(0,1,14)
	await create_timer(.4).timeout
	check(game.spoken.is_empty() and game.body.find_child("Dialogue",true,false)==null,"Walking away closes the dialogue box")
	world.player.position=Vector3(0,1,4.5)
	await create_timer(.4).timeout
	# day to night blends on the same island instead of rebuilding it
	game.choose_look("night"); game.render()
	await create_timer(.7).timeout
	check(game.world3d==world,"Changing the look keeps the same island")
	check(world.mix>.05 and world.mix<.95,"Day blends into night over time")
	shot(folder,"island-dusk-camp.png")
	await create_timer(1.6).timeout
	check(is_equal_approx(world.mix,1.0) and world.night,"The blend finishes at night")
	check(world.audio.crickets.volume_db>-30,"Crickets fade in at night")
	shot(folder,"island-night-camp.png")
	world.player.position=Vector3(18,1,-2.2)
	world.yaw=PI/2
	await create_timer(1.0).timeout
	shot(folder,"island-night-crab.png")
	game.choose_look("day"); game.render()
	await create_timer(2.2).timeout
	shot(folder,"island-day-crab.png")
	# each element's companion model loads and animates
	for kind in ["fire","water","earth","air"]:
		world.element=kind
		var old_pet=world.companion
		world.pet_animator=null
		world.companion=world.make_companion()
		world.add_child(world.companion)
		world.companion.position=old_pet.position
		old_pet.queue_free()
		await create_timer(.5).timeout
		check(world.pet_animator!=null and world.pet_animator.is_playing(),"%s companion model animates" % kind)
		shot(folder,"companion-%s.png" % kind)
	check(is_zero_approx(world.mix),"Night blends back to day")
	# settings: reachable from the island, changes class, returns to the island
	game.open_settings(); await process_frame
	check(game.page=="settings" and not is_instance_valid(game.world_host),"Settings opens from the island")
	shot(folder,"settings.png")
	game.model.profile.job="wizard"; game.page=game.settings_back; game.render()
	await create_timer(1.0).timeout
	world=game.world3d
	check(game.page=="map" and world.job=="wizard","Changing class in Settings changes the island hero")
	check(ProjectSettings.get_setting("display/window/size/viewport_width")*9==ProjectSettings.get_setting("display/window/size/viewport_height")*16,"The game window is 16:9 landscape")
	var mute_before=game.battle_audio.muted
	game.battle_audio.toggle(); game.render(); await process_frame
	check(world.audio.muted!=mute_before and world.audio.waves.volume_db<-60,"Sound button silences the island")
	game.battle_audio.toggle(); game.render(); await process_frame
	# the island clock: time passes, the HUD shows it, and sunset changes the look by itself
	check(game.world_clock.text.begins_with("Day 09:"),"HUD shows the island time")
	game.game_hour=17.9
	game.clock_speed=1.0
	await create_timer(.5).timeout
	game.clock_speed=0.0
	check(UIStyle.mode=="night" and game.world3d==world and world.night,"Sunset on the clock brings the night look")
	check(world.mix>0.0 and world.mix<.5,"A clock sunset blends slowly")
	check(game.world_clock.text.begins_with("Night 18:"),"HUD shows night time")
	check(is_equal_approx(game.model.profile.time,game.game_hour),"The time of day is kept in the save")
	# the tunes: built on request here, then both loops play and follow the look
	world.audio.build_music()
	await process_frame; await process_frame
	check(world.audio.day_music!=null and world.audio.day_music.playing and world.audio.night_music.playing,"Day and night tunes are playing")
	world.audio.day_music.stream.save_to_wav(folder.path_join("tune-day.wav"))
	world.audio.night_music.stream.save_to_wav(folder.path_join("tune-night.wav"))
	check(world.audio.day_music.stream.get_length()>15 and world.audio.night_music.stream.get_length()>25,"Tunes are full-length loops")
	game.choose_look("day"); game.render()
	await create_timer(2.2).timeout
	check(world.audio.day_music.volume_db>-30 and world.audio.night_music.volume_db<-70,"By day only the day tune is heard")
	game.page="deck"; game.render(); await create_timer(.2).timeout
	check(not is_instance_valid(game.world_host),"World view is removed when leaving the island")
	game.choose_look("day"); game.render(); await process_frame
	for step in [[KEY_F5,"night"],[KEY_F5,"day"],[KEY_F6,"classic"],[KEY_F6,"day"]]:
		var key=InputEventKey.new(); key.keycode=step[0]; key.pressed=true
		Input.parse_input_event(key)
		await process_frame; await process_frame
		check(UIStyle.mode==step[1],"%s switches to %s" % ["F5" if step[0]==KEY_F5 else "F6",step[1]])
	game.queue_free(); await process_frame; await create_timer(.2).timeout
	UIStyle.set_mode("day")
	print("LOOKS: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
