@tool
class_name Water
extends MeshInstance3D

@export var water_material : ShaderMaterial

const MAX_SPLASHES = 32
const MAX_FOAM = 16

var splash_index = 0
var foam_index = 0

# Uniform arrays for splashes (vertex displacement)
var splash_positions = []
var splash_times = []

# Uniform arrays for foam (surface texture)
var foam_positions = []
var foam_times = []
var foam_sizes = [] # <-- NEW: Array to hold foam sizes

func _ready():
	# Initialize splash arrays
	splash_positions.resize(MAX_SPLASHES)
	splash_times.resize(MAX_SPLASHES)
	splash_positions.fill(Vector3.ZERO)
	splash_times.fill(-100.0)

	# Initialize foam arrays
	foam_positions.resize(MAX_FOAM)
	foam_times.resize(MAX_FOAM)
	foam_sizes.resize(MAX_FOAM) # <-- NEW: Resize the sizes array
	foam_positions.fill(Vector3.ZERO)
	foam_times.fill(-100.0)
	foam_sizes.fill(1.0) # <-- NEW: Fill with a default size

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
	
	splash_positions[splash_index] = position_xyz
	splash_times[splash_index] = Time.get_ticks_msec() / 1000.0
	
	mat.set_shader_parameter("splash_positions", splash_positions)
	mat.set_shader_parameter("splash_start_times", splash_times)
	
	splash_index = (splash_index + 1) % MAX_SPLASHES

# MODIFIED: Now accepts a 'size' parameter
func add_foam(position_xyz: Vector3, size: float = 8.0):
	"""Adds a foam effect on the water's surface with a specified size."""
	var mat = get_active_material(0) as ShaderMaterial
	if not mat: return
	
	# Update the ring buffers for foam
	foam_positions[foam_index] = position_xyz
	foam_times[foam_index] = Time.get_ticks_msec() / 1000.0
	foam_sizes[foam_index] = size # <-- NEW: Store the custom size
	
	# Send foam arrays to shader
	mat.set_shader_parameter("foam_positions", foam_positions)
	mat.set_shader_parameter("foam_start_times", foam_times)
	mat.set_shader_parameter("foam_sizes", foam_sizes) # <-- NEW: Send sizes to the shader
	
	foam_index = (foam_index + 1) % MAX_FOAM

# Example usage: Create a splash and foam with a specific size when clicking
func _input(event):
	if event is InputEventMouseButton and event.pressed:
		var impact_position = Vector3(0, 0, 0)
		
		add_splash(impact_position)
		# MODIFIED: Pass a custom size to the foam effect.
		add_foam(impact_position, 8.0) # This foam will be larger
