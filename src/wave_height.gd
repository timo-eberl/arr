class_name WaveHeight
extends Node


# This static function calculates the 3D displacement (x, y, z) for a single Gerstner wave.
# A steepness of 0.0 makes it a simple sine wave.
# A steepness of 1.0 creates a very sharp crest.
static func _gerstner_wave_displacement(xz: Vector2, dir: Vector2, steepness: float, amp: float, freq: float, speed: float, time: float) -> Vector3:
	# Calculate the main wave function component
	var dot_product: float = dir.dot(xz) * freq + time * speed

	# Use cos for horizontal and sin for vertical displacement to create circular motion
	var s: float = sin(dot_product)
	var c: float = cos(dot_product)

	# Calculate the displacements
	# The x and z components create the horizontal movement, sharpening the peak.
	var dx: float = steepness * dir.x * amp * c
	var dz: float = steepness * dir.y * amp * c # dir.y corresponds to the Z axis
	# The y component is the standard vertical movement.
	var dy: float = amp * s

	return Vector3(dx, dy, dz)


# This function calculates the COMBINED VERTICAL HEIGHT of all waves for gameplay logic.
static func height(xz: Vector2) -> float:
	var time := Time.get_ticks_msec() / 1000.0
	var h: float = 0.0

	# --- Wave 1 ---
	var steepness_1 := 0.4      # How sharp the peak is (0=sine wave, 1=very sharp)
	var amp_1 := 0.5            # Amplitude: How high the wave is.
	var freq_1 := 0.3           # Frequency: How spread out the wave is.wa
	var speed_1 := 1.1          # Speed: How fast it moves.
	var dir_1 := Vector2(1.0, 0.6).normalized() # Direction of travel.

	# Calculate the first wave's full displacement vector
	var wave_1_disp: Vector3 = _gerstner_wave_displacement(xz, dir_1, steepness_1, amp_1, freq_1, speed_1, time)
	# Add its vertical component (y) to the total height
	h += wave_1_disp.y
	
	# --- Wave 2 ---
	var steepness_2 := 0.6      # A slightly sharper secondary wave
	var amp_2 := 0.9
	var freq_2 := 0.12
	var speed_2 := 0.9
	var dir_2 := Vector2(1.0, 1.1).normalized()

	# Calculate the second wave's full displacement vector
	var wave_2_disp: Vector3 = _gerstner_wave_displacement(xz, dir_2, steepness_2, amp_2, freq_2, speed_2, time)
	# Add its vertical component (y) to the total height
	h += wave_2_disp.y
	
	return h

static func calculateNormal(xz: Vector2) -> Vector3:
	# A small offset value to sample neighboring points
	var epsilon = 0.05;

	# Sample the height at the current point and at points slightly offset in x and z
	var h = WaveHeight.height(xz);
	var hx = WaveHeight.height(Vector2(xz.x + epsilon, xz.y));
	var hz = WaveHeight.height(Vector2(xz.x, xz.y + epsilon));

	# Create two tangent vectors
	var tangentX = Vector3(epsilon, hx - h, 0.0).normalized();
	var tangentZ = Vector3(0.0, hz - h, epsilon).normalized();

	# The normal is the cross product of the two tangents
	var normal = tangentZ.cross(tangentX);

	return normal;
