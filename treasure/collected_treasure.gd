extends RigidBody3D

func _process(_delta: float) -> void:
	if self.global_position.y < -10.0:
		queue_free()
