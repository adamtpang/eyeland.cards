extends Node
## Original synthesized prototype cues; no third-party recordings.
var muted=false
var streams={}
var last_battle
var log_cursor=0
var result_played=false
var last_cue=""
var hit_streams={}
const HIT_DB={"hit_snap":-7.0,"hit_heavy":-3.0,"hit_slash":-8.0}

func _ready():
	for kind in ["play","attack","secret","victory","defeat","draw"]: streams[kind]=make_cue(kind)

func make_cue(kind: String) -> AudioStreamWAV:
	var notes={"play":[440.0,660.0],"attack":[140.0,70.0],"secret":[600.0,900.0,1200.0],"victory":[392.0,494.0,587.0,784.0],"defeat":[294.0,247.0,196.0],"draw":[330.0,330.0]}[kind]
	var rate=22050
	var note_time=.085 if kind not in ["victory","defeat","draw"] else .14
	var samples=int(rate*note_time*notes.size())
	var bytes=PackedByteArray(); bytes.resize(samples*2)
	for i in range(samples):
		var t=float(i)/rate
		var n=mini(int(t/note_time),notes.size()-1)
		var phase=fmod(t,note_time)/note_time
		var envelope=sin(PI*phase)*exp(-phase*2.0)
		var wave=sin(TAU*notes[n]*t)+.2*sin(TAU*notes[n]*2*t)
		bytes.encode_s16(i*2,int(clampf(wave*envelope*.35,-1,1)*32767))
	var stream=AudioStreamWAV.new()
	stream.format=AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate=rate
	stream.data=bytes
	return stream

## Synthesized impact cues for the attack-feel variations (see hit_feel.gd).
func make_hit(kind: String) -> AudioStreamWAV:
	var rate=22050
	var seconds={"hit_snap":.14,"hit_heavy":.5,"hit_slash":.36}[kind]
	var samples=int(rate*seconds)
	var bytes=PackedByteArray(); bytes.resize(samples*2)
	var rng=RandomNumberGenerator.new(); rng.seed=7
	var low=0.0
	var phase=0.0
	for i in range(samples):
		var t=float(i)/rate
		var noise=rng.randf_range(-1,1)
		var wave=0.0
		if kind=="hit_snap":
			# sharp click plus a short falling thud
			phase+=TAU*lerpf(240.0,95.0,minf(1.0,t/.09))/rate
			wave=sin(phase)*exp(-t*26)*.9+noise*exp(-t*130)*.7
		elif kind=="hit_heavy":
			# deep falling boom with a crunch on the front and a long tail
			phase+=TAU*lerpf(110.0,36.0,minf(1.0,t/.3))/rate
			low=lerpf(low,noise,.12)
			wave=sin(phase)*exp(-t*7)+.35*sin(phase*2)*exp(-t*14)+low*exp(-t*22)*1.4
		else:
			# airy swish that rises, then a bright ring on the hit at .16s
			low=lerpf(low,noise,.45)
			if t<.16: wave=(noise-low)*sin(PI*t/.16)*.5
			else: wave=(sin(TAU*1320*t)+.6*sin(TAU*1980*t)+.3*sin(TAU*2640*t))*exp(-(t-.16)*16)*.45
		bytes.encode_s16(i*2,int(clampf(wave*.6,-1,1)*32767))
	var stream=AudioStreamWAV.new()
	stream.format=AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate=rate
	stream.data=bytes
	return stream

func play_cue(kind: String):
	last_cue=kind
	if muted: return
	if HIT_DB.has(kind) and not hit_streams.has(kind): hit_streams[kind]=make_hit(kind)
	var stream=streams.get(kind,hit_streams.get(kind))
	if stream==null: return
	var player=AudioStreamPlayer.new()
	player.stream=stream
	player.volume_db=HIT_DB.get(kind,-12.0)
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func observe(battle,presentation_managed: bool=false):
	if battle!=last_battle:
		last_battle=battle; log_cursor=0; result_played=false
	var recent=battle.log.slice(log_cursor)
	log_cursor=battle.log.size()
	if not presentation_managed and battle.outcome!=-1 and not result_played:
		result_played=true
		play_cue("draw" if battle.outcome==2 else ("victory" if battle.outcome==0 else "defeat"))
		return
	var cue=""
	for line in recent:
		if not presentation_managed and "Secret revealed:" in line: cue="secret"
		elif not presentation_managed and cue!="secret" and "attacks" in line: cue="attack"
		elif cue.is_empty() and ("play " in line or "plays " in line): cue="play"
	if not cue.is_empty(): play_cue(cue)

func present_result(battle):
	if battle!=last_battle:
		last_battle=battle; result_played=false
	if battle.outcome==-1 or result_played: return
	result_played=true
	play_cue("draw" if battle.outcome==2 else ("victory" if battle.outcome==0 else "defeat"))

func toggle():
	muted=not muted
	if muted:
		for player in get_children():
			player.stop()
			player.stream=null
			player.queue_free()

func _exit_tree():
	for player in get_children():
		player.stop()
		player.stream=null
	streams.clear()
	hit_streams.clear()
	last_battle=null
