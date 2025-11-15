class_name RandomSoundPlayer
extends AudioStreamPlayer3D

@export var sounds : Array[AudioStream]

# This method selects a random sound from the 'sounds' array and plays it.
func play_sound():
	# Ensure the 'sounds' array is not empty to avoid errors.
	if not sounds.is_empty():
		# Pick a random AudioStream from the array.
		stream = sounds.pick_random()
		# Play the selected sound.
		play()
