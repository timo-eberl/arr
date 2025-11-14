extends Node3D

@onready var camera_look_at : Node3D = $"../../CameraLookAt"

func _process(delta: float) -> void:
	camera_look_at.global_position = lerp(
		camera_look_at.global_position, self.global_position, delta * 2.0
	)
