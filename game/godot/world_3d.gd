extends Node3D
## Actual 3D terrain, CharacterBody3D motion, gravity and collision-aware camera.
signal interact_requested(id: String)
signal nearby_changed(id: String)
signal position_saved(at: Vector3)
var player: CharacterBody3D
var avatar: Node3D
var pivot: Node3D
var arm: SpringArm3D
var camera: Camera3D
var legs: Array=[]
var arms: Array=[]
var companion: Node3D
var held={}
var yaw=0.0
var movement_yaw=0.0
var previous_axis=Vector2.ZERO
var manual_camera_grace=0.0
var pitch=-.32
var jump_queued=false
var orbiting=false
var step=0.0
var save_clock=0.0
var current_landmark=""
var last_safe=Vector3(-18,2,0)
var spawn_position=Vector3(-18,2,0)
var element="fire"
var restored_garden=false
const UIStyle=preload("res://skin.gd")
var job="warrior"
var night=false
var ink: StandardMaterial3D
var materials={}
var animator: AnimationPlayer
var clouds: Array=[]
var flame: Node3D
var creature: Node3D
var clock=0.0
var mix=0.0  # 0 is day, 1 is night
var env: Environment
var sun: DirectionalLight3D
var sky_material: ShaderMaterial
var water_material: ShaderMaterial
var cloud_tint: StandardMaterial3D
var glows: Array=[]
var lamps: Array=[]
var blend: Tween
var audio
var muted=false
var path_points: Array=[]
var grass_blades=0
var pet_wings: Array=[]
var crab_claws: Array=[]
var crab_legs: Array=[]
var stride=0.0
# Battle stage: the same island used as the live backdrop of a card battle. The hero and
# companion face the enemy, nobody walks, and a fixed camera frames them from behind.
var stage=false
var stage_enemy="crab"   # "crab" for the island encounter, "keeper" for practice
var stage_center=Vector3.ZERO
var hero_home=Vector3.ZERO
var rival: Node3D
var rival_home=Vector3.ZERO
var rival_animator: AnimationPlayer
var creature_facing=-PI/2
var goal_marker: Node3D
var stick=Vector2.ZERO  # on-screen movement stick, each axis -1 to 1
var goal_at=Vector3.ZERO
var goal_id=""
var last_stage_event=""
var pet_animator: AnimationPlayer
var pet_ink: StandardMaterial3D
var pet_idle=""
var pet_move=""
const PET_SCALE=.28
var airborne=false
var landmarks={"home":Vector3(-18,0,-6),"friend":Vector3(-6,0,-12),"crop":Vector3(6,0,-6),"encounter":Vector3(18,0,-6),"camp":Vector3(0,0,6),"dock":Vector3(18,0,6)}
const WALK=4.2
const RUN=7.4
const JUMP=7.1
const GRAVITY=20.0

func ground_height(x: float,z: float) -> float:
	var edge=sqrt(pow(x/35.0,2)+pow(z/28.0,2))
	if edge>1.04: return -3.5
	var hill=2.8*exp(-((x+12)*(x+12)+(z+17)*(z+17))/75.0)
	return .5+hill+.18*sin(x*.18)*cos(z*.2)-maxf(0,edge-.86)*15

## Shared toon material: flat banded light, no highlights, optional ink outline.
## `glow` is the emission strength by day (x) and at night (y); it follows the look blend.
func material(color: Color,outline: bool=true,glow: Vector2=Vector2.ZERO,emit=null) -> StandardMaterial3D:
	var key=[color,outline,glow,emit]
	if materials.has(key): return materials[key]
	var m=StandardMaterial3D.new()
	m.albedo_color=color
	m.roughness=1.0
	m.diffuse_mode=BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode=BaseMaterial3D.SPECULAR_DISABLED
	if glow!=Vector2.ZERO:
		m.emission_enabled=true
		m.emission=color if emit==null else emit
		m.emission_energy_multiplier=lerpf(glow.x,glow.y,mix)
		glows.append([m,glow])
	if outline: m.next_pass=ink
	materials[key]=m
	return m

func mesh_at(parent: Node3D, mesh: Mesh, at: Vector3, color: Color, collision=false, outline: bool=true, glow: Vector2=Vector2.ZERO, emit=null) -> MeshInstance3D:
	var instance=MeshInstance3D.new()
	instance.mesh=mesh
	instance.material_override=material(color,outline,glow,emit)
	instance.position=at
	parent.add_child(instance)
	if collision: instance.create_trimesh_collision()
	return instance

func box(parent: Node3D,at: Vector3,dimensions: Vector3,color: Color,collision=false,glow: Vector2=Vector2.ZERO,emit=null):
	var mesh=BoxMesh.new()
	mesh.size=dimensions
	return mesh_at(parent,mesh,at,color,collision,true,glow,emit)

func sphere(parent: Node3D,at: Vector3,radius: float,color: Color,outline: bool=true,glow: Vector2=Vector2.ZERO):
	var mesh=SphereMesh.new()
	mesh.radius=radius
	mesh.height=radius*2
	mesh.radial_segments=16
	mesh.rings=8
	return mesh_at(parent,mesh,at,color,false,outline,glow)

func cylinder(parent: Node3D,at: Vector3,radius: float,height: float,color: Color,collision=false,top=-1.0,outline: bool=true,glow: Vector2=Vector2.ZERO):
	var mesh=CylinderMesh.new()
	mesh.top_radius=radius if top<0 else top
	mesh.bottom_radius=radius
	mesh.height=height
	mesh.radial_segments=12
	return mesh_at(parent,mesh,at,color,collision,outline,glow)

func prism(parent: Node3D,at: Vector3,dimensions: Vector3,color: Color):
	var mesh=PrismMesh.new()
	mesh.size=dimensions
	return mesh_at(parent,mesh,at,color)

