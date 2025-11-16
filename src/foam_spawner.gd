extends Node3D

@onready var water : Water = $"../../Water"
@export var time_diff_from := 1.0
@export var time_diff_to := 0.2
@onready var ship : Ship = $".."

func _ready() -> void:
	while true:
		var time_diff := remap(abs(ship.linear_velocity.length()), 0.0, 17.0, time_diff_from, time_diff_to)
		water.add_foam(self.global_position, 12.0)
		await get_tree().create_timer(time_diff).timeout
