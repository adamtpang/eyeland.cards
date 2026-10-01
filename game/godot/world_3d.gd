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

## Shared toon material: flat banded light, no highlights, optional ink outline and glow.
func material(color: Color,outline: bool=true,glow: float=0.0) -> StandardMaterial3D:
	var key=[color,outline,glow]
	if materials.has(key): return materials[key]
	var m=StandardMaterial3D.new()
	m.albedo_color=color
	m.roughness=1.0
	m.diffuse_mode=BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode=BaseMaterial3D.SPECULAR_DISABLED
	if glow>0:
		m.emission_enabled=true
		m.emission=color
		m.emission_energy_multiplier=glow
	if outline: m.next_pass=ink
	materials[key]=m
	return m

func mesh_at(parent: Node3D, mesh: Mesh, at: Vector3, color: Color, collision=false, outline: bool=true, glow: float=0.0) -> MeshInstance3D:
	var instance=MeshInstance3D.new()
	instance.mesh=mesh
	instance.material_override=material(color,outline,glow)
	instance.position=at
	parent.add_child(instance)
	if collision: instance.create_trimesh_collision()
	return instance

func box(parent: Node3D,at: Vector3,dimensions: Vector3,color: Color,collision=false,glow: float=0.0):
	var mesh=BoxMesh.new()
	mesh.size=dimensions
	return mesh_at(parent,mesh,at,color,collision,true,glow)

func sphere(parent: Node3D,at: Vector3,radius: float,color: Color,outline: bool=true,glow: float=0.0):
	var mesh=SphereMesh.new()
	mesh.radius=radius
	mesh.height=radius*2
	mesh.radial_segments=16
	mesh.rings=8
	return mesh_at(parent,mesh,at,color,false,outline,glow)

func cylinder(parent: Node3D,at: Vector3,radius: float,height: float,color: Color,collision=false,top=-1.0,outline: bool=true,glow: float=0.0):
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
	# One outline pass shared by every toon material: ink navy by day, bone at night.
	ink=StandardMaterial3D.new()
	ink.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	ink.albedo_color=Color("a59d8b") if night else Color("1d2a4d")
	ink.cull_mode=BaseMaterial3D.CULL_FRONT
	ink.grow=true
	ink.grow_amount=.025 if night else .045
	var environment=WorldEnvironment.new()
	var env=Environment.new()
	var sky_material=ShaderMaterial.new()
	sky_material.shader=preload("res://sky.gdshader")
	sky_material.set_shader_parameter("top_color",Color("0d0b1e") if night else Color("2f9be6"))
	sky_material.set_shader_parameter("horizon_color",Color("2c2552") if night else Color("b9ecff"))
	sky_material.set_shader_parameter("disc_color",Color("f0e6c8") if night else Color("fff27a"))
	sky_material.set_shader_parameter("disc_size",.035 if night else .05)
	sky_material.set_shader_parameter("stars",1.0 if night else 0.0)
	var sky=Sky.new()
	sky.sky_material=sky_material
	env.background_mode=Environment.BG_SKY
	env.sky=sky
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color("4a4590") if night else Color("cdeeff")
	env.ambient_light_energy=.7 if night else .42
	env.tonemap_mode=Environment.TONE_MAPPER_LINEAR
	env.fog_enabled=true
	env.fog_light_color=Color("1c1838") if night else Color("c4eeff")
	env.fog_density=.022 if night else .0035
	env.fog_sky_affect=.25 if night else 0.0
	env.glow_enabled=night
	env.glow_intensity=.9
	env.glow_bloom=.12
	env.glow_hdr_threshold=.85
	environment.environment=env
	add_child(environment)
	var sun=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-32,150,0) if night else Vector3(-48,-35,0)
	sun.light_color=Color("a9b6ff") if night else Color("fff3d0")
	sun.light_energy=.55 if night else .64
	sun.shadow_enabled=true
	sun.shadow_blur=.35
	sun.directional_shadow_max_distance=70
	add_child(sun)
	build_terrain()
	build_landmarks()
	build_trees()
	build_scenery()
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
	var mat=StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo=true
	mat.roughness=1
	mat.diffuse_mode=BaseMaterial3D.DIFFUSE_TOON
	mat.specular_mode=BaseMaterial3D.SPECULAR_DISABLED
	terrain.material_override=mat
	add_child(terrain)
	terrain.create_trimesh_collision()
	var water=PlaneMesh.new()
	water.size=Vector2(700,700)
	var sea=MeshInstance3D.new()
	sea.mesh=water
	sea.position=Vector3(0,-.5,0)
	var water_material=ShaderMaterial.new()
	water_material.shader=preload("res://water.gdshader")
	water_material.set_shader_parameter("deep",Color("141033") if night else Color("1689d6"))
	water_material.set_shader_parameter("shallow",Color("2a2466") if night else Color("58d6ee"))
	water_material.set_shader_parameter("foam",Color("b9b3e6") if night else Color("ffffff"))
	water_material.set_shader_parameter("glints",.35 if night else .6)
	sea.material_override=water_material
	add_child(sea)
	# Paths follow terrain height and remain non-colliding ground markings.
	for pair in [[Vector3(-18,0,0),landmarks.home],[landmarks.home,landmarks.friend],[landmarks.friend,landmarks.crop],[landmarks.crop,landmarks.encounter],[landmarks.crop,landmarks.camp],[landmarks.camp,landmarks.dock]]:
		var distance=pair[0].distance_to(pair[1])
		for i in range(int(distance/.7)+1):
			var at=pair[0].lerp(pair[1],float(i)/maxf(1,int(distance/.7)))
			at.y=ground_height(at.x,at.z)+.02
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