func _ready():
	night=UIStyle.mode=="night"
	mix=1.0 if night else 0.0
	if stage:
		var spots=stage_spots()
		stage_center=spots[0].lerp(spots[1],.5)
	# One outline pass shared by every toon material: ink navy by day, bone at night.
	ink=StandardMaterial3D.new()
	ink.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	ink.cull_mode=BaseMaterial3D.CULL_FRONT
	ink.grow=true
	# The creature models are authored 100 times smaller inside their rigs, so they need
	# their own outline pass with a proportionally thinner grow.
	pet_ink=ink.duplicate()
	var environment=WorldEnvironment.new()
	env=Environment.new()
	sky_material=ShaderMaterial.new()
	sky_material.shader=preload("res://sky.gdshader")
	var sky=Sky.new()
	sky.sky_material=sky_material
	env.background_mode=Environment.BG_SKY
	env.sky=sky
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.tonemap_mode=Environment.TONE_MAPPER_LINEAR
	env.fog_enabled=true
	env.glow_bloom=.12
	env.glow_hdr_threshold=.85
	environment.environment=env
	add_child(environment)
	sun=DirectionalLight3D.new()
	sun.shadow_enabled=true
	sun.shadow_blur=.35
	sun.directional_shadow_max_distance=70
	add_child(sun)
	audio=preload("res://world_audio.gd").new()
	audio.muted=muted
	add_child(audio)
	build_terrain()
	build_landmarks()
	build_trees()
	build_scenery()
	build_grass()
	build_player()
	pivot=Node3D.new()
	add_child(pivot)
	arm=SpringArm3D.new()
	arm.spring_length=7.5
	arm.margin=.3
	arm.add_excluded_object(player.get_rid())
	pivot.add_child(arm)
	camera=Camera3D.new()
	camera.fov=58.0
	camera.far=420
	camera.current=true
	arm.add_child(camera)
	pivot.position=player.position+Vector3(0,1.5,0)
	pivot.rotation=Vector3(pitch,yaw,0)
	if stage: setup_stage()
	apply_look(mix)

## Where the hero and the enemy stand during a battle. The hero is close to the camera at
## the bottom left of the screen; the enemy stands on a rocky bluff further off, so it shows
## at the top right, above the card lanes.
const BLUFF=4.4
func stage_spots() -> Array:
	var hero=Vector3(11.5,0,-2.8)
	var forward=Vector3(6.5,0,-3.2).normalized()
	var right=forward.cross(Vector3.UP)
	var enemy=hero+forward*5.9+right*6.7
	hero.y=ground_height(hero.x,hero.z)
	enemy.y=hero.y+BLUFF
	return [hero,enemy,forward,right]

## A golden marker that bobs above the landmark the current goal points at.
func set_goal(id: String):
	goal_id=id
	if not landmarks.has(id):
		if is_instance_valid(goal_marker): goal_marker.visible=false
		return
	if not is_instance_valid(goal_marker):
		goal_marker=cylinder(self,Vector3.ZERO,.5,1.0,Color("ffd23f"),false,0,true,Vector2(1.4,2.4))
		goal_marker.rotation.x=PI
	goal_at=Vector3(landmarks[id].x,ground_height(landmarks[id].x,landmarks[id].z)+4.6,landmarks[id].z)
	goal_marker.position=goal_at
	goal_marker.visible=true

func near_stage(at: Vector3,clear: float) -> bool:
	return stage and Vector2(at.x-stage_center.x,at.z-stage_center.z).length()<clear

func setup_stage():
	var spots=stage_spots()
	var forward: Vector3=spots[2]
	var right: Vector3=spots[3]
	var duel=spots[1]-spots[0]
	hero_home=spots[0]
	rival_home=spots[1]
	player.position=spots[0]
	avatar.rotation.y=atan2(duel.x,duel.z)
	companion.position=spots[0]-right*1.3+forward*.8
	companion.position.y=ground_height(companion.position.x,companion.position.z)
	companion.rotation.y=avatar.rotation.y
	creature_facing=atan2(-duel.x,-duel.z)
	# the bluff: stacked rock with a grass cap
	var base=ground_height(spots[1].x,spots[1].z)-.6
	var rise=spots[1].y-base
	var rock=Color("9aa0ad")
	cylinder(self,Vector3(spots[1].x,base+rise*.25,spots[1].z),2.9,rise*.5,rock,false,2.4)
	cylinder(self,Vector3(spots[1].x+.3,base+rise*.65,spots[1].z-.2),2.35,rise*.4,rock.lightened(.08),false,1.95)
	cylinder(self,Vector3(spots[1].x,base+rise*.92,spots[1].z),1.95,rise*.16,rock.lightened(.14),false,1.8)
	cylinder(self,Vector3(spots[1].x,spots[1].y-.08,spots[1].z),1.85,.2,Color("57c84d"),false)
	if stage_enemy=="crab" and is_instance_valid(creature):
		rival=creature
		creature.position=spots[1]
	else:
		if is_instance_valid(creature): creature.visible=false
		if stage_enemy=="mira": rival=make_character("Rogue_Hooded" if job=="wizard" else "Mage",[])
		else: rival=make_character("Barbarian",["1H_Axe"])
		add_child(rival)
		rival.position=spots[1]
		rival.rotation.y=creature_facing
		rival_animator=rival.find_child("AnimationPlayer",true,false)
		loop_and_play(rival_animator,"Idle")
	var view=Camera3D.new()
	view.name="StageCamera"
	view.fov=44.0
	view.far=420
	add_child(view)
	view.position=spots[0]-forward*6.4+right*2.85+Vector3(0,3.05,0)
	view.look_at(view.position+forward*10.0+Vector3(0,-.875,0))
	view.current=true

func play_once(animator_node: AnimationPlayer,animation: String):
	if animator_node==null or not animator_node.has_animation(animation): return
	animator_node.get_animation(animation).loop_mode=Animation.LOOP_NONE
	animator_node.speed_scale=1.0
	animator_node.play(animation,.1)
	animator_node.queue("Idle")

