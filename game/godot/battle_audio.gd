extends Node
## Original synthesized prototype cues; no third-party recordings.
var muted=false
var streams={}
var last_battle
var log_cursor=0
var result_played=false
var last_cue=""

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

func play_cue(kind: String):
	last_cue=kind
	if muted or not streams.has(kind): return
	var player=AudioStreamPlayer.new()
	player.stream=streams[kind]
	player.volume_db=-12
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
	last_battle=null
