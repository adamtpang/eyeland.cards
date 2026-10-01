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

func material(color: Color) -> StandardMaterial3D:
	var m=StandardMaterial3D.new()
	m.albedo_color=color
	m.roughness=.88
	return m

func mesh_at(parent: Node3D, mesh: Mesh, at: Vector3, color: Color, collision=false) -> MeshInstance3D:
	var instance=MeshInstance3D.new()
	instance.mesh=mesh
	instance.material_override=material(color)
	instance.position=at
	parent.add_child(instance)
	if collision: instance.create_trimesh_collision()
	return instance

func box(parent: Node3D,at: Vector3,dimensions: Vector3,color: Color,collision=false):
	var mesh=BoxMesh.new()
	mesh.size=dimensions
	return mesh_at(parent,mesh,at,color,collision)

func sphere(parent: Node3D,at: Vector3,radius: float,color: Color):
	var mesh=SphereMesh.new()
	mesh.radius=radius
	mesh.height=radius*2
	mesh.radial_segments=12
	mesh.rings=6
	return mesh_at(parent,mesh,at,color)

func cylinder(parent: Node3D,at: Vector3,radius: float,height: float,color: Color,collision=false,top=-1.0):
	var mesh=CylinderMesh.new()
	mesh.top_radius=radius if top<0 else top
	mesh.bottom_radius=radius
	mesh.height=height
	mesh.radial_segments=10
	return mesh_at(parent,mesh,at,color,collision)

func _ready():
	var environment=WorldEnvironment.new()
	var env=Environment.new()
	env.background_mode=Environment.BG_COLOR
	env.background_color=Color("91bcc8")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color("c3d6df")
	env.ambient_light_energy=.35
	env.tonemap_mode=Environment.TONE_MAPPER_LINEAR
	environment.environment=env
	add_child(environment)
	var sun=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-48,-35,0)
	sun.light_color=Color("ffe5b4")
	sun.light_energy=.8
	sun.shadow_enabled=true
	add_child(sun)
	build_terrain()
	build_landmarks()
	build_trees()
	build_player()
	pivot=Node3D.new()
	add_child(pivot)
	arm=SpringArm3D.new()
	arm.spring_length=7.5
	arm.margin=.3
	arm.add_excluded_object(player.get_rid())
	pivot.add_child(arm)
	camera=Camera3D.new()
	camera.fov=65.0
	camera.far=240
	camera.current=true
	arm.add_child(camera)
	pivot.position=player.position+Vector3(0,1.5,0)
	pivot.rotation=Vector3(pitch,yaw,0)


func build_terrain():
	var surface=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in range(-38,38):
		for z in range(-31,31):
			for offset in [Vector2(0,0),Vector2(1,0),Vector2(0,1),Vector2(1,0),Vector2(1,1),Vector2(0,1)]:
				var at=Vector3(x+offset.x,0,z+offset.y)
				at.y=ground_height(at.x,at.z)
				var edge=sqrt(pow(at.x/35,2)+pow(at.z/28,2))
				var color=Color("d3be88") if edge>.84 else Color("7b9c61")
				if at.y>1.5: color=Color("64835c")
				surface.set_color(color.lightened(absf(sin(at.x*41+at.z*71))*.07))
				surface.add_vertex(at)
	surface.generate_normals()
	var terrain=MeshInstance3D.new()
	terrain.mesh=surface.commit()
	var mat=StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo=true
	mat.roughness=1
	terrain.material_override=mat
	add_child(terrain)
	terrain.create_trimesh_collision()
	var water=PlaneMesh.new()
	water.size=Vector2(240,240)
	var sea=mesh_at(self,water,Vector3(0,-.5,0),Color("398aa2"))
	sea.material_override.roughness=.3
	# Paths follow terrain height and remain non-colliding ground markings.
	for pair in [[Vector3(-18,0,0),landmarks.home],[landmarks.home,landmarks.friend],[landmarks.friend,landmarks.crop],[landmarks.crop,landmarks.encounter],[landmarks.crop,landmarks.camp],[landmarks.camp,landmarks.dock]]:
		var distance=pair[0].distance_to(pair[1])
		for i in range(int(distance/.7)+1):
			var at=pair[0].lerp(pair[1],float(i)/maxf(1,int(distance/.7)))
			at.y=ground_height(at.x,at.z)+.02
			cylinder(self,at,1.0,.03,Color("c5b588"))

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

