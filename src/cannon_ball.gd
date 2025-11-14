extends RigidBody3D

@export var life_time: float = 3.0

var _time_passed: float = 0.0

func _ready() -> void:
	linear_damp = 0.0
	angular_damp = 0.0

func _physics_process(delta: float) -> void:
	_time_passed += delta
	if _time_passed >= life_time:
		queue_free()