## The characters react to what happens in the card battle.
func stage_event(kind: String):
	if not stage: return
	last_stage_event=kind
	var toward=(hero_home-rival_home).normalized()
	match kind:
		"hero_attack":
			play_once(animator,{"warrior":"1H_Melee_Attack_Slice_Diagonal","ranger":"1H_Melee_Attack_Stab","wizard":"Spellcast_Shoot"}.get(job,"1H_Melee_Attack_Chop"))
		"hero_hit":
			play_once(animator,"Hit_A")
		"enemy_attack":
			if rival_animator!=null: play_once(rival_animator,"1H_Melee_Attack_Chop")
			elif is_instance_valid(rival):
				var lunge=create_tween()
				lunge.tween_property(rival,"position",rival_home+toward*1.1,.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				lunge.tween_property(rival,"position",rival_home,.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		"enemy_hit":
			if rival_animator!=null: play_once(rival_animator,"Hit_A")
			elif is_instance_valid(rival):
				rival.scale=Vector3(1.25,.8,1.25)
				create_tween().tween_property(rival,"scale",Vector3.ONE,.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		"win":
			loop_and_play(animator,"Cheer")
			if rival_animator!=null:
				rival_animator.clear_queue()
				rival_animator.play("Death_A",.1)
			elif is_instance_valid(rival): create_tween().tween_property(rival,"scale",Vector3(1.1,.25,1.1),.4)
		"lose":
			if animator!=null and animator.has_animation("Death_A"):
				animator.clear_queue()
				animator.play("Death_A",.1)
			if rival_animator!=null: loop_and_play(rival_animator,"Cheer")

## Everything that differs between day (0) and night (1), blended by `t`.
func apply_look(t: float):
	mix=t
	ink.albedo_color=Color("1d2a4d").lerp(Color("a59d8b"),t)
	ink.grow_amount=lerpf(.045,.025,t)
	pet_ink.albedo_color=ink.albedo_color
	pet_ink.grow_amount=ink.grow_amount/(100.0*PET_SCALE)*.7
	var dusk=sin(PI*t)  # peaks halfway through a change: a short orange sunset
	sky_material.set_shader_parameter("top_color",Color("2f9be6").lerp(Color("0d0b1e"),t))
	sky_material.set_shader_parameter("horizon_color",Color("b9ecff").lerp(Color("2c2552"),t).lerp(Color("ff9a5a"),dusk*.6))
	sky_material.set_shader_parameter("disc_color",Color("fff27a").lerp(Color("f0e6c8"),t))
	sky_material.set_shader_parameter("disc_size",lerpf(.05,.035,t))
	sky_material.set_shader_parameter("stars",smoothstep(.55,1.0,t))
	env.ambient_light_color=Color("cdeeff").lerp(Color("4a4590"),t)
	env.ambient_light_energy=lerpf(.42,.5,t)
	env.fog_light_color=Color("c4eeff").lerp(Color("1c1838"),t).lerp(Color("ffb37a"),dusk*.4)
	env.fog_density=lerpf(.0035,.02,t)
	env.fog_sky_affect=lerpf(0.0,.25,t)
	env.glow_enabled=t>.02
	env.glow_intensity=.9*t
	sun.rotation_degrees=Vector3(lerpf(-48,-32,t)+dusk*18,lerpf(-35,150,t),0)
	sun.light_color=Color("fff3d0").lerp(Color("a9b6ff"),t).lerp(Color("ffb37a"),dusk*.5)
	sun.light_energy=lerpf(.64,.4,t)
	water_material.set_shader_parameter("deep",Color("1689d6").lerp(Color("141033"),t))
	water_material.set_shader_parameter("shallow",Color("58d6ee").lerp(Color("2a2466"),t))
	water_material.set_shader_parameter("foam",Color("ffffff").lerp(Color("b9b3e6"),t))
	water_material.set_shader_parameter("glints",lerpf(.6,.35,t))
	for entry in glows: entry[0].emission_energy_multiplier=lerpf(entry[1].x,entry[1].y,t)
	lamps=lamps.filter(func(entry): return is_instance_valid(entry[0]))
	for entry in lamps:
		entry[0].light_energy=lerpf(entry[1],entry[2],t)
		entry[0].visible=entry[0].light_energy>.02
	if cloud_tint!=null: cloud_tint.albedo_color=Color("ffffff").lerp(Color("3a3466"),t).lerp(Color("ffc9a3"),dusk*.5)
	if is_instance_valid(audio): audio.set_night_mix(t)

## Change between day and night. The sun sweeps round, the sky passes through a short
## sunset, and lights, fog, stars and crickets fade in or out.
func set_night(value: bool,seconds: float=1.8):
	night=value
	var target=1.0 if value else 0.0
	if blend!=null and blend.is_valid(): blend.kill()
	if is_equal_approx(mix,target): return
	if seconds<=0:
		apply_look(target)
		return
	blend=create_tween()
	blend.tween_method(apply_look,mix,target,seconds).set_trans(Tween.TRANS_SINE)

func set_muted(value: bool):
	muted=value
	if is_instance_valid(audio): audio.set_muted(value)

func build_terrain():
	var surface=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sand=Color("ffd97a")
	var grass=Color("62d45c")
	var meadow=Color("4ac458")
	var hill=Color("36aa54")
	for x in range(-38,38):
		for z in range(-31,31):
			for offset in [Vector2(0,0),Vector2(1,0),Vector2(0,1),Vector2(1,0),Vector2(1,1),Vector2(0,1)]:
				var at=Vector3(x+offset.x,0,z+offset.y)
				at.y=ground_height(at.x,at.z)
				var edge=sqrt(pow(at.x/35,2)+pow(at.z/28,2))
				# large flat patches of colour instead of per-vertex speckle
				var color=grass if sin(at.x*.31)+cos(at.z*.27+1.3)+sin((at.x+at.z)*.11)>.2 else meadow
				if at.y>1.5: color=hill
				if edge>.84: color=sand
				surface.set_color(color)
				surface.add_vertex(at)
	surface.index()
	surface.generate_normals()
	var terrain=MeshInstance3D.new()
	terrain.mesh=surface.commit()
	var ground=ShaderMaterial.new()
	ground.shader=preload("res://terrain.gdshader")
	terrain.material_override=ground
	add_child(terrain)
	terrain.create_trimesh_collision()
	var water=PlaneMesh.new()
	water.size=Vector2(700,700)
	var sea=MeshInstance3D.new()
	sea.mesh=water
	sea.position=Vector3(0,-.5,0)
	water_material=ShaderMaterial.new()
	water_material.shader=preload("res://water.gdshader")
	sea.material_override=water_material
	add_child(sea)
	# Paths follow terrain height and remain non-colliding ground markings.
	for pair in [[Vector3(-18,0,0),landmarks.home],[landmarks.home,landmarks.friend],[landmarks.friend,landmarks.crop],[landmarks.crop,landmarks.encounter],[landmarks.crop,landmarks.camp],[landmarks.camp,landmarks.dock]]:
		var distance=pair[0].distance_to(pair[1])
		for i in range(int(distance/.7)+1):
			var at=pair[0].lerp(pair[1],float(i)/maxf(1,int(distance/.7)))
			at.y=ground_height(at.x,at.z)+.02
			path_points.append(at)
			cylinder(self,at,1.0,.03,Color("f2d88a"),false,-1.0,false)

func label3d(at: Vector3,text_value: String):
	var label=Label3D.new()
	label.text=text_value
	label.font_size=40
	label.pixel_size=.015
	label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate=Color("fff1d2")
	label.outline_modulate=Color("243c44")
	label.outline_size=9
	label.position=at
	add_child(label)

## A point light with a day strength and a night strength.
func lamp(parent: Node3D,at: Vector3,color: Color,reach: float,day: float,dark: float):
	var light=OmniLight3D.new()
	light.position=at
	light.light_color=color
	light.omni_range=reach
	parent.add_child(light)
	lamps.append([light,day,dark])

func build_landmarks():
	var warm=Color("ffc75a")
	for id in landmarks:
		var at=landmarks[id]
		at.y=ground_height(at.x,at.z)
		landmarks[id]=at
		match id:
			"home":
				box(self,at+Vector3(0,1.3,-1.5),Vector3(4,2.6,3),Color("fff5dc"),true)
				prism(self,at+Vector3(0,3.45,-1.5),Vector3(4.7,1.7,3.7),Color("ff6b57"))
				box(self,at+Vector3(1.2,3.7,-2.1),Vector3(.6,1.3,.6),Color("c9b99a"))
				box(self,at+Vector3(0,.9,.03),Vector3(.9,1.8,.12),Color("8a5a2b"))
				sphere(self,at+Vector3(.28,.9,.12),.07,warm)
				for side in [-1,1]:
					box(self,at+Vector3(side*1.2,1.45,.05),Vector3(.65,.7,.12),Color("8fdcf2"),false,Vector2(0,2.4),warm)
					box(self,at+Vector3(side*1.2,1.05,.14),Vector3(.8,.14,.2),Color("ff6b57"))
				for i in range(6): box(self,at+Vector3(-2.9+i*1.15,.35,1.7),Vector3(.14,.7,.14),Color("fff5dc"))
				box(self,at+Vector3(0,.5,1.7),Vector3(6.2,.1,.08),Color("fff5dc"))
				lamp(self,at+Vector3(0,1.6,1.2),warm,7,0,1.2)
			"friend":
				var npc=make_character("Rogue_Hooded" if job=="wizard" else "Mage",[])
				add_child(npc)
				npc.position=at
				npc.rotation.y=.6
				var npc_player=npc.find_child("AnimationPlayer",true,false)
				if npc_player!=null: loop_and_play(npc_player,"Idle")
			"crop":
				for i in range(7):
					var spot=at+Vector3(sin(i*2.4)*1.5,.3,cos(i*2.4)*1.5)
					var crystal=cylinder(self,spot,.22,.9,Color("ffd23f"),false,0,true,Vector2(.25,1.8))
					crystal.rotation.z=.2
				lamp(self,at+Vector3(0,1,0),Color("ffd23f"),6,0,.8)
				if restored_garden:
					for i in range(12): sphere(self,at+Vector3(sin(i)*2,.3,cos(i)*2),.18,Color("ff9ec7"))
			"encounter":
				creature=make_crab()
				add_child(creature)
				creature.position=at
			"camp":
				for i in range(8): sphere(self,at+Vector3(sin(i*TAU/8)*.8,.1,cos(i*TAU/8)*.8),.2,Color("9aa3b5"))
				flame=cylinder(self,at+Vector3(0,.5,0),.36,1.0,Color("ff8a2b"),false,0,false,Vector2(2.2,2.8))
				cylinder(self,at+Vector3(0,.4,0),.2,.7,Color("ffe07a"),false,0,false,Vector2(2.6,3.2))
				for i in range(3): box(self,at+Vector3(sin(i*2.1)*.35,.12,cos(i*2.1)*.35),Vector3(.9,.16,.16),Color("8a5a2b")).rotation.y=i*2.1
				prism(self,at+Vector3(-3.6,.7,-2.2),Vector3(1.9,1.4,2.3),Color("ffd23f")).rotation.y=.5
				lamp(self,at+Vector3(0,1,0),Color("ffb668"),8,.8,1.7)
			"dock":
				for i in range(9): box(self,at+Vector3(0,.12,i*.6),Vector3(2,.2,.52),Color("c9975a"),true)
				for i in [0,4,8]:
					for side in [-1,1]: cylinder(self,at+Vector3(side*1.05,.1,i*.6),.12,1.6,Color("8a5a2b"))
				cylinder(self,at+Vector3(1.05,1.25,4.8),.2,.34,warm,false,-1.0,true,Vector2(.4,3.0))
				lamp(self,at+Vector3(1.05,1.5,4.8),warm,7,0,1.2)
	# Jumpable stepping stones create an optional exploration loop.
	for i in range(5):
		var at=Vector3(-7+i*1.5,0,4)
		at.y=ground_height(at.x,at.z)+.3+i*.12
		box(self,at,Vector3(1.1,.5+i*.24,1.1),Color("aab3c5"),true)


func free_spot(at: Vector3,clear: float) -> bool:
	if sqrt(pow(at.x/35,2)+pow(at.z/28,2))>.8: return false
	for mark in landmarks.values():
		if at.distance_to(Vector3(mark.x,0,mark.z))<clear: return false
	return absf(at.z)>=2

func build_trees():
	var random=RandomNumberGenerator.new()
	random.seed=47
	var greens=[Color("2fae5d"),Color("46c463"),Color("63d472")]
	for i in range(55):
		var at=Vector3(random.randf_range(-29,29),0,random.randf_range(-22,22))
		if sqrt(pow(at.x/35,2)+pow(at.z/28,2))>.83: continue
		var occupied=false
		for mark in landmarks.values():
			if at.distance_to(Vector3(mark.x,0,mark.z))<4.5: occupied=true
		if occupied or absf(at.z)<2 or near_stage(at,11.0): continue
		at.y=ground_height(at.x,at.z)
		cylinder(self,at+Vector3(0,1.2,0),.26,2.4,Color("9a6a3a"),true)
		if i%3==0:
			# pine: three stacked cones
			for layer in range(3): cylinder(self,at+Vector3(0,2.3+layer*.8,0),1.5-layer*.3,2,greens[layer],false,0)
		else:
			# broadleaf: one big round crown with two smaller puffs
			var crown=greens[i%3]
			sphere(self,at+Vector3(0,3.3,0),1.55,crown)
			sphere(self,at+Vector3(.95,2.7,.3),.95,crown.darkened(.08))
			sphere(self,at+Vector3(-.8,2.9,-.5),1.05,crown.lightened(.08))

## Bushes, rocks, flowers and clouds: cheap shapes that make the island feel lived in.
func build_scenery():
	var random=RandomNumberGenerator.new()
	random.seed=91
	var petals=[Color("ff6b57"),Color("ffd23f"),Color("ffffff"),Color("ff9ec7")]
	for i in range(150):
		var at=Vector3(random.randf_range(-30,30),0,random.randf_range(-23,23))
		if not free_spot(at,2.5): continue
		at.y=ground_height(at.x,at.z)
		var kind=i%10
		if kind<3 and near_stage(at,11.0): continue
		if kind<2:
			sphere(self,at+Vector3(0,.35,0),.6,Color("39b85e")).scale.y=.75
			sphere(self,at+Vector3(.5,.25,.2),.42,Color("4fc96a"))
		elif kind==2:
			var rock=sphere(self,at+Vector3(0,.2,0),.55,Color("aab3c5"))
			rock.scale=Vector3(1.2,.6,.9)
			rock.rotation.y=random.randf()*TAU
		else:
			cylinder(self,at+Vector3(0,.16,0),.025,.32,Color("2fae5d"),false,-1.0,false)
			sphere(self,at+Vector3(0,.36,0),.11,petals[i%petals.size()],false,Vector2(0,.9) if i%4==0 else Vector2.ZERO)
	cloud_tint=StandardMaterial3D.new()
	cloud_tint.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	cloud_tint.disable_fog=true
	for i in range(14):
		var angle=random.randf()*TAU
		var far=random.randf_range(70,150)
		var cloud=Node3D.new()
		cloud.position=Vector3(cos(angle)*far,random.randf_range(24,44),sin(angle)*far)
		add_child(cloud)
		for puff in range(4):
			var ball=sphere(cloud,Vector3(puff*4.2-6.3,sin(puff*1.7)*1.1,cos(puff*2.3)*1.5),random.randf_range(3.2,5.2),Color.WHITE,false)
			ball.scale.y=.55
			ball.material_override=cloud_tint
			ball.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		clouds.append(cloud)

## Swaying grass tufts across the meadow, drawn as a single MultiMesh.
func build_grass():
	var blade=CylinderMesh.new()
	blade.top_radius=0
	blade.bottom_radius=.06
	blade.height=.34
	blade.radial_segments=3
	blade.rings=1
	var sway=ShaderMaterial.new()
	sway.shader=preload("res://grass.gdshader")
	blade.material=sway
	var random=RandomNumberGenerator.new()
	random.seed=7
	var tones=[Color("3fb54f"),Color("57c95c"),Color("2f9f48")]
	var blades=[]
	for i in range(1100):
		var at=Vector3(random.randf_range(-31,31),0,random.randf_range(-24,24))
		if not free_spot(at,2.2): continue
		var on_path=false
		for point in path_points:
			if absf(point.x-at.x)<1.3 and absf(point.z-at.z)<1.3: on_path=true; break
		if on_path: continue
		for k in range(3):
			var spot=at+Vector3(random.randf_range(-.16,.16),0,random.randf_range(-.16,.16))
			var tall=random.randf_range(.7,1.5)
			spot.y=ground_height(spot.x,spot.z)+.17*tall
			blades.append([Transform3D(Basis(Vector3.UP,random.randf()*TAU).scaled(Vector3(1,tall,1)),spot),tones[(i+k)%3]])
	var field=MultiMesh.new()
	field.transform_format=MultiMesh.TRANSFORM_3D
	field.use_colors=true
	field.mesh=blade
	field.instance_count=blades.size()
	for i in range(blades.size()):
		field.set_instance_transform(i,blades[i][0])
		field.set_instance_color(i,blades[i][1])
	var holder=MultiMeshInstance3D.new()
	holder.multimesh=field
	holder.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(holder)
	grass_blades=blades.size()

func loop_and_play(animator_node: AnimationPlayer,animation: String,speed: float=1.0):
	if animator_node==null or not animator_node.has_animation(animation): return
	animator_node.get_animation(animation).loop_mode=Animation.LOOP_LINEAR
	if animator_node.current_animation!=animation: animator_node.play(animation,.18)
	animator_node.speed_scale=speed

## An animated KayKit adventurer (CC0), toon shaded with the shared ink outline.
## Falls back to the old block figure if the model is missing.
func make_character(kind: String,held_items: Array) -> Node3D:
	var path="res://assets/characters/%s.glb" % kind
	if not ResourceLoader.exists(path): return make_person(Color("39738c"))
	var model=load(path).instantiate()
	model.scale=Vector3.ONE*.8
	for slot in model.find_children("handslot_*","BoneAttachment3D",true,false):
		for item in slot.get_children(): item.visible=held_items.has(String(item.name))
	toonify(model)
	return model

## Give an imported model the island's toon shading and shared ink outline.
func toonify(model: Node3D,outline: StandardMaterial3D=null):
	if outline==null: outline=ink
	for part in model.find_children("*","MeshInstance3D",true,false):
		for i in range(part.mesh.get_surface_count()):
			var source=part.mesh.surface_get_material(i)
			var key=["character",source,outline]
			if not materials.has(key):
				var toon=source.duplicate() if source is BaseMaterial3D else StandardMaterial3D.new()
				toon.diffuse_mode=BaseMaterial3D.DIFFUSE_TOON
				toon.specular_mode=BaseMaterial3D.SPECULAR_DISABLED
				toon.roughness=1.0
				toon.metallic=0.0
				toon.next_pass=outline
				materials[key]=toon
			part.set_surface_override_material(i,materials[key])

func make_person(color: Color) -> Node3D:
	var person=Node3D.new()
	box(person,Vector3(0,1.05,0),Vector3(.62,.7,.4),color)
	sphere(person,Vector3(0,1.63,0),.25,Color("e4bd8b"))
	var hair=sphere(person,Vector3(0,1.79,-.035),.24,Color("584b3e"))
	hair.scale.y=.65
	for x in [-.09,.09]: sphere(person,Vector3(x,1.64,.225),.026,Color("26373b"),false)
	box(person,Vector3(0,1.25,-.28),Vector3(.42,.5,.22),Color("b99762"))
	for side in [-1,1]:
		var leg=Node3D.new()
		leg.position=Vector3(side*.17,.72,0)
		person.add_child(leg)
		box(leg,Vector3(0,-.3,0),Vector3(.22,.6,.24),Color("425061"))
		box(leg,Vector3(0,-.64,.06),Vector3(.24,.15,.38),Color("4b4139"))
		var limb=Node3D.new()
		limb.position=Vector3(side*.38,1.35,0)
		person.add_child(limb)
		box(limb,Vector3(0,-.2,0),Vector3(.19,.45,.22),color)
		sphere(limb,Vector3(0,-.48,0),.1,Color("e4bd8b"))
		legs.append(leg)
		arms.append(limb)
	return person

## The starter companion: a round friend with big eyes and one feature for its element.
func make_companion() -> Node3D:
	var pet=Node3D.new()
	# Animated Quaternius monsters (CC0) when present; the code-built friend is the fallback.
	var models={"fire":["Dragon","Flying_Idle","Fast_Flying",.9],"water":["Fish","Idle","Run",0.0],"earth":["Cactoro","Idle","Walk",0.0],"air":["Birb","Idle","Walk",0.0]}
	var pick=models.get(element,models.fire)
	var path="res://assets/creatures/%s.glb" % pick[0]
	if ResourceLoader.exists(path):
		var model=load(path).instantiate()
		model.scale=Vector3.ONE*PET_SCALE
		model.position.y=pick[3]
		toonify(model,pet_ink)
		pet.add_child(model)
		pet_animator=model.find_child("AnimationPlayer",true,false)
		pet_idle="CharacterArmature|"+pick[1]
		pet_move="CharacterArmature|"+pick[2]
		loop_and_play(pet_animator,pet_idle)
		lamp(pet,Vector3(0,.6,0),{"fire":Color("ff8a3d"),"water":Color("4fb8ee"),"earth":Color("6fcf5a"),"air":Color("c9b6ff")}.get(element,Color("ff8a3d")),3.5,0,.7)
		return pet
	var tones={"fire":[Color("ff8a3d"),Color("ffd27a")],"water":[Color("4fb8ee"),Color("c9f1ff")],"earth":[Color("6fcf5a"),Color("d9f2a6")],"air":[Color("c9b6ff"),Color("ffffff")]}
	var tone=tones.get(element,tones.fire)
	var navy=Color("1d2a4d")
	sphere(pet,Vector3(0,.34,0),.32,tone[0],true,Vector2(0,.45)).scale=Vector3(1,.92,1)
	sphere(pet,Vector3(0,.28,.17),.2,tone[1],false).scale=Vector3(1,.9,.6)
	for side in [-1,1]:
		sphere(pet,Vector3(side*.12,.44,.26),.085,Color.WHITE,false)
		sphere(pet,Vector3(side*.12,.44,.325),.046,navy,false)
		sphere(pet,Vector3(side*.135,.47,.362),.016,Color.WHITE,false)
		sphere(pet,Vector3(side*.21,.33,.24),.045,Color("ff9ec7"),false)
		sphere(pet,Vector3(side*.14,.06,.05),.1,tone[0]).scale=Vector3(1,.6,1.3)
	match element:
		"water":
			for side in [-1,1]:
				var fin=sphere(pet,Vector3(side*.33,.36,0),.14,tone[0])
				fin.scale=Vector3(.35,.9,1.1)
				pet_wings.append(fin)
			sphere(pet,Vector3(0,.66,-.04),.12,Color("2f8fff")).scale=Vector3(.3,1.1,1.4)
			sphere(pet,Vector3(0,.3,-.36),.13,Color("2f8fff")).scale=Vector3(1.3,.3,1)
		"earth":
			sphere(pet,Vector3(0,.4,-.14),.27,Color("8a5a2b")).scale=Vector3(1,.85,.8)
			cylinder(pet,Vector3(0,.72,0),.025,.2,Color("2fae5d"),false,-1.0,false)
			for side in [-1,1]:
				var leaf=sphere(pet,Vector3(side*.12,.84,0),.12,Color("46c463"))
				leaf.scale=Vector3(1.2,.25,.7)
				leaf.rotation.z=side*-.5
				pet_wings.append(leaf)
		"air":
			for side in [-1,1]:
				var wing=sphere(pet,Vector3(side*.36,.44,-.05),.17,Color.WHITE)
				wing.scale=Vector3(1,.25,.7)
				pet_wings.append(wing)
			for i in range(3): sphere(pet,Vector3((i-1)*.14,.66,-.02),.1,Color.WHITE,false)
		_:
			for i in range(3): cylinder(pet,Vector3((i-1)*.1,.74+(.08 if i==1 else 0.0),-.02),.09,.3,Color("ff6b2b") if i==1 else Color("ffd23f"),false,0,false,Vector2(.6,2.2))
			cylinder(pet,Vector3(0,.3,-.36),.07,.24,Color("ffd23f"),false,0,false,Vector2(.6,2.2)).rotation.x=-1.0
	lamp(pet,Vector3(0,.5,0),tone[0],3.5,0,.7)
	return pet

## The Resin Crab: wide spotted shell, eye stalks, two snapping claws and six legs.
func make_crab() -> Node3D:
	var crab=Node3D.new()
	var navy=Color("1d2a4d")
	sphere(crab,Vector3(0,.62,0),.7,Color("ff8a3d")).scale=Vector3(1.25,.75,1)
	sphere(crab,Vector3(0,.5,.3),.45,Color("ffd9a8"),false).scale=Vector3(1.2,.6,.7)
	for i in range(5): sphere(crab,Vector3(sin(i*1.3)*.5,1.0-absf(sin(i*1.3))*.14,cos(i*1.9)*.3-.15),.09,Color("ffd27a"),false,Vector2(.2,1.4))
	for side in [-1,1]:
		cylinder(crab,Vector3(side*.25,1.1,.4),.045,.36,Color("ff8a3d"))
		sphere(crab,Vector3(side*.25,1.32,.42),.13,Color.WHITE)
		sphere(crab,Vector3(side*.25,1.33,.52),.065,navy,false)
		box(crab,Vector3(side*.78,.55,.32),Vector3(.42,.14,.14),Color("d9622b"))
		var claw=Node3D.new()
		claw.position=Vector3(side*1.05,.6,.5)
		crab.add_child(claw)
		sphere(claw,Vector3.ZERO,.3,Color("ff6b2b")).scale=Vector3(1,.8,1.2)
		for jaw in [-1,1]:
			var pincer=cylinder(claw,Vector3(0,jaw*.12,.36),.11,.36,Color("ff6b2b"),false,0)
			pincer.rotation.x=PI/2
		crab_claws.append(claw)
		for leg in range(3):
			var limb=box(crab,Vector3(side*.88,.26,leg*.32-.42),Vector3(.6,.11,.11),Color("d9622b"))
			limb.rotation.z=side*-.5
			crab_legs.append(limb)
	return crab

func build_player():
	legs.clear()
	arms.clear()
	player=CharacterBody3D.new()
	player.floor_snap_length=.35
	add_child(player)
	var shape=CollisionShape3D.new()
	var capsule=CapsuleShape3D.new()
	capsule.radius=.32
	capsule.height=1.8
	shape.shape=capsule
	shape.position.y=.9
	player.add_child(shape)
	var looks={"warrior":["Knight",["1H_Sword","Round_Shield"]],"ranger":["Rogue_Hooded",[]],"wizard":["Mage",["2H_Staff"]]}
	var look=looks.get(job,looks.warrior)
	avatar=make_character(look[0],look[1])
	animator=avatar.find_child("AnimationPlayer",true,false)
	loop_and_play(animator,"Idle")
	player.add_child(avatar)
	avatar.rotation.y=PI
	player.position=spawn_position
	player.position.y=maxf(player.position.y,ground_height(player.position.x,player.position.z)+.1)
	last_safe=player.position
	companion=make_companion()
	add_child(companion)
	companion.position=player.position+Vector3(1,0,1)

func _process(delta):
	clock+=delta
	if is_instance_valid(goal_marker) and goal_marker.visible:
		goal_marker.position.y=goal_at.y+.3*sin(clock*3.0)
		goal_marker.rotation.y=clock*1.6
	for cloud in clouds:
		cloud.position.x+=delta*.6
		if cloud.position.x>160: cloud.position.x=-160
	if is_instance_valid(flame): flame.scale=Vector3.ONE*(1.0+.08*sin(clock*11.0)+.05*sin(clock*17.0))
	if is_instance_valid(creature):
		creature.position.y=(rival_home.y if stage else landmarks.encounter.y)+.07*absf(sin(clock*2.2))
		creature.rotation.y=creature_facing+.25*sin(clock*.8)
		for i in range(crab_claws.size()): crab_claws[i].rotation.z=(1 if i==0 else -1)*(.15+.2*absf(sin(clock*2.6+i)))
		for i in range(crab_legs.size()): crab_legs[i].rotation.y=.18*sin(clock*5.0+i*1.1)
	if is_instance_valid(companion):
		var hopping=player!=null and Vector2(player.velocity.x,player.velocity.z).length()>.5
		if pet_animator!=null: loop_and_play(pet_animator,pet_move if hopping else pet_idle)
		else:
			var squash=.09*sin(clock*9.0) if hopping else .03*sin(clock*2.4)
			companion.scale=Vector3(1.0-squash*.5,1.0+squash,1.0-squash*.5)
		for i in range(pet_wings.size()): pet_wings[i].rotation.x=.5*sin(clock*(12.0 if hopping else 4.0)+i*PI)

func input_event(event):
	if event is InputEventKey:
		if not event.pressed: held.erase(event.keycode)
		elif not event.echo:
			held[event.keycode]=true
			if event.keycode==KEY_SPACE: jump_queued=true
			if event.keycode==KEY_E and not current_landmark.is_empty():
				audio.chime()
				interact_requested.emit(current_landmark)
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_RIGHT:
			orbiting=event.pressed
			manual_camera_grace=.8
		if event.pressed and event.button_index==MOUSE_BUTTON_WHEEL_UP: arm.spring_length=maxf(3.5,arm.spring_length-.5)
		if event.pressed and event.button_index==MOUSE_BUTTON_WHEEL_DOWN: arm.spring_length=minf(12,arm.spring_length+.5)
	if event is InputEventMouseMotion and orbiting:
		yaw-=event.relative.x*.006
		pitch=clampf(pitch-event.relative.y*.004,-.8,.08)
		manual_camera_grace=.8

func stop_input():
	held.clear()
	orbiting=false
	jump_queued=false
	previous_axis=Vector2.ZERO

func _physics_process(delta):
	if player==null or stage: return
	var axis=Vector2(float(held.has(KEY_D) or held.has(KEY_RIGHT))-float(held.has(KEY_A) or held.has(KEY_LEFT)),float(held.has(KEY_S) or held.has(KEY_DOWN))-float(held.has(KEY_W) or held.has(KEY_UP))).normalized()
	# Automatic orbit must not rotate the movement basis every frame: holding
	# sideways would otherwise make the player run in circles as the camera follows.
	var by_stick=stick.length()>.15
	if by_stick: axis=stick.limit_length(1.0)
	# a stick wobbles all the time, so it only re-reads the camera when it is first pushed
	if (previous_axis.is_zero_approx() if by_stick else not axis.is_equal_approx(previous_axis)) or orbiting:
		movement_yaw=yaw
	previous_axis=axis
	var movement=Basis(Vector3.UP,movement_yaw)*Vector3(axis.x,0,axis.y)
	manual_camera_grace=maxf(0,manual_camera_grace-delta)
	var speed=RUN if held.has(KEY_SHIFT) or stick.length()>.9 else WALK
	player.velocity.x=move_toward(player.velocity.x,movement.x*speed,24*delta)
	player.velocity.z=move_toward(player.velocity.z,movement.z*speed,24*delta)
	if not player.is_on_floor(): player.velocity.y-=GRAVITY*delta
	elif jump_queued:
		player.velocity.y=JUMP
		audio.jump()
	jump_queued=false
	player.move_and_slide()
	var grounded=player.is_on_floor()
	if airborne and grounded and clock>.8: audio.land()  # no thud for the drop-in at spawn
	airborne=not grounded
	if grounded and movement.length()>.01:
		stride+=delta*speed
		if stride>2.3:
			stride=0.0
			audio.footstep()
	else: stride=1.6
	if movement.length()>.01:
		avatar.rotation.y=lerp_angle(avatar.rotation.y,atan2(movement.x,movement.z),minf(1,12*delta))
		step+=delta*speed*2.3
	else: step=0
	if animator!=null:
		if not player.is_on_floor(): loop_and_play(animator,"Jump_Idle")
		elif movement.length()>.01: loop_and_play(animator,"Running_A" if held.has(KEY_SHIFT) else "Walking_A",1.0 if held.has(KEY_SHIFT) else 1.5)
		else: loop_and_play(animator,"Idle")
	for i in range(legs.size()): legs[i].rotation.x=sin(step+(PI if i%2 else 0))*.55 if player.is_on_floor() else -.35
	for i in range(arms.size()): arms[i].rotation.x=-sin(step+(PI if i%2 else 0))*.45
	if player.position.y<-.7:
		player.position=last_safe
		player.velocity=Vector3.ZERO
	elif player.is_on_floor() and ground_height(player.position.x,player.position.z)>.05: last_safe=player.position
	var horizontal_speed=Vector2(player.velocity.x,player.velocity.z).length()
	if movement.length()>.01 and horizontal_speed>.25 and not orbiting and manual_camera_grace<=0:
		var behind=atan2(-movement.x,-movement.z)
		yaw=lerp_angle(yaw,behind,1-exp(-3.0*delta))
	pivot.position=pivot.position.lerp(player.position+Vector3(0,1.45,0),1-exp(-12*delta))
	pivot.rotation=Vector3(pitch,yaw,0)
	var follow=player.position+Vector3(1.2,0,1.2)
	follow.y=ground_height(follow.x,follow.z)+(.14*absf(sin(clock*9.0)) if movement.length()>.01 and pet_animator==null else 0.0)
	companion.position=companion.position.lerp(follow,minf(1,delta*3))
	companion.rotation.y=avatar.rotation.y
	var nearby=""
	var distance=4.0
	for id in landmarks:
		var d=Vector2(player.position.x,player.position.z).distance_to(Vector2(landmarks[id].x,landmarks[id].z))
		if d<distance: nearby=id; distance=d
	if nearby!=current_landmark:
		current_landmark=nearby
		nearby_changed.emit(nearby)
	save_clock+=delta
	if save_clock>1.0:
		save_clock=0
		position_saved.emit(player.position)

