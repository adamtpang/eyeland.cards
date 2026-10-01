extends SceneTree
var checks=0
var failed=0
func check(ok: bool,label: String):
	checks+=1
	if not ok: failed+=1; push_error(label)
func _initialize():
	var m=preload("res://model.gd").new()
	var deck=preload("res://collection.gd").practice_deck(m.cards,"fire")
	var b=preload("res://battle.gd").new(m.cards,deck,deck,30,30,m.world.classes[0],1)
	b.resolve_effects(0,[{"effect":"summon","card":"home-breeze-finch","amount":1},{"effect":"damageBoard","amount":4}],b.cards["home-spark"])
	b.clean()
	check(b.sides[0].board.is_empty(),"Fixture creates and destroys creature in one resolution")
	check(b.timeline.map(func(e): return e.kind)==["summon","spell_hit","death"],"Timeline retains intermediate summon, hit and death in order")
	check(b.timeline[0].minion.hp==2 and b.timeline[2].minion.hp==-2,"Event snapshots do not mutate with live minion")
	check(b.timeline[0].uid==b.timeline[2].uid,"Intermediate creature identity survives removal")
	b.resolve_effects(0,[{"effect":"discover"},{"effect":"summon","card":"home-breeze-finch","amount":1}],b.cards["air-windfall"])
	var count=b.timeline.size()
	check(not b.pending_choice.is_empty() and count==3,"Paused effects do not record future events early")
	b.choose_discover(0,0)
	check(b.timeline.size()==4 and b.timeline[-1].kind=="summon","Continuation appends at actual resolution time")
	for i in range(b.timeline.size()): check(b.timeline[i].sequence==i,"Monotonic event sequence")
	print("EVENT TIMELINE: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
