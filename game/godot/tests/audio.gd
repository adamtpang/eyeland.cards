extends SceneTree
var checks=0
var failed=0
func check(ok: bool,label: String):
	checks+=1
	if not ok: failed+=1; push_error(label)
func _initialize(): call_deferred("run")
func run():
	var sound=preload("res://battle_audio.gd").new(); root.add_child(sound)
	check(sound.streams.size()==6,"Six original cues generated")
	for stream in sound.streams.values():
		check(stream.data.size()>0 and stream.get_length()>0 and stream.mix_rate==22050,"Valid PCM stream")
	var b={"log":["You play Cinder Moth."],"outcome":-1}
	sound.observe(b)
	check(sound.last_cue=="play" and sound.get_child_count()==1,"Card play starts audio player")
	sound.observe(b)
	check(sound.get_child_count()==1,"Repeated render does not replay cue")
	sound.toggle(); await process_frame
	check(sound.muted and sound.get_child_count()==0,"Mute stops active audio")
	b.log.append("Hero attacks for 3."); sound.observe(b)
	check(sound.get_child_count()==0,"Muted actions produce no playback")
	sound.toggle(); b.log.append("Secret revealed: Pebble Ward."); sound.observe(b)
	check(sound.last_cue=="secret","Secret reveal uses its cue")
	b.outcome=2; sound.observe(b)
	check(sound.last_cue=="draw","Draw has distinct result cue")
	sound.toggle(); await process_frame
	sound.streams.clear()
	sound.queue_free(); await process_frame
	await create_timer(.1).timeout
	print("AUDIO: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
