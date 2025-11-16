class_name CollectableTreasure
extends Area3D

@export var collected_variant : PackedScene

func _physics_process(delta: float) -> void:
	var target_y := WaveHeight.height(
		Vector2(self.global_position.x, self.global_position.z)
	)
	if self.global_position.y < target_y:
		self.global_position.y += delta * 3.0
