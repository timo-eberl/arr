extends Area3D

@onready var collected_treasure_parent : Node3D = $"../../CollectedTreasure"
@onready var treasure_spawn : Marker3D = $"../TreasureSpawn"
@onready var ship_body : RigidBody3D = $".."

var gold_sounds = ["res://Sounds/gold1.wav", "res://Sounds/gold2.wav", "res://Sounds/gold3.wav", "res://Sounds/gold4.wav"]

func _on_area_entered(area: Area3D) -> void:
	if area is CollectableTreasure:
		#var rb := RigidBody3D.new()
		#collected_treasure_parent.add_child(rb)
		#rb.global_position = treasure_spawn.global_position
		#for child in area.get_children():
			#child.get_parent().remove_child(child)
			#rb.add_child(child)
		var collected : RigidBody3D = area.collected_variant.instantiate()
		collected_treasure_parent.add_child(collected)
		collected.global_position = treasure_spawn.global_position
		
		area.queue_free()

		var gold_sound_player: AudioStreamPlayer = AudioStreamPlayer.new()
		gold_sound_player.stream = load(gold_sounds.pick_random())
		get_tree().root.add_child(gold_sound_player)
		#gold_sound_player.position = global_position
		gold_sound_player.volume_db = -12
		gold_sound_player.play()
		
		DynamicMusic.update(collected_treasure_parent, $"../../MusicPlayer")

		# Free sound player once it finished playing
		await gold_sound_player.finished
		gold_sound_player.queue_free()
