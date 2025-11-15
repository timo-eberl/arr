extends Node3D

@onready var water : Water = $"../../Water"
@export var time_diff_from := 0.5
@export var time_diff_to := 0.05
@onready var ship : Ship = $"../../Ship"

func _ready() -> void:
	while true
		print(ship.speed)
		var time_diff := remap(abs(ship.speed), 0.0, 17.0, time_diff_from, time_diff_to)
		water.add_splash(self.global_position)
		await get_tree().create_timer(time_diff).timeout
