extends Node3D

func height(xz: Vector2) -> float:
	var time_ms := Time.get_ticks_msec()
	return ((sin(xz.y * 0.3 + time_ms * 0.001)) * 1.0) \
		+ ((sin(-xz.x * 0.2 + time_ms * 0.001)) * 0.5);

func _process(_delta: float) -> void:
	var global_2d := Vector2(self.global_position.x, self.global_position.z)
	self.global_position.y = height(global_2d)
