extends Node
## Island ambience, synthesized in code (no recordings): sea wash all day, birdsong by day,
## crickets at night, footsteps, jumps and landings for the hero, and two short looping
## tunes (a bright one by day, a slow one at night) that crossfade with the look.
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
const MUSIC_RATE=16000
var day_music: AudioStreamPlayer
var night_music: AudioStreamPlayer
static var music_task=-1

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
	if not bank.has("waves"): synthesize()
	# The tunes take a few seconds to synthesize, so they are built once on a worker thread
	# and start when ready. Automated runs build them on request instead.
	if not bank.has("night_music") and music_task==-1 and not OS.get_cmdline_args().has("--script"):
		music_task=WorkerThreadPool.add_task(build_music)
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

## One note added into a looping buffer; tails wrap round so the loop has no seam.
static func note(buffer: PackedFloat32Array,start: float,seconds: float,midi: int,voice: String,gain: float):
	var total=buffer.size()
	var first=int(start*MUSIC_RATE)
	var w=TAU*440.0*pow(2.0,(midi-69)/12.0)/MUSIC_RATE
	var count=int((seconds+{"pluck":.5,"bass":.3,"bell":1.4,"pad":1.2}[voice])*MUSIC_RATE)
	if voice=="pluck":
		for i in range(count):
			var t=float(i)/MUSIC_RATE
			buffer[(first+i)%total]+=(sin(w*i)+.35*sin(2.0*w*i))*exp(-t*5.5)*gain
	elif voice=="bass":
		for i in range(count):
			var t=float(i)/MUSIC_RATE
			var hold=1.0 if t<seconds else exp(-(t-seconds)*12.0)
			buffer[(first+i)%total]+=(sin(w*i)+.2*sin(2.0*w*i))*minf(1.0,t*60.0)*exp(-t*1.6)*hold*gain
	elif voice=="bell":
		for i in range(count):
			var t=float(i)/MUSIC_RATE
			buffer[(first+i)%total]+=(sin(w*i)*exp(-t*2.6)+.45*sin(3.01*w*i)*exp(-t*7.0))*gain
	else:
		for i in range(count):
			var t=float(i)/MUSIC_RATE
			var shape=minf(1.0,t/.5)*(1.0 if t<seconds else maxf(0.0,1.0-(t-seconds)/1.2))
			buffer[(first+i)%total]+=(sin(w*i)+.5*sin(2.006*w*i)+.3*sin(.997*w*i))*shape*.5*gain

## Notes are [beat, length in beats, MIDI pitch, voice, gain].
static func song(bpm: float,beats: int,notes: Array) -> AudioStreamWAV:
	var beat=60.0/bpm
	var buffer=PackedFloat32Array()
	buffer.resize(int(beats*beat*MUSIC_RATE))
	for n in notes: note(buffer,n[0]*beat,n[1]*beat,n[2],n[3],n[4])
	var peak=0.001
	for value in buffer: peak=maxf(peak,absf(value))
	var bytes=PackedByteArray()
	bytes.resize(buffer.size()*2)
	for i in range(buffer.size()): bytes.encode_s16(i*2,int(buffer[i]/peak*.8*32767))
	var stream=AudioStreamWAV.new()
	stream.format=AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate=MUSIC_RATE
	stream.data=bytes
	stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
	stream.loop_end=buffer.size()
	return stream

static func build_music():
	# Day: eight bars in C major at 100 bpm. Bass, a plucked arpeggio and a bell melody.
	var day=[]
	var chords=[[48,60,64,67],[45,57,60,64],[41,53,57,60],[43,55,59,62],[48,60,64,67],[45,57,60,64],[41,53,57,60],[43,55,59,62]]
	for bar in range(8):
		var chord=chords[bar]
		day.append([bar*4,3.5,chord[0],"bass",.55])
		for eighth in range(8): day.append([bar*4+eighth*.5,.5,chord[1+[0,1,2,1,0,1,2,1][eighth]],"pluck",.3])
	var tune=[[0,1,76],[1,1,79],[2,2,81],[4,1,79],[5,1,76],[6,2,72],[8,1,77],[9,1,81],[10,2,84],[12,1,83],[13,1,81],[14,2,79],
		[16,1,76],[17,1,79],[18,2,84],[20,1,81],[21,1,79],[22,2,76],[24,1,77],[25,1,76],[26,1,74],[27,1,72],[28,2,74],[30,2,79]]
	for n in tune: day.append([n[0],n[1],n[2],"bell",.42])
	var day_stream=song(100.0,32,day)
	# Night: eight bars in A minor at 66 bpm. Slow pads, a low bass and a sparse bell line.
	var dark=[]
	var pads=[[45,57,60,64],[41,53,57,60],[48,55,60,64],[40,52,55,59],[45,57,60,64],[41,53,57,60],[38,50,53,57],[40,52,56,59]]
	for bar in range(8):
		var chord=pads[bar]
		dark.append([bar*4,4,chord[0],"bass",.4])
		for tone in chord.slice(1): dark.append([bar*4,3.6,tone,"pad",.3])
	var line=[[0,2,76],[2,2,81],[4,3,84],[7,1,81],[8,2,79],[10,2,76],[12,4,71],[16,2,76],[18,2,81],[20,3,84],[23,1,86],[24,2,81],[26,2,77],[28,4,80]]
	for n in line: dark.append([n[0],n[1],n[2],"bell",.34])
	var night_stream=song(66.0,32,dark)
	bank.day_music=day_stream
	bank.night_music=night_stream

func start_music():
	day_music=looping(bank.day_music,-80)
	night_music=looping(bank.night_music,-80)
	day_music.play()
	night_music.play()
	apply_volume()

func apply_volume():
	if not is_instance_valid(waves): return
	if is_instance_valid(day_music):
		day_music.volume_db=-80.0 if muted or night_mix>.95 else lerpf(-23.0,-55.0,night_mix)
		night_music.volume_db=-80.0 if muted or night_mix<.05 else lerpf(-55.0,-23.0,night_mix)
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
	if day_music==null and bank.has("night_music"): start_music()
	next_chirp-=delta
	if next_chirp<=0:
		next_chirp=random.randf_range(2.5,7.0)
		if night_mix<.4: play(chirps[random.randi()%chirps.size()],-20,"bird")
