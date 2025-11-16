class_name FloatingFluff
extends Node3D

func _physics_process(delta: float) -> void:
	var target_y := WaveHeight.height(
		Vector2(self.global_position.x, self.global_position.z)
	)
	if self.global_position.y < target_y and (target_y - self.global_position.y) > 1.0:
		self.global_position.y += delta * 5.0
	else:
		self.global_position.y = lerp(global_position.y, target_y, delta * 5)
	
	var target_normal := WaveHeight.calculateNormal(Vector2(global_position.x,global_position.z)).normalized()
	print("target_normal: ", target_normal)
	self.look_at(global_position + target_normal, Vector3.RIGHT)
