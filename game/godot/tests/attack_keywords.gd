extends SceneTree
const Model=preload("res://model.gd")
const Battle=preload("res://battle.gd")
const Collection=preload("res://collection.gd")
const Main=preload("res://main.tscn")
var count=0
var failed=0
func check(ok,label):
	count+=1
	if not ok: failed+=1; printerr("FAIL: "+label)
func _initialize(): call_deferred("run")
func run():
	var m=Model.new()
	var deck=Collection.practice_deck(m.cards,"air")
	var b=Battle.new(m.cards,deck,deck,30,30,m.world.classes[0],1)
	b.summon(0,"fire-ember-ram")
	var rush=b.sides[0].board[0]
	check(rush.ready and b.attack_targets(0,rush.uid).is_empty(),"Rush cannot attack hero on empty enemy board")
	check(not b.attack(0,rush.uid,-1) and rush.ready,"illegal Rush face attack preserves swing")
	b.summon(1,"home-resin-crab")
	check(b.attack_targets(0,rush.uid).has(b.sides[1].board[0].uid),"Rush immediately attacks minions")
	check(b.attack(0,rush.uid,b.sides[1].board[0].uid) and not rush.ready,"Rush attack spends swing")
	b.start_turn(0)
	check(b.attack_targets(0,rush.uid).has(-1),"Rush can attack hero next turn")
	b.summon(0,"air-skyfin-ray")
	var charge=b.sides[0].board[1]
	check(b.attack(0,charge.uid,-1),"Charge attacks hero immediately")
	b.summon(0,"home-cloudling")
	check(b.attack_targets(0,b.sides[0].board[2].uid).is_empty(),"ordinary minion retains sickness")
	b.summon(1,"home-shore-guard")
	check(not b.attack_targets(0,rush.uid).has(-1),"Taunt still blocks Rush after first turn")
	var game=Main.instantiate()
	game.model.save_path="user://keywords-ui-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.model.new_profile("warrior","air"); game.page="deck"
	game.start_practice("air","",false,0)
	game.battle.mulligan([])
	game.battle.summon(0,"fire-ember-ram")
	game.battle.summon(1,"water-shellback-tortoise")
	game.selection="attack"; game.selected=game.battle.sides[0].board[0].uid; game.render()
	await process_frame; await process_frame
	var enemy=game.battle.sides[1].board[0]
	check(not game.target_allowed(-1) and game.target_allowed(enemy.uid),"UI uses authoritative Rush targets")
	check(game.target_widgets[enemy.uid].shield_active,"shield indicator follows live state")
	check(not game.duel_board.accepts_enemy({"kind":"attack","uid":game.selected},-1),"drag cannot bypass Rush restrictions")
	if DisplayServer.get_name()!="headless":
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../evidence/rush-shield.png"))
	game.target_enemy(enemy.uid)
	check(not game.battle.sides[1].board[0].divine_shield and game.battle.sides[1].board[0].hp==4,"Rush attack breaks shield through UI")
	game.battle.summon(0,"water-shellback-tortoise")
	var frozen=game.battle.sides[0].board[-1]
	frozen.frozen=true; frozen.ready=true; frozen.summoning_sick=false
	game.render()
	await process_frame; await process_frame
	var frozen_face=game.duel_board.friendly_faces[frozen.uid]
	check(frozen_face.disabled and frozen_face.status=="FROZEN" and "Frozen:" in frozen_face.tooltip_text,"Frozen Taunt token shows status and is disabled")
	check(not game.duel_board.accepts_enemy({"kind":"attack","uid":frozen.uid},enemy.uid),"Frozen drag cannot attack")
	if DisplayServer.get_name()!="headless":
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../evidence/frozen-token.png"))
	game.queue_free(); await process_frame
	print("ATTACK KEYWORDS: %d / %d passed" % [count-failed,count])
	quit(1 if failed else 0)
