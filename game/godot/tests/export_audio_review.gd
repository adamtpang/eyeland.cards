extends SceneTree
## Export the actual runtime cue generator, at the runtime -12 dB volume.
func _initialize():
	var sound=preload("res://battle_audio.gd").new()
	var combined=PackedByteArray()
	var silence=PackedByteArray(); silence.resize(22050)
	var sequence=["play","attack","secret","victory","defeat","draw"]
	for kind in sequence:
		var stream=sound.make_cue(kind)
		var samples=stream.data.duplicate()
		for i in range(samples.size()/2): samples.encode_s16(i*2,int(samples.decode_s16(i*2)*db_to_linear(-12)))
		combined.append_array(samples); combined.append_array(silence)
	var review=AudioStreamWAV.new()
	review.format=AudioStreamWAV.FORMAT_16_BITS; review.mix_rate=22050; review.data=combined
	var path=ProjectSettings.globalize_path("res://../evidence/battle-cues-review.wav")
	var result=review.save_to_wav(path)
	sound.free()
	print("Audio review export: ",result," — ",sequence)
	quit(0 if result==OK else 1)
