extends AnimationPlayer

@export var animation := "sail_animation"

func _ready() -> void:
	play(animation)
