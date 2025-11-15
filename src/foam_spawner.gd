extends Node3D

@onready var water : Water = $"../../Water"
@export var time_diff := 0.1

func _ready() -> void:
	while true:
		water.add_foam(self.global_position)
		await get_tree().create_timer(time_diff).timeout
