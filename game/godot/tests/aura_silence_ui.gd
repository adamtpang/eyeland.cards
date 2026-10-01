extends SceneTree
var checks=0
var failed=0
func check(ok: bool,label: String):
	checks+=1
	if not ok: failed+=1; push_error(label)
func _initialize(): call_deferred("run")
func run():
	root.size=Vector2i(1280,800)
	var game=preload("res://main.tscn").instantiate()
	game.model.save_path="user://aura-silence-ui-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.model.new_profile("warrior","air"); game.page="deck"
	game.start_practice("air","",false,0); game.confirm_opening()
	var b=game.battle
	b.summon(1,"water-shellback-tortoise")
	b.summon(1,"air-flock-captain")
	b.summon(1,"water-reef-conductor")
	var turtle=b.sides[1].board[0]
	game.render(); await process_frame; await process_frame
	var face=game.target_widgets[turtle.uid]
	check(face.current_attack==4 and face.current_health==5,"Token shows positional attack and health aura bonuses")
	check("+2 Attack / +1 Health" in face.tooltip_text,"Hover explains active aura contribution")
	check(face.card.taunt and face.shield_active,"Printed Taunt and Shield appear before Silence")
	b.silence_minion(1,turtle.uid); game.render()
	face=game.target_widgets[turtle.uid]
	check(face.status=="SILENCED" and not face.card.taunt and not face.shield_active,"Silence removes Taunt frame and Shield while marking status")
	check(face.current_attack==4 and face.current_health==5 and "Active auras:" in face.tooltip_text,"External aura persists visibly through recipient Silence")
	var tooltip=face._make_custom_tooltip(face.tooltip_text)
	check("Silenced:" in tooltip.get_child(2).text and not "Divine Shield" in tooltip.get_child(2).text,"Actual hover details do not advertise removed abilities")
	tooltip.free()
	b.sides[0].hand=["water-sea-glass"]; b.sides[0].mana=3
	game.play_card(0)
	var deadline=Time.get_ticks_msec()+5000
	while game.feedback_busy() and Time.get_ticks_msec()<deadline:
		await create_timer(.05).timeout
	face=game.target_widgets[turtle.uid]
	check(face.current_attack==2 and face.current_health==4 and not "Active auras:" in face.tooltip_text,"Playing Silence spell removes source auras from rendered recipient")
	b.sides[0].weapon={"attack":3,"durability":2}; b.sides[0].frozen=true
	game.render(); await process_frame; await process_frame
	var hero=game.duel_board.friendly_faces[-1]
	check(hero.disabled and hero.modulate==Color("8ecde8") and "Frozen:" in hero.tooltip_text,"Frozen armed hero has tint, explanation and disabled attack")
	if DisplayServer.get_name()!="headless":
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../evidence/silence-hero-freeze.png"))
	game.queue_free(); await process_frame; await create_timer(.1).timeout
	print("AURA SILENCE UI: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
