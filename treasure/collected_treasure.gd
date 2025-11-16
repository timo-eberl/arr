extends RigidBody3D

var splash_sounds = ["res://Sounds/splash1.wav", "res://Sounds/splash2.wav", "res://Sounds/splash3.wav", "res://Sounds/splash4.wav"]
var splash_sound_player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()

var sinking: bool = false

func _ready() -> void:
	splash_sound_player.stream = load(splash_sounds.pick_random())
	self.add_child(splash_sound_player)

func _process(_delta: float) -> void:
	if self.global_position.y < -10.0 && !self.sinking:
		self.sinking = true

		#splash_sound_player.position = self.global_position
		splash_sound_player.volume_db = -6
		splash_sound_player.play()

		await splash_sound_player.finished
		splash_sound_player.queue_free()

		queue_free()

		DynamicMusic.update($"../../CollectedTreasure", $"../../MusicPlayer")