func build_landmarks():
	for id in landmarks:
		var at=landmarks[id]
		at.y=ground_height(at.x,at.z)
		landmarks[id]=at
		match id:
			"home":
				box(self,at+Vector3(0,1.3,-1.5),Vector3(4,2.6,3),Color("edd9b3"),true)
				var roof=cylinder(self,at+Vector3(0,3,-1.5),3,1.6,Color("a7674e"),false,0)
				roof.rotation.y=PI/4
				box(self,at+Vector3(0,.9,.03),Vector3(.9,1.8,.12),Color("665345"))
				for side in [-1,1]: box(self,at+Vector3(side*1.2,1.45,.05),Vector3(.65,.7,.12),Color("7ebbc3"))
			"friend":
				var npc=make_person(Color("967db1"))
				add_child(npc)
				npc.position=at
			"crop":
				for i in range(7):
					var spot=at+Vector3(sin(i*2.4)*1.5,.3,cos(i*2.4)*1.5)
					var crystal=cylinder(self,spot,.22,.9,Color("e8b84f"),false,0)
					crystal.rotation.z=.2
				if restored_garden:
					for i in range(12): sphere(self,at+Vector3(sin(i)*2,.3,cos(i)*2),.18,Color("ecc4db"))
			"encounter":
				var crab=Node3D.new()
				add_child(crab)
				crab.position=at
				var shell=sphere(crab,Vector3(0,.6,0),.65,Color("e7a44e"))
				shell.scale=Vector3(1.2,.8,1)
				for side in [-1,1]:
					sphere(crab,Vector3(side*.9,.6,.3),.3,Color("dd934a"))
					sphere(crab,Vector3(side*.25,.75,.55),.10,Color("243b41"))
					for leg in range(3): box(crab,Vector3(side*.65,.18,leg*.3-.3),Vector3(.7,.12,.12),Color("a96b3f"))
			"camp":
				for i in range(8): sphere(self,at+Vector3(sin(i*TAU/8)*.8,.1,cos(i*TAU/8)*.8),.2,Color("81877a"))
				cylinder(self,at+Vector3(0,.45,0),.35,.9,Color("ffb357"),false,0)
				var light=OmniLight3D.new()
				light.position=at+Vector3(0,1,0)
				light.light_color=Color("ffb668")
				light.omni_range=5
				add_child(light)
			"dock":
				for i in range(9): box(self,at+Vector3(0,.12,i*.6),Vector3(2,.2,.52),Color("ae8b5d"),true)
	# Jumpable stepping stones create an optional exploration loop.
	for i in range(5):
		var at=Vector3(-7+i*1.5,0,4)
		at.y=ground_height(at.x,at.z)+.3+i*.12
		box(self,at,Vector3(1.1,.5+i*.24,1.1),Color("859080"),true)


func build_trees():
	var random=RandomNumberGenerator.new()
	random.seed=47
	for i in range(55):
		var at=Vector3(random.randf_range(-29,29),0,random.randf_range(-22,22))
		if sqrt(pow(at.x/35,2)+pow(at.z/28,2))>.83: continue
		var occupied=false
		for mark in landmarks.values():
			if at.distance_to(Vector3(mark.x,0,mark.z))<4.5: occupied=true
		if occupied or absf(at.z)<2: continue
		at.y=ground_height(at.x,at.z)
		cylinder(self,at+Vector3(0,1.2,0),.24,2.4,Color("78634a"),true)
		for layer in range(3): cylinder(self,at+Vector3(0,2.3+layer*.8,0),1.5-layer*.3,2,Color("3e7759").lightened(layer*.07),false,0)

func make_person(color: Color) -> Node3D:
	var person=Node3D.new()
	box(person,Vector3(0,1.05,0),Vector3(.62,.7,.4),color)
	sphere(person,Vector3(0,1.63,0),.25,Color("e4bd8b"))
	var hair=sphere(person,Vector3(0,1.79,-.035),.24,Color("584b3e"))
	hair.scale.y=.65
	for x in [-.09,.09]: sphere(person,Vector3(x,1.64,.225),.026,Color("26373b"))
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
	avatar=make_person(Color("39738c"))
	player.add_child(avatar)
	avatar.rotation.y=PI
	player.position=spawn_position
	player.position.y=maxf(player.position.y,ground_height(player.position.x,player.position.z)+.1)
	last_safe=player.position
	companion=Node3D.new()
	add_child(companion)
	var colors={"fire":Color("e7a34f"),"water":Color("74bed0"),"earth":Color("8cac6c"),"air":Color("d6c5dc")}
	sphere(companion,Vector3(0,.3,0),.28,colors[element])
	for side in [-1,1]:
		cylinder(companion,Vector3(side*.16,.56,0),.1,.32,colors[element],false,0)
		sphere(companion,Vector3(side*.09,.4,.24),.035,Color("253944"))
	companion.position=player.position+Vector3(1,0,1)

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
	follow.y=ground_height(follow.x,follow.z)
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

