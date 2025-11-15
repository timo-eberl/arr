@tool
class_name Water
extends MeshInstance3D

@export var water_material : ShaderMaterial

const MAX_SPLASHES = 64
const MAX_FOAM = 64 # Can be a different value from splashes if needed

var splash_index = 0
var foam_index = 0

# Uniform arrays to send to shader for splashes (vertex displacement)
var splash_positions = []
var splash_times = []

# Uniform arrays to send to shader for foam (surface texture)
var foam_positions = []
var foam_times = []

func _ready():
	# Initialize splash arrays
	splash_positions.resize(MAX_SPLASHES)
	splash_times.resize(MAX_SPLASHES)
	splash_positions.fill(Vector3.ZERO)
	splash_times.fill(-100.0) # Negative time means "not active"

	# Initialize foam arrays
	foam_positions.resize(MAX_FOAM)
	foam_times.resize(MAX_FOAM)
	foam_positions.fill(Vector3.ZERO)
	foam_times.fill(-100.0) # Negative time means "not active"

func _process(_delta: float) -> void:
	var time_ms := Time.get_ticks_msec()
	if water_material:
		water_material.set_shader_parameter("time_ms", time_ms)
	else:
		push_error("water material not set")

func add_splash(position_xyz: Vector3):
	"""Adds a splash that affects the water's height (vertex displacement)."""
	var mat = get_active_material(0) as ShaderMaterial
	if not mat: return
	
	# Update the ring buffer for splashes
	splash_positions[splash_index] = position_xyz
	splash_times[splash_index] = Time.get_ticks_msec() / 1000.0
	
	# Send splash arrays to shader
	mat.set_shader_parameter("splash_positions", splash_positions)
	mat.set_shader_parameter("splash_start_times", splash_times)
	
	# Move index for next splash
	splash_index = (splash_index + 1) % MAX_SPLASHES

func add_foam(position_xyz: Vector3):
	"""Adds a foam effect on the water's surface."""
	var mat = get_active_material(0) as ShaderMaterial
	if not mat: return
	
	# Update the ring buffer for foam
	foam_positions[foam_index] = position_xyz
	foam_times[foam_index] = Time.get_ticks_msec() / 1000.0
	
	# Send foam arrays to shader
	mat.set_shader_parameter("foam_positions", foam_positions)
	mat.set_shader_parameter("foam_start_times", foam_times)
	
	# Move index for next foam instance
	foam_index = (foam_index + 1) % MAX_FOAM

# Example usage: Create a splash and foam when clicking
func _input(event):
	if event is InputEventMouseButton and event.pressed:
		# In a real game, you would get this position from a raycast
		var impact_position = Vector3(0, 0, 0) 
		
		# You can now call them together or separately
		add_splash(impact_position)
		add_foam(impact_position)
