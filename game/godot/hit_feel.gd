extends Node
const UIStyle=preload("res://skin.gd")
## Attack "feel" variations for playtesting. Variant 0 is the original lunge.
## In battle, F1 to F4 switch between them. Rules and outcomes never change, only presentation.
const NAMES=["Original","A  Snap","B  Heavy","C  Slash"]
const IMPACT=[.14,.17,.34,.24]       # seconds from the start of an attack to the hit landing
const SPACING=[.22,.38,.70,.48]      # seconds before the next queued effect may start
const CUES=["attack","hit_snap","hit_heavy","hit_slash"]
const CUE_LEAD=[0.0,0.0,0.0,.16]     # the slash cue opens with a swish before its hit
const GHOST_SIZE=[66,84,100,76]
var variant=0
var game
var label: Label
var shaking=false
var shake_from=0.0
var shake_until=0.0
var shake_amp=0.0

func set_variant(v: int):
	variant=clampi(v,0,NAMES.size()-1)
	if is_instance_valid(label):
		label.text=caption()
		label.modulate=Color(1,1,1,1)
		var tween=label.create_tween()
		tween.tween_property(label,"scale",Vector2(1.25,1.25),.08)
		tween.tween_property(label,"scale",Vector2.ONE,.16)

func caption() -> String:
	return "Attack feel: %s  (F1 to F4)   ·   Look: %s  (F5 time, F6 classic)" % [NAMES[variant],UIStyle.mode]

func _process(_delta):
	if not is_instance_valid(game): return
	if not is_instance_valid(label):
		label=Label.new()
		label.name="HitFeelLabel"
		label.mouse_filter=Control.MOUSE_FILTER_IGNORE
		label.z_index=70
		label.add_theme_font_size_override("font_size",13)
		label.add_theme_color_override("font_color",Color("ffe0a0"))
		label.add_theme_color_override("font_outline_color",Color("1c1410"))
		label.add_theme_constant_override("outline_size",4)
		label.text=caption()
		game.add_child(label)
	label.visible=game.page=="battle"
	label.text=caption()
	label.add_theme_color_override("font_color",UIStyle.P.stat_text)
	label.add_theme_color_override("font_outline_color",UIStyle.P.stat_outline)
	label.position=Vector2(14,game.size.y-24)
	if not shaking: return
	var now=Time.get_ticks_usec()/1000000.0
	if now>=shake_until or game.page!="battle":
		game.get_viewport().canvas_transform=Transform2D.IDENTITY
		shaking=false
	else:
		var fade=1.0-(now-shake_from)/(shake_until-shake_from)
		game.get_viewport().canvas_transform=Transform2D(0.0,Vector2(randf_range(-1,1),randf_range(-1,1))*shake_amp*fade)

func shake(amp: float,seconds: float):
	shake_from=Time.get_ticks_usec()/1000000.0
	shake_until=shake_from+seconds
	shake_amp=amp
	shaking=true

func local(point: Vector2) -> Vector2:
	return game.get_global_transform().affine_inverse()*point

func dim(face_of: Callable,alpha: float):
	var face=face_of.call()
	if is_instance_valid(face) and face.get_parent()!=game.creature_feedback: face.modulate.a=alpha

## A round portrait token with a gold rim, matching the oval creature tokens on the board.
func token(tex: Texture2D,side: float,label_name: String,layer: int) -> Panel:
	var disc=Panel.new()
	var mask=StyleBoxFlat.new()
	mask.bg_color=Color.WHITE
	mask.set_corner_radius_all(int(side/2))
	disc.add_theme_stylebox_override("panel",mask)
	disc.clip_children=CanvasItem.CLIP_CHILDREN_ONLY
	disc.name=label_name
	disc.size=Vector2(side,side)
	disc.pivot_offset=disc.size/2
	disc.mouse_filter=Control.MOUSE_FILTER_IGNORE
	disc.z_index=layer
	var art=TextureRect.new()
	art.texture=tex
	art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.size=disc.size
	art.mouse_filter=Control.MOUSE_FILTER_IGNORE
	art.material=UIStyle.art_material(true)
	disc.add_child(art)
	var rim=Panel.new()
	var edge=StyleBoxFlat.new()
	edge.bg_color=Color(0,0,0,0)
	edge.border_color=UIStyle.P.token_idle
	edge.set_border_width_all(3)
	edge.set_corner_radius_all(int(side/2))
	rim.add_theme_stylebox_override("panel",edge)
	rim.size=disc.size
	rim.mouse_filter=Control.MOUSE_FILTER_IGNORE
	disc.add_child(rim)
	disc.hide()
	game.add_child(disc)
	return disc

