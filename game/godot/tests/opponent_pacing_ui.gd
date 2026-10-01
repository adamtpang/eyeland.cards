extends SceneTree
var checks=0
var failed=0
func check(ok: bool,label: String):
	checks+=1
	if not ok: failed+=1; push_error(label)
func _initialize(): call_deferred("run")
func run():
	var game=preload("res://main.tscn").instantiate()
	game.model.save_path="user://opponent-pacing-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.model.new_profile("warrior","air"); game.page="deck"
	game.start_practice("air","",false,0); game.confirm_opening()
	await create_timer(.5).timeout
	var b=game.battle
	b.active=1; b.sides[0].hp=2; b.sides[1].weapon={"attack":3,"durability":2}
	b.sides[1].hand=[]; b.sides[1].mana=0
	var hold=game.create_tween()
	hold.tween_interval(1.0)
	game.creature_feedback.animations.append(hold)
	check(game.feedback_busy(),"Shared feedback guard recognizes running creature sequence")
	game.run_opponent_turn()
	await create_timer(.7).timeout
	check(b.sides[0].hp==2 and b.outcome==-1,"Opponent waits beyond old fixed action delay")
	await create_timer(.6).timeout
	check(b.outcome==1,"Opponent resumes and completes legal lethal action after feedback")
	await create_timer(1.0).timeout
	check(game.page=="result" and not game.feedback_busy(),"Final feedback finishes before results without deadlock")
	game.queue_free(); await process_frame; await create_timer(.2).timeout
	print("OPPONENT PACING UI: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
