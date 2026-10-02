extends SceneTree
## Onboarding: intro, goals with a world marker, three coached lessons, the Crab, and the
## closing goals. Saves screenshots as evidence.
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

func stand_at(game,id: String):
	var at=game.world3d.landmarks[id]
	game.world3d.player.position=Vector3(at.x+1.5,game.world3d.ground_height(at.x+1.5,at.z+1.5)+.2,at.z+1.5)
	await create_timer(.5).timeout

func run():
	var folder=ProjectSettings.globalize_path("res://").path_join("../evidence/onboarding-2026-10-01")
	DirAccess.make_dir_recursive_absolute(folder)
	var game=preload("res://main.tscn").instantiate()
	game.model.save_path="user://onboarding-%d.json" % Time.get_ticks_usec()
	game.show_intro=true
	root.add_child(game)
	await process_frame
	check(game.page=="start","A new player starts on the class and companion screen")
	game.job_index=2; game.element_index=0
	game.begin()
	await create_timer(.3).timeout
	check(game.page=="intro" and game.quest()==0,"Beginning shows the story intro")
	shot(folder,"1-intro.png")
	game.page="map"; game.render()
	await create_timer(1.2).timeout
	var world=game.world3d
	check(game.body.find_child("Goal",true,false)!=null,"The island shows the current goal")
	check(world.goal_id=="home" and world.goal_marker.visible,"A marker floats over the goal")
	shot(folder,"2-first-goal.png")
	await stand_at(game,"friend")
	game.world_interact("friend"); await process_frame
	check(game.note.begins_with("Mira: Your family") and game.body.find_child("LessonButton",true,false)==null,"Mira sends you home first")
	await stand_at(game,"home")
	game.world_interact("home"); await process_frame
	check(game.quest()==1 and game.world3d.goal_id=="friend","Talking to family completes the goal and points at Mira")
	shot(folder,"3-goal-complete.png")
	await stand_at(game,"friend")
	game.world_interact("friend"); await process_frame
	var offer=game.body.find_child("LessonButton",true,false)
	check(offer!=null and offer.text=="Start lesson 1: Creatures","Mira offers the first lesson")
	shot(folder,"4-mira.png")
	for n in [1,2,3]:
		game.start_lesson(n)
		await create_timer(2.2 if n==1 else .6).timeout
		var b=game.battle
		check(game.page=="battle" and game.lesson==n and b.sides[1].hp==game.LESSONS[n-1].hp,"Lesson %d starts against Mira" % n)
		check(b.sides[0].hand.size()==3 and b.active==0 and not b.mulligan_pending,"Lesson %d deals a fixed opening hand, player first" % n)
		check(game.duel_board.find_child("Coach",true,false)!=null and not game.coach_text().is_empty(),"Lesson %d shows a coach hint" % n)
		check(game.duel_board.find_child("Coach",true,false).size.y<130,"Lesson %d coach plate stays compact" % n)
		if n==1:
			check(game.coach_text().begins_with("Drag Breeze Finch"),"The first hint is to play a creature")
			shot(folder,"5-lesson-1.png")
			b.play(0,0); game.after_action(); await process_frame
			check(game.coach_text().contains("End turn"),"After playing, the hint is to end the turn")
			game.end_turn()
			await create_timer(4.0).timeout
			check(b.active==0 and game.coach_text().begins_with("Your creature is ready"),"Next turn, the hint is to attack")
			shot(folder,"6-lesson-1-attack.png")
		if n==2:
			b.end_turn(0); b.ai_step(1)
			while b.active==1 and b.outcome==-1 and b.ai_step(1): pass
			if b.active==1: b.end_turn(1)
			game.render(); await process_frame
			check(game.coach_text().begins_with("Drag Spark onto an enemy creature"),"Lesson 2 teaches the spell once Mira has a creature")
			shot(folder,"7-lesson-2.png")
		if n==3:
			b.sides[0].mana=3; b.sides[0].max_mana=3
			check(game.coach_text().begins_with("Click your class power"),"Lesson 3 teaches the class power")
		var before=game.clock_left
		await create_timer(.3).timeout
		check(is_equal_approx(game.clock_left,before),"Lesson %d has no turn timer" % n)
		b.damage_hero(1,99); b.check_outcome(); game.after_action()
		await create_timer(1.6).timeout
		check(game.page=="result" and game.body.find_child("LessonResult",true,false)!=null,"Lesson %d ends on its own result screen" % n)
		check(game.quest()==n+1,"Winning lesson %d moves the goal on" % n)
		if n==3: shot(folder,"8-lessons-done.png")
	game.leave_lesson()
	await create_timer(1.2).timeout
	check(game.page=="map" and game.world3d.goal_id=="encounter" and not game.practice_mode,"After the lessons the goal is the Resin Crab")
	await stand_at(game,"encounter")
	game.world_interact("encounter"); await create_timer(.5).timeout
	check(game.page=="battle" and game.lesson==0 and game.battle.sides[0].hp==10 and game.battle.sides[1].hp==5,"The Crab fight is small: ten health against five")
	game.battle.damage_hero(1,99); game.battle.check_outcome(); game.after_action()
	await create_timer(1.6).timeout
	check(game.model.profile.won and game.quest()==5,"Beating the Crab moves the goal to adding its card")
	game.page="map"; game.render()
	await create_timer(1.2).timeout
	check(game.body.find_child("Goal",true,false)!=null and (not is_instance_valid(game.world3d.goal_marker) or not game.world3d.goal_marker.visible),"A goal with no place shows no marker")
	# the goal survives a reload
	var path=game.model.save_path
	game.queue_free(); await process_frame; await create_timer(.2).timeout
	var again=preload("res://main.tscn").instantiate()
	again.model.save_path=path
	root.add_child(again)
	await process_frame
	check(again.quest()==5 and again.model.error.is_empty(),"Goal progress is kept in the save")
	again.queue_free(); await process_frame; await create_timer(.2).timeout
	print("ONBOARDING: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
