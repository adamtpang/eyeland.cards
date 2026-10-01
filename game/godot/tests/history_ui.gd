extends SceneTree
var checks=0
var failed=0
func check(ok: bool,label: String):
	checks+=1
	if not ok: failed+=1; push_error(label)
func texts(node: Node) -> Array:
	var result=[]
	if node is Label: result.append(node.text)
	for child in node.get_children(): result.append_array(texts(child))
	return result
func _initialize(): call_deferred("run")
func run():
	root.size=Vector2i(1280,800)
	var game=preload("res://main.tscn").instantiate()
	game.model.save_path="user://history-ui-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.model.new_profile("warrior","air"); game.page="deck"
	game.start_practice("air","",false,0); game.confirm_opening()
	var b=game.battle
	b.active=1; b.sides[1].mana=3; b.sides[1].hand=["air-fresh-breeze"]
	b.play(1,0)
	game.show_battle_history()
	var lines=texts(game.inspection)
	check(lines.has(b.enemy_name+" plays a Secret.") and not "Fresh Breeze" in " ".join(lines),"History hides unrevealed Secret identity")
	check(lines[1]==b.log[-1],"Newest action is first")
	await process_frame; await process_frame
	if DisplayServer.get_name()!="headless":
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../evidence/history.png"))
	var escape=InputEventKey.new(); escape.keycode=KEY_ESCAPE; escape.pressed=true; root.push_input(escape)
	check(game.inspection==null,"Escape dismisses history")
	b.active=0; b.sides[0].mana=1; b.sides[0].hand=["home-spark"]; b.play(0,0)
	game.show_battle_history()
	check("Secret revealed: Fresh Breeze." in texts(game.inspection),"Revealed Secret appears in history")
	b.summon(0,"home-breeze-finch"); b.summon(1,"water-shellback-tortoise")
	var attacker=b.sides[0].board[0]; var target=b.sides[1].board[0]
	attacker.ready=true; attacker.summoning_sick=false
	b.attack(0,attacker.uid,target.uid)
	game.show_battle_history()
	check(texts(game.inspection).has("Breeze Finch attacks Shellback Tortoise for 0 damage; takes 2 in return."),"History names target and records Shield absorption and retaliation")
	b.sides[0].mana=1; b.sides[0].hand=["air-gust-bolt"]
	b.play(0,0,target.uid); game.show_battle_history()
	check(texts(game.inspection).has("You play Gust Bolt on Shellback Tortoise."),"Targeted spell history names affected creature")
	game.queue_free(); await process_frame; await create_timer(.1).timeout
	print("HISTORY UI: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
