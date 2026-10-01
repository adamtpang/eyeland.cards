extends Control
const REVEAL_SECONDS=1.93
var observed_battle
var cursor=0
var queued: Array=[]
var showing=false
var generation=0
var animation: Tween

func _ready():
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	z_index=90

func observe(battle):
	if observed_battle!=battle:
		reset(battle)
	if battle==null: return
	while cursor<battle.revealed_secrets.size():
		var event=battle.revealed_secrets[cursor]
		queued.append(battle.cards[event.id].duplicate(true))
		cursor+=1
	if not showing: show_next()

func remaining_seconds() -> float:
	var remaining=queued.size()*REVEAL_SECONDS
	if showing and animation!=null and animation.is_valid():
		remaining+=maxf(0.0,REVEAL_SECONDS-animation.get_total_elapsed_time())
	return remaining

func enqueue_event(battle,event: Dictionary):
	if observed_battle!=battle: reset(battle)
	queued.append(battle.cards[event.id].duplicate(true))
	if not showing: show_next()

func reset(battle=null):
	if animation!=null: animation.kill(); animation=null
	observed_battle=battle; cursor=0; queued.clear(); showing=false; generation+=1
	for child in get_children():
		remove_child(child)
		child.queue_free()

func show_next():
	if queued.is_empty(): showing=false; return
	showing=true
	var token=generation
	var face=preload("res://card_face.gd").new()
	face.name="RevealedSecret"
	face.card=queued.pop_front()
	face.mouse_filter=Control.MOUSE_FILTER_IGNORE
	face.focus_mode=Control.FOCUS_NONE
	face.position=Vector2(24,190)
	face.size=Vector2(166,228)
	face.modulate.a=0
	add_child(face)
	var tween=create_tween()
	animation=tween
	tween.tween_property(face,"modulate:a",1.0,.18)
	tween.parallel().tween_property(face,"position:x",44.0,.18)
	tween.tween_interval(1.5)
	tween.tween_property(face,"modulate:a",0.0,.25)
	tween.tween_callback(func():
		remove_child(face)
		face.queue_free()
		if token==generation: show_next())