## The attacker's portrait travels to the target, lands the hit, and returns or fades.
func strike(tex: Texture2D,from: Vector2,to: Vector2,delay: float,source_anchor: Callable,target_anchor: Callable,source_face: Callable,target_face: Callable,dim_source: bool):
	if game.page!="battle": return
	var v=variant
	var ghost=token(tex,GHOST_SIZE[v],"AttackLunge",50)
	var tween=game.create_tween()
	game.track_battle_effect(ghost,tween)
	if delay>0: tween.tween_interval(delay)
	var path={"from":from,"to":to,"hit":to}
	var place=func(point: Vector2):
		ghost.position=local(point)-ghost.size/2
	tween.tween_callback(func():
		path.from=source_anchor.call() if source_anchor.is_valid() else from
		path.to=target_anchor.call() if target_anchor.is_valid() else to
		path.hit=path.to-(path.to-path.from).normalized()*[0.0,46.0,52.0,0.0][v]
		ghost.set_meta("path",path.duplicate())
		place.call(path.from)
		ghost.show()
		if dim_source: dim(source_face,.3))
	var restore=func():
		if dim_source: dim(source_face,1.0)
	if v==1:
		# Snap: a short pull back, a fast jab, a quick return.
		var back=func() -> Vector2:
			return path.from+(path.from-path.to).normalized()*18
		tween.tween_method(func(t: float): place.call(path.from.lerp(back.call(),t)),0.0,1.0,.07).set_ease(Tween.EASE_OUT)
		tween.tween_method(func(t: float): place.call(back.call().lerp(path.hit,t)),0.0,1.0,.10).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
		tween.tween_callback(func(): impact(v,path.to,target_face))
		tween.tween_method(func(t: float): place.call(path.hit.lerp(path.from,t)),0.0,1.0,.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_callback(restore)
		tween.tween_property(ghost,"modulate:a",0.0,.06)
	elif v==2:
		# Heavy: rear up and grow, slam down, hold the frame on impact, then settle back.
		var raised=func() -> Vector2:
			return path.from+Vector2(0,-26)
		tween.tween_method(func(t: float): place.call(path.from.lerp(raised.call(),t)),0.0,1.0,.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(ghost,"scale",Vector2(1.4,1.4),.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_method(func(t: float): place.call(raised.call().lerp(path.hit,t)),0.0,1.0,.12).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		tween.tween_callback(func():
			ghost.scale=Vector2(1.2,1.2)
			impact(v,path.to,target_face))
		tween.tween_interval(.1)
		tween.tween_method(func(t: float): place.call(path.hit.lerp(path.from,t)),0.0,1.0,.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(ghost,"scale",Vector2.ONE,.24)
		tween.tween_callback(restore)
		tween.tween_property(ghost,"modulate:a",0.0,.08)
	else:
		# Slash: sweep in on a curve with afterimages, cut through the target and fade past it.
		var curve=func(t: float) -> Vector2:
			var side=1.0 if path.to.x>=path.from.x else -1.0
			var control=(path.from+path.to)/2+(path.to-path.from).orthogonal().normalized()*110*side
			return path.from.lerp(control,t).lerp(control.lerp(path.to,t),t)
		var trail=[]
		for i in range(3):
			var echo=token(tex,GHOST_SIZE[v],"AttackTrail",49)
			echo.modulate=Color(1,1,1,.34-.1*i)
			game.battle_effects.append(echo)
			trail.append(echo)
		var sweep=func(t: float):
			place.call(curve.call(t))
			ghost.rotation=lerpf(-.6,.35,t)
			for i in range(trail.size()):
				trail[i].visible=t>.05
				trail[i].position=local(curve.call(maxf(0.0,t-.13*(i+1))))-ghost.size/2
		tween.tween_method(sweep,0.0,1.0,.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tween.tween_callback(func():
			for echo in trail: echo.queue_free()
			impact(v,path.to,target_face))
		tween.tween_method(func(t: float): place.call(path.to+(path.to-path.from).normalized()*46*t),0.0,1.0,.14).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(ghost,"modulate:a",0.0,.14)
		tween.tween_callback(restore)
	tween.tween_callback(ghost.queue_free)

func impact(v: int,point: Vector2,target_face: Callable):
	if game.page!="battle": return
	var face=target_face.call()
	var rect=face.get_global_rect() if is_instance_valid(face) else Rect2(point-Vector2(50,47),Vector2(100,94))
	if v==1:
		flash(rect,Color(1,1,1,.8),.12)
		shake(5,.14)
		recoil(face,Vector2(.84,.84),0.0,.2,Tween.TRANS_BACK)
	elif v==2:
		flash(rect,Color(1,.86,.62,.95),.3)
		shake(14,.34)
		ring(point)
		recoil(face,Vector2(.72,.72),0.0,.5,Tween.TRANS_ELASTIC)
	else:
		flash(rect,Color(.8,.95,1,.6),.16)
		shake(3,.1)
		slash(point)
		sparks(point)
		recoil(face,Vector2(.94,.94),.16,.3,Tween.TRANS_BACK)

func recoil(face,squash: Vector2,tilt: float,seconds: float,trans: int):
	if not is_instance_valid(face): return
	face.pivot_offset=face.size/2
	face.scale=squash
	face.rotation=tilt
	var tween=face.create_tween()
	tween.tween_property(face,"scale",Vector2.ONE,seconds).set_trans(trans).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(face,"rotation",0.0,seconds).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func transient(node: CanvasItem,seconds: float) -> Tween:
	node.name="HitEffect"
	node.z_index=55
	game.add_child(node)
	var tween=game.create_tween()
	game.track_battle_effect(node,tween)
	tween.tween_interval(seconds)
	tween.tween_callback(node.queue_free)
	return tween

func flash(rect: Rect2,color: Color,seconds: float):
	var overlay=Panel.new()
	var glow=StyleBoxFlat.new()
	glow.bg_color=color
	glow.set_corner_radius_all(int(minf(rect.size.x,rect.size.y)/2))
	overlay.add_theme_stylebox_override("panel",glow)
	overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE
	overlay.position=local(rect.position)
	overlay.size=rect.size
	transient(overlay,seconds)
	overlay.create_tween().tween_property(overlay,"modulate:a",0.0,seconds).set_ease(Tween.EASE_IN)

func ring(point: Vector2):
	var circle=Panel.new()
	var box=StyleBoxFlat.new()
	box.bg_color=Color(0,0,0,0)
	box.border_color=Color("ffd98a")
	box.set_border_width_all(5)
	box.set_corner_radius_all(40)
	circle.add_theme_stylebox_override("panel",box)
	circle.mouse_filter=Control.MOUSE_FILTER_IGNORE
	circle.size=Vector2(80,80)
	circle.pivot_offset=circle.size/2
	circle.position=local(point)-circle.size/2
	circle.scale=Vector2(.4,.4)
	transient(circle,.36)
	var tween=circle.create_tween()
	tween.tween_property(circle,"scale",Vector2(3.4,3.4),.36).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(circle,"modulate:a",0.0,.36).set_ease(Tween.EASE_IN)

func slash(point: Vector2):
	var cut=Line2D.new()
	var center=local(point)
	var reach=Vector2(78,-62)
	cut.width=11
	cut.default_color=Color("eaffff")
	cut.begin_cap_mode=Line2D.LINE_CAP_ROUND
	cut.end_cap_mode=Line2D.LINE_CAP_ROUND
	cut.points=PackedVector2Array([center-reach,center-reach])
	transient(cut,.3)
	var tween=cut.create_tween()
	tween.tween_method(func(t: float): cut.points=PackedVector2Array([center-reach,center-reach+reach*2*t]),0.0,1.0,.07)
	tween.tween_property(cut,"width",0.0,.22).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(cut,"modulate:a",0.0,.22)

func sparks(point: Vector2):
	var burst=CPUParticles2D.new()
	burst.position=local(point)
	burst.one_shot=true
	burst.explosiveness=1.0
	burst.amount=16
	burst.lifetime=.38
	burst.spread=180
	burst.initial_velocity_min=150
	burst.initial_velocity_max=300
	burst.gravity=Vector2(0,520)
	burst.scale_amount_min=3
	burst.scale_amount_max=6
	burst.color=Color("bff4ff")
	burst.emitting=true
	transient(burst,.6)

## Damage number that pops on the hit, styled per variant.
func number(text: String,point: Vector2,delay: float,anchor: Callable):
	if game.page!="battle": return
	var v=variant
	var value=Label.new()
	value.name="DamageFeedback"
	value.z_index=60
	value.text=text
	value.mouse_filter=Control.MOUSE_FILTER_IGNORE
	value.add_theme_font_size_override("font_size",[30,34,48,34][v])
	value.add_theme_color_override("font_color",[Color("ffe0a0"),Color("fff1c4"),Color("ffb27a"),Color("d8fbff")][v])
	value.add_theme_color_override("font_outline_color",Color("1c1410"))
	value.add_theme_constant_override("outline_size",6)
	value.hide()
	game.add_child(value)
	value.reset_size()
	value.pivot_offset=value.size/2
	var tween=game.create_tween()
	game.track_battle_effect(value,tween)
	if delay>0: tween.tween_interval(delay)
	tween.tween_callback(func():
		var at=anchor.call() if anchor.is_valid() else point
		value.position=local(at)-value.size/2-Vector2(0,14)
		value.show())
	if v==2:
		# lands big, then drops and settles
		value.scale=Vector2(2.2,2.2)
		tween.tween_property(value,"scale",Vector2.ONE,.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_interval(.3)
		tween.tween_property(value,"position:y",26.0,.3).as_relative().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(value,"modulate:a",0.0,.3).set_ease(Tween.EASE_IN)
	elif v==3:
		# flicks out along the cut
		value.scale=Vector2(1.5,1.5)
		value.rotation=-.3
		tween.tween_property(value,"scale",Vector2.ONE,.1)
		tween.parallel().tween_property(value,"rotation",0.0,.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(value,"position",Vector2(34,-40),.5).as_relative().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		tween.tween_property(value,"modulate:a",0.0,.2)
	else:
		value.scale=Vector2(1.7,1.7)
		tween.tween_property(value,"scale",Vector2.ONE,.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(value,"position:y",-42.0,.55).as_relative().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(value,"modulate:a",0.0,.2)
	tween.tween_callback(value.queue_free)
