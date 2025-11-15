extends RigidBody3D

var is_initialized := false

@export var forward_speed: float = 5.0
@export var turn_strength: float = 1.5

@export var target_container_path: NodePath 
@export var wait_at_target_time: float = 0.0
@export var arrival_distance: float = 3.0   

@onready var nav_agent: NavigationAgent3D = $NavAgent
@onready var target_container: Node3D = get_node_or_null(target_container_path)

var current_target: Node3D = null
var is_waiting: bool = false
var wait_timer: float = 0.0


func _ready() -> void:
	randomize()
	gravity_scale = 0.0
	linear_damp = 0.1
	angular_damp = 0.2

	add_to_group("enemy_ship")

	if target_container_path != NodePath(""):
		target_container = get_node_or_null(target_container_path)

	_pick_new_random_target()
	
	is_initialized = true
	
	if target_container != null:
		_pick_new_random_target()


func _physics_process(delta: float) -> void:

	var global_2d := Vector2(global_position.x, global_position.z)
	global_position.y = WaveHeight.height(global_2d)

	var normal = calculateNormal(global_2d)
	var myBasis = Basis()
	myBasis.y = normal.normalized()        # UP-Richtung setzen
	myBasis.x = myBasis.y.cross(-Vector3.FORWARD).normalized()
	myBasis.z = myBasis.x.cross(myBasis.y).normalized()

	var current_up = global_transform.basis.y
	var target_up = myBasis.y

	var rotation_axis = current_up.cross(target_up)
	var angle = current_up.angle_to(target_up)
	var up_strength = 0.25

	if rotation_axis.length() > 0.0001:
		angular_velocity = rotation_axis.normalized() * angle

	if is_waiting:
		wait_timer -= delta
		if wait_timer <= 0.0:
			is_waiting = false
			_pick_new_random_target()
		# Während des Wartens nicht weiterfahren
		linear_velocity = Vector3.ZERO
		# Wellen kippen das Schiff weiter schön → daher kein return vor der Wellenlogik
		return


	if current_target == null:
		# Kein Ziel -> einfach geradeaus fahren
		var move_forward_no_target: Vector3 = global_transform.basis.z
		move_forward_no_target.y = 0.0
		if move_forward_no_target.length() > 0.001:
			move_forward_no_target = move_forward_no_target.normalized()
			linear_velocity = move_forward_no_target * forward_speed
		return

	# NavAgent an Zielposition binden
	var target_pos: Vector3 = current_target.global_transform.origin
	nav_agent.target_position = target_pos

	var current_pos: Vector3 = global_transform.origin

	# Entfernung zum Ziel in XZ-Ebene
	var to_target_flat := target_pos - current_pos
	to_target_flat.y = 0.0
	var horizontal_dist := to_target_flat.length()

	# Ziel erreicht -> wir warten
	if nav_agent.is_navigation_finished() or horizontal_dist < arrival_distance:
		is_waiting = true
		wait_timer = wait_at_target_time
		linear_velocity = Vector3.ZERO
		return

	# Nächste Position auf dem Pfad
	var next_pos: Vector3 = nav_agent.get_next_path_position()
	var desired_dir: Vector3 = next_pos - current_pos
	desired_dir.y = 0.0

	if desired_dir.length() > 0.1:
		desired_dir = desired_dir.normalized()

		# aktuelle Vorwärtsrichtung (du nutzt +Z als vorwärts)
		var forward: Vector3 = global_transform.basis.z
		forward.y = 0.0
		forward = forward.normalized()

		# Yaw berechnen (Winkel in XZ)
		var target_yaw := atan2(desired_dir.x, desired_dir.z)
		var current_yaw := atan2(forward.x, forward.z)
		var delta_yaw := wrapf(target_yaw - current_yaw, -PI, PI)

		# Nur um Y drehen
		var yaw_velocity := delta_yaw * turn_strength
		angular_velocity.y = yaw_velocity


	var move_forward: Vector3 = global_transform.basis.z
	move_forward.y = 0.0
	if move_forward.length() > 0.001:
		move_forward = move_forward.normalized()
		linear_velocity = move_forward * forward_speed


func _pick_new_random_target() -> void:
	if target_container == null:
		print("Kein target_container gesetzt")
		current_target = null
		return

	var candidates: Array[Node3D] = []
	for child in target_container.get_children():
		if child is Node3D:
			candidates.append(child)

	if candidates.is_empty():
		print("target_container hat keine Node3D-Kinder")
		current_target = null
		return

	current_target = candidates[randi() % candidates.size()]
	print("Neues Ziel gewählt:", current_target.name)

	nav_agent.target_position = current_target.global_transform.origin


func calculateNormal(xz: Vector2) -> Vector3:
	var epsilon = 0.05

	var h = WaveHeight.height(xz)
	var hx = WaveHeight.height(Vector2(xz.x + epsilon, xz.y))
	var hz = WaveHeight.height(Vector2(xz.x, xz.y + epsilon))

	var tangentX = Vector3(epsilon, hx - h, 0.0).normalized()
	var tangentZ = Vector3(0.0, hz - h, epsilon).normalized()

	var normal = tangentZ.cross(tangentX)
	return normal

func set_target_container(container: Node3D) -> void:
	target_container = container

	if is_initialized:
		_pick_new_random_target()
