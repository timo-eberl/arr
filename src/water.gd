@tool
extends MeshInstance3D

@export var water_material : ShaderMaterial

func _process(_delta: float) -> void:
	var time_ms := Time.get_ticks_msec()
	if water_material:
		water_material.set_shader_parameter("time_ms", time_ms)
	else:
		push_error("water material not set")
