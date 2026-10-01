extends SceneTree
var checks=0
var failed=0
func check(ok: bool,label: String):
	checks+=1
	if not ok: failed+=1; push_error(label)
func _initialize(): call_deferred("run")
func run():
	var m=preload("res://model.gd").new()
	var deck=preload("res://collection.gd").practice_deck(m.cards,"earth")
	var b=preload("res://battle.gd").new(m.cards,deck,deck,30,30,m.world.classes[0],1)
	var reveal=preload("res://secret_reveal.gd").new()
	root.add_child(reveal)
	b.revealed_secrets=[{"owner":0,"id":"earth-pebble-ward"},{"owner":1,"id":"air-fresh-breeze"}]
	reveal.observe(b)
	check(reveal.get_child(0).card.id=="earth-pebble-ward" and reveal.queued.size()==1,"First reveal displays while second waits")
	await create_timer(2.05).timeout
	check(reveal.get_child_count()==1 and reveal.get_child(0).card.id=="air-fresh-breeze","Second reveal follows first without overlap")
	var next=preload("res://battle.gd").new(m.cards,deck,deck,30,30,m.world.classes[0],2)
	reveal.observe(next)
	check(reveal.get_child_count()==0 and not reveal.showing and reveal.queued.is_empty(),"New match clears prior reveal immediately")
	next.revealed_secrets=[{"owner":0,"id":"earth-pebble-ward"}]
	reveal.observe(next)
	check(reveal.get_child_count()==1,"New match can reveal its own card")
	reveal.reset()
	await create_timer(2.1).timeout
	check(reveal.get_child_count()==0 and not reveal.showing,"Canceled animation cannot resurrect queued reveals")
	reveal.queue_free(); await process_frame
	print("SECRET REVEAL QUEUE: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
