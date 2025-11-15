class_name CameraController
extends Node3D

@onready var camera_look_at : Node3D = $"../../CameraLookAt"
@onready var camera : Node3D = $"../../CameraLookAt/Camera3D"

var target_cam_distance := 80.0

func _physics_process(delta) -> void:
	camera_look_at.global_position = lerp(
		camera_look_at.global_position, self.global_position, delta * 2.0
	)
	
	camera.position.z = lerp(camera.position.z, target_cam_distance, delta * 0.5)