func lamp(at: Vector3,color: Color,reach: float,energy: float):
	var light=OmniLight3D.new()
	light.position=at
	light.light_color=color
	light.omni_range=reach
	light.light_energy=energy
	add_child(light)

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
					box(self,at+Vector3(side*1.2,1.45,.05),Vector3(.65,.7,.12),warm if night else Color("8fdcf2"),false,2.4 if night else 0.0)
					box(self,at+Vector3(side*1.2,1.05,.14),Vector3(.8,.14,.2),Color("ff6b57"))
				for i in range(6): box(self,at+Vector3(-2.9+i*1.15,.35,1.7),Vector3(.14,.7,.14),Color("fff5dc"))
				box(self,at+Vector3(0,.5,1.7),Vector3(6.2,.1,.08),Color("fff5dc"))
				if night: lamp(at+Vector3(0,1.6,1.2),warm,7,1.6)
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
					var crystal=cylinder(self,spot,.22,.9,Color("ffd23f"),false,0,true,1.8 if night else .25)
					crystal.rotation.z=.2
				if night: lamp(at+Vector3(0,1,0),Color("ffd23f"),6,1.2)
				if restored_garden:
					for i in range(12): sphere(self,at+Vector3(sin(i)*2,.3,cos(i)*2),.18,Color("ff9ec7"))
			"encounter":
				var crab=Node3D.new()
				add_child(crab)
				crab.position=at
				creature=crab
				var shell=sphere(crab,Vector3(0,.6,0),.65,Color("ff9a3d"))
				shell.scale=Vector3(1.2,.8,1)
				for side in [-1,1]:
					sphere(crab,Vector3(side*.9,.6,.3),.3,Color("ff7a3d"))
					sphere(crab,Vector3(side*.25,.95,.5),.13,Color("ffffff"))
					sphere(crab,Vector3(side*.25,.97,.6),.06,Color("1d2a4d"),false)
					for leg in range(3): box(crab,Vector3(side*.65,.18,leg*.3-.3),Vector3(.7,.12,.12),Color("d9622b"))
			"camp":
				for i in range(8): sphere(self,at+Vector3(sin(i*TAU/8)*.8,.1,cos(i*TAU/8)*.8),.2,Color("9aa3b5"))
				flame=cylinder(self,at+Vector3(0,.5,0),.36,1.0,Color("ff8a2b"),false,0,false,2.6)
				cylinder(self,at+Vector3(0,.4,0),.2,.7,Color("ffe07a"),false,0,false,3.0)
				for i in range(3): box(self,at+Vector3(sin(i*2.1)*.35,.12,cos(i*2.1)*.35),Vector3(.9,.16,.16),Color("8a5a2b")).rotation.y=i*2.1
				prism(self,at+Vector3(-3.6,.7,-2.2),Vector3(1.9,1.4,2.3),Color("ffd23f")).rotation.y=.5
				lamp(at+Vector3(0,1,0),Color("ffb668"),10 if night else 5,2.6 if night else 1.0)
			"dock":
				for i in range(9): box(self,at+Vector3(0,.12,i*.6),Vector3(2,.2,.52),Color("c9975a"),true)
				for i in [0,4,8]:
					for side in [-1,1]: cylinder(self,at+Vector3(side*1.05,.1,i*.6),.12,1.6,Color("8a5a2b"))
				cylinder(self,at+Vector3(1.05,1.25,4.8),.2,.34,warm,false,-1.0,true,3.0 if night else .4)
				if night: lamp(at+Vector3(1.05,1.5,4.8),warm,7,1.5)
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
		if occupied or absf(at.z)<2: continue
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
		if kind<2:
			sphere(self,at+Vector3(0,.35,0),.6,Color("39b85e")).scale.y=.75
			sphere(self,at+Vector3(.5,.25,.2),.42,Color("4fc96a"))
		elif kind==2:
			var rock=sphere(self,at+Vector3(0,.2,0),.55,Color("aab3c5"))
			rock.scale=Vector3(1.2,.6,.9)
			rock.rotation.y=random.randf()*TAU
		else:
			cylinder(self,at+Vector3(0,.16,0),.025,.32,Color("2fae5d"),false,-1.0,false)
			sphere(self,at+Vector3(0,.36,0),.11,petals[i%petals.size()],false,.9 if night and i%4==0 else 0.0)
	for i in range(14):
		var angle=random.randf()*TAU
		var far=random.randf_range(70,150)
		var cloud=Node3D.new()
		cloud.position=Vector3(cos(angle)*far,random.randf_range(24,44),sin(angle)*far)
		add_child(cloud)
		var tint=Color("3a3466") if night else Color("ffffff")
		for puff in range(4):
			var ball=sphere(cloud,Vector3(puff*4.2-6.3,sin(puff*1.7)*1.1,cos(puff*2.3)*1.5),random.randf_range(3.2,5.2),tint,false)
			ball.scale.y=.55
			ball.material_override=cloud_material(tint)
			ball.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		clouds.append(cloud)

