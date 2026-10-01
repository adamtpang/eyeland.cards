extends Node
## Island ambience, synthesized in code (no recordings): sea wash all day, birdsong by day,
## crickets at night, and footsteps, jumps and landings for the hero.
const RATE=22050
var muted=false
var night_mix=0.0
var waves: AudioStreamPlayer
var crickets: AudioStreamPlayer
var chirps: Array=[]
var step_sounds: Array=[]
var land_sound: AudioStreamWAV
var jump_sound: AudioStreamWAV
var chime_sound: AudioStreamWAV
var next_chirp=2.0
var last_cue=""
var counts={}  # how many times each cue has been asked for
var random=RandomNumberGenerator.new()

func pcm(seconds: float,sample: Callable,looped: bool=false) -> AudioStreamWAV:
	var count=int(RATE*seconds)
	var bytes=PackedByteArray()
	bytes.resize(count*2)
	for i in range(count):
		bytes.encode_s16(i*2,int(clampf(sample.call(float(i)/RATE,i),-1,1)*32767))
	var stream=AudioStreamWAV.new()
	stream.format=AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate=RATE
	stream.data=bytes
	if looped:
		stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
		stream.loop_end=count
	return stream

func looping(stream: AudioStreamWAV,db: float) -> AudioStreamPlayer:
	var player=AudioStreamPlayer.new()
	player.stream=stream
	player.volume_db=db
	add_child(player)
	return player

static var bank: Dictionary={}  # synthesized once per run, reused each time the island loads

func _ready():
	random.seed=5
	if bank.is_empty(): synthesize()
	waves=looping(bank.waves,-17)
	crickets=looping(bank.crickets,-80)
	chirps=bank.chirps
	step_sounds=bank.steps
	jump_sound=bank.jump
	land_sound=bank.land
	chime_sound=bank.chime
	waves.play()
	crickets.play()
	apply_volume()

func synthesize():
	var state={"low":0.0,"lower":0.0}
	# Sea wash: low-passed noise that swells and fades twice over a six second loop.
	var wash=func(t: float,_i: int) -> float:
		state.low=lerpf(state.low,random.randf_range(-1,1),.09)
		state.lower=lerpf(state.lower,state.low,.2)
		var swell=.35+.65*pow(sin(PI*t/3.0),2)
		return state.lower*swell*2.2
	bank.waves=pcm(6.0,wash,true)
	# Crickets: a steady pulse of short high chirps.
	var cricket=func(t: float,_i: int) -> float:
		var beat=fmod(t,.5)
		var pulse=0.0
		for k in range(3):
			var at=beat-k*.07
			if at>=0 and at<.035: pulse=sin(PI*at/.035)
		return sin(TAU*4300*t)*pulse*.25
	bank.crickets=pcm(2.0,cricket,true)
	bank.chirps=[]
	bank.steps=[]
	# Birdsong: a few different short trills, played at random by day.
	for shape in [[2600.0,3400.0,3],[3100.0,2500.0,2],[3600.0,4200.0,4]]:
		var trill=func(t: float,_i: int) -> float:
			var note=fmod(t,.11)
			if t>=shape[2]*.11 or note>.075: return 0.0
			var pitch=lerpf(shape[0],shape[1],note/.075)
			return sin(TAU*pitch*t)*sin(PI*note/.075)*.3
		bank.chirps.append(pcm(shape[2]*.11+.05,trill))
	# Footsteps: soft thuds at slightly different pitches.
	for pitch in [150.0,170.0,135.0]:
		var thud=func(t: float,_i: int) -> float:
			return (sin(TAU*pitch*t*(1.0-t*2.2))*.7+random.randf_range(-1,1)*.35)*exp(-t*38)
		bank.steps.append(pcm(.12,thud))
	bank.jump=pcm(.16,func(t: float,_i: int) -> float: return sin(TAU*(260+900*t)*t)*exp(-t*14)*.4)
	bank.land=pcm(.2,func(t: float,_i: int) -> float: return (sin(TAU*95*t)*.8+random.randf_range(-1,1)*.4)*exp(-t*24))
	bank.chime=pcm(.5,func(t: float,_i: int) -> float: return (sin(TAU*880*t)+.6*sin(TAU*1320*t))*exp(-t*7)*.3)

func apply_volume():
	if not is_instance_valid(waves): return
	waves.volume_db=-80.0 if muted else -17.0
	crickets.volume_db=-80.0 if muted or night_mix<.05 else lerpf(-40.0,-21.0,night_mix)

func set_night_mix(value: float):
	night_mix=value
	apply_volume()

func set_muted(value: bool):
	muted=value
	apply_volume()

func play(stream: AudioStreamWAV,db: float,cue: String):
	last_cue=cue
	counts[cue]=counts.get(cue,0)+1
	if muted or stream==null: return
	var player=AudioStreamPlayer.new()
	player.stream=stream
	player.volume_db=db
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func footstep(): play(step_sounds[random.randi()%step_sounds.size()],-13,"step")
func jump(): play(jump_sound,-15,"jump")
func land(): play(land_sound,-11,"land")
func chime(): play(chime_sound,-14,"chime")

func _process(delta):
	next_chirp-=delta
	if next_chirp<=0:
		next_chirp=random.randf_range(2.5,7.0)
		if night_mix<.4: play(chirps[random.randi()%chirps.size()],-20,"bird")
