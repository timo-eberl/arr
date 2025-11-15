class_name CollectableTreasure
extends Area3D

@export var collected_variant : PackedScene

func _physics_process(_delta: float) -> void:
	self.global_position.y = Ship.height(
		Vector2(self.global_position.x, self.global_position.z)
	)
