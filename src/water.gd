@tool
class_name Water
extends MeshInstance3D

@export var water_material : ShaderMaterial

const MAX_SPLASHES = 64
var splash_index = 0

# Uniform arrays to send to shader
var splash_positions = []
var splash_times = []

func _ready():
	# Initialize arrays
	splash_positions.resize(MAX_SPLASHES)
	splash_times.resize(MAX_SPLASHES)
	splash_positions.fill(Vector3.ZERO)
	splash_times.fill(-100.0) # Negative time means "not active"

func _process(_delta: float) -> void:
	var time_ms := Time.get_ticks_msec()
	if water_material:
		water_material.set_shader_parameter("time_ms", time_ms)
	else:
		push_error("water material not set")

func add_splash(position_xyz: Vector3):
	var mat = get_active_material(0) as ShaderMaterial
	if not mat: return
	
	# Update the ring buffer logic
	splash_positions[splash_index] = position_xyz
	splash_times[splash_index] = Time.get_ticks_msec() / 1000.0
	
	# Send arrays to shader
	mat.set_shader_parameter("splash_positions", splash_positions)
	mat.set_shader_parameter("splash_start_times", splash_times)
	
	# Move index for next splash
	splash_index = (splash_index + 1) % MAX_SPLASHES

# Example usage: Create a splash when clicking
func _input(event):
	if event is InputEventMouseButton and event.pressed:
		# Just for testing: Splash at center
		# In a real game, raycast from camera to water plane
		add_splash(Vector3(0, 0, 0))