func cloud_material(color: Color) -> StandardMaterial3D:
	var key=["cloud",color]
	if materials.has(key): return materials[key]
	var m=StandardMaterial3D.new()
	m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color=color
	m.disable_fog=true
	materials[key]=m
	return m

func loop_and_play(animator: AnimationPlayer,animation: String,speed: float=1.0):
	if animator==null or not animator.has_animation(animation): return
	animator.get_animation(animation).loop_mode=Animation.LOOP_LINEAR
	if animator.current_animation!=animation: animator.play(animation,.18)
	animator.speed_scale=speed

## An animated KayKit adventurer (CC0), toon shaded with the shared ink outline.
## Falls back to the old block figure if the model is missing.
func make_character(kind: String,held_items: Array) -> Node3D:
	var path="res://assets/characters/%s.glb" % kind
	if not ResourceLoader.exists(path): return make_person(Color("39738c"))
	var model=load(path).instantiate()
	model.scale=Vector3.ONE*.8
	for slot in model.find_children("handslot_*","BoneAttachment3D",true,false):
		for item in slot.get_children(): item.visible=held_items.has(String(item.name))
	for part in model.find_children("*","MeshInstance3D",true,false):
		for i in range(part.mesh.get_surface_count()):
			var source=part.mesh.surface_get_material(i)
			var key=["character",source]
			if not materials.has(key):
				var toon=source.duplicate() if source is BaseMaterial3D else StandardMaterial3D.new()
				toon.diffuse_mode=BaseMaterial3D.DIFFUSE_TOON
				toon.specular_mode=BaseMaterial3D.SPECULAR_DISABLED
				toon.roughness=1.0
				toon.metallic=0.0
				toon.next_pass=ink
				materials[key]=toon
			part.set_surface_override_material(i,materials[key])
	return model

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
	companion=Node3D.new()
	add_child(companion)
	var colors={"fire":Color("ff9a3d"),"water":Color("58c6ee"),"earth":Color("7edc6a"),"air":Color("d9c2ff")}
	sphere(companion,Vector3(0,.3,0),.3,colors[element],true,.6 if night else 0.0)
	for side in [-1,1]:
		cylinder(companion,Vector3(side*.16,.58,0),.1,.32,colors[element],false,0)
		sphere(companion,Vector3(side*.1,.4,.25),.07,Color("ffffff"),false)
		sphere(companion,Vector3(side*.1,.4,.3),.035,Color("1d2a4d"),false)
	if night:
		var glow=OmniLight3D.new()
		glow.light_color=colors[element]
		glow.omni_range=3.5
		glow.light_energy=.8
		glow.position=Vector3(0,.5,0)
		companion.add_child(glow)
	companion.position=player.position+Vector3(1,0,1)

