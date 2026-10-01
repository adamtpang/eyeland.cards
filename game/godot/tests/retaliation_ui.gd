extends SceneTree
var checks=0
var failed=0
func check(ok: bool,label: String):
	checks+=1
	if not ok: failed+=1; push_error(label)
func _initialize(): call_deferred("run")
func run():
	root.size=Vector2i(1280,800)
	for owner in [0,1]:
		for shield in [false,true]:
			var game=preload("res://main.tscn").instantiate()
			game.model.save_path="user://retaliation-%d.json" % Time.get_ticks_usec()
			root.add_child(game)
			game.model.new_profile("warrior","air"); game.page="deck"
			game.start_practice("air","",false,0); game.confirm_opening()
			var b=game.battle
			b.summon(owner,"home-breeze-finch"); b.summon(1-owner,"home-breeze-finch")
			var a=b.sides[owner].board[0]; var d=b.sides[1-owner].board[0]
			a.ready=true; a.summoning_sick=false; a.divine_shield=shield
			b.active=owner; game.render(); await process_frame; await process_frame
			b.attack(owner,a.uid,d.uid); game.after_action()
			var labels=[]
			for node in game.get_children():
				if node is Label and node.text=="−2": labels.append(node)
			var expected=1+(0 if shield else 1)
			check(labels.size()==expected,"Retaliation feedback respects owner and Shield")
			check(b.combat_events[-1].retaliation==(0 if shield else 2),"Event records actual retaliation rather than printed attack")
			game.queue_free(); await process_frame; await create_timer(.1).timeout
	print("RETALIATION UI: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