func _process(delta):
	clock+=delta
	for cloud in clouds:
		cloud.position.x+=delta*.6
		if cloud.position.x>160: cloud.position.x=-160
	if is_instance_valid(flame): flame.scale=Vector3.ONE*(1.0+.08*sin(clock*11.0)+.05*sin(clock*17.0))
	if is_instance_valid(creature):
		creature.position.y=landmarks.encounter.y+.07*absf(sin(clock*2.2))
		creature.rotation.y=.25*sin(clock*.8)

func input_event(event):
	if event is InputEventKey:
		if not event.pressed: held.erase(event.keycode)
		elif not event.echo:
			held[event.keycode]=true
			if event.keycode==KEY_SPACE: jump_queued=true
			if event.keycode==KEY_E and not current_landmark.is_empty(): interact_requested.emit(current_landmark)
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
	if player==null: return
	var axis=Vector2(float(held.has(KEY_D) or held.has(KEY_RIGHT))-float(held.has(KEY_A) or held.has(KEY_LEFT)),float(held.has(KEY_S) or held.has(KEY_DOWN))-float(held.has(KEY_W) or held.has(KEY_UP))).normalized()
	# Automatic orbit must not rotate the movement basis every frame: holding
	# sideways would otherwise make the player run in circles as the camera follows.
	if not axis.is_equal_approx(previous_axis) or orbiting:
		movement_yaw=yaw
	previous_axis=axis
	var movement=Basis(Vector3.UP,movement_yaw)*Vector3(axis.x,0,axis.y)
	manual_camera_grace=maxf(0,manual_camera_grace-delta)
	var speed=RUN if held.has(KEY_SHIFT) else WALK
	player.velocity.x=move_toward(player.velocity.x,movement.x*speed,24*delta)
	player.velocity.z=move_toward(player.velocity.z,movement.z*speed,24*delta)
	if not player.is_on_floor(): player.velocity.y-=GRAVITY*delta
	elif jump_queued: player.velocity.y=JUMP
	jump_queued=false
	player.move_and_slide()
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
	follow.y=ground_height(follow.x,follow.z)+.14+.1*sin(clock*3.0)
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

