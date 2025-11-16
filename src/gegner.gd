class_name Gegner
extends RigidBody3D

var is_initialized := false

@onready var water : Water = get_tree().root.get_node("World/Water")

@export var forward_speed: float = 5.0
@export var turn_strength: float = 1.5

@export var target_container_path: NodePath 
@export var wait_at_target_time: float = 0.0
@export var arrival_distance: float = 3.0   

@export var wave_spawns_on_death : Array[Node3D]

@onready var nav_agent: NavigationAgent3D = $NavAgent
@onready var target_container: Node3D = get_node_or_null(target_container_path)

@onready var wood_mesh: MeshInstance3D = $pirateShip_applied_material/PirateShip

var hole_counter := 0

var is_sinking := false

var health := 100.0
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
	
	wood_mesh.set_instance_shader_parameter("hole_position_0", Vector3(0,1000,0))
	wood_mesh.set_instance_shader_parameter("hole_position_1", Vector3(0,1000,0))
	wood_mesh.set_instance_shader_parameter("hole_position_2", Vector3(0,1000,0))
	wood_mesh.set_instance_shader_parameter("hole_direction_0", Vector3(1,0,0))
	wood_mesh.set_instance_shader_parameter("hole_direction_1", Vector3(1,0,0))
	wood_mesh.set_instance_shader_parameter("hole_direction_2", Vector3(1,0,0))


func _exit_tree() -> void:
	# Beim Entfernen des Schiffs das Ziel freigeben
	_set_current_target(null)


func _physics_process(delta: float) -> void:
	if is_sinking:
		return

	var global_2d := Vector2(global_position.x, global_position.z)
	global_position.y = WaveHeight.height(global_2d)

	var normal = WaveHeight.calculateNormal(global_2d)
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


# Helper: kümmert sich um exklusives Ziel-Besitzen
func _set_current_target(target: Node3D) -> void:
	# altes Ziel freigeben
	if current_target != null and current_target.is_inside_tree():
		if current_target.has_meta("assigned_ship") and current_target.get_meta("assigned_ship") == self:
			current_target.set_meta("assigned_ship", null)

	# neues Ziel setzen
	current_target = target

	# neues Ziel belegen
	if current_target != null:
		current_target.set_meta("assigned_ship", self)
		nav_agent.target_position = current_target.global_transform.origin


func _pick_new_random_target() -> void:
	if target_container == null:
		print("Kein target_container gesetzt")
		_set_current_target(null)
		return

	var free_candidates: Array[Node3D] = []

	for child in target_container.get_children():
		if child is Node3D:
			var assigned_ship = child.get_meta("assigned_ship") if child.has_meta("assigned_ship") else null
			# Nur Ziele ohne aktuelles Schiff
			if assigned_ship == null:
				free_candidates.append(child)

	if free_candidates.is_empty():
		print("Keine freien Ziele im target_container")
		# aktuelles Ziel behalten, falls vorhanden
		return

	var new_target: Node3D = free_candidates[randi() % free_candidates.size()]
	print("Neues Ziel gewählt für ", name, ": ", new_target.name)

	_set_current_target(new_target)

func set_target_container(container: Node3D) -> void:
	target_container = container

	if is_initialized:
		_pick_new_random_target()

func ball_enter(pos : Vector3, vel: Vector3):
	health -= 40.0
	print(self.name, " hit, new hp: ", health)
	
	var destruction := (1.0 - health/100.0)
	destruction = clampf(destruction, 0.0, 1.0)
	if health <= 0.0:
		destruction = 3.0
	wood_mesh.set_instance_shader_parameter("destruction", destruction)
	if hole_counter == 0:
		wood_mesh.set_instance_shader_parameter("hole_position_0", wood_mesh.to_local(pos))
		wood_mesh.set_instance_shader_parameter("hole_direction_0", (wood_mesh.global_basis.inverse() * vel).normalized())
		hole_counter += 1
	elif hole_counter == 1:
		wood_mesh.set_instance_shader_parameter("hole_position_1", wood_mesh.to_local(pos))
		wood_mesh.set_instance_shader_parameter("hole_direction_1", (wood_mesh.global_basis.inverse() * vel).normalized())
		hole_counter += 1
	elif hole_counter == 2:
		wood_mesh.set_instance_shader_parameter("hole_position_2", wood_mesh.to_local(pos))
		wood_mesh.set_instance_shader_parameter("hole_direction_2", (wood_mesh.global_basis.inverse() * vel).normalized())
		hole_counter += 1
	
	if health <= 0.0:
		sink()
		self.apply_impulse(vel * 0.003, pos)

func ball_exit(_pos : Vector3, _vel: Vector3):
	pass

func sink():
	self.gravity_scale = 0.3
	self.apply_central_impulse(Vector3(0,-0.2,0))
	axis_lock_linear_y = false
	self.linear_damp = 1.5
	is_sinking = true
	collision_mask = 0
	collision_layer = 0
	$Pfeil.visible = false
	for wave in wave_spawns_on_death:
		water.add_splash(wave.global_position)
		water.add_foam(wave.global_position, 8.0)
		await get_tree().create_timer(0.5).timeout
	for child in get_children():
		if child is CollectableTreasure or child is FloatingFluff:
			child.process_mode = Node.PROCESS_MODE_INHERIT
			child.visible = true
			var old_global_pos = child.global_position
			child.get_parent().remove_child(child)
			if child is CollectableTreasure:
				get_tree().root.get_node("World/Collectable").add_child(child)
			else:
				get_tree().root.add_child(child)
			child.global_position = old_global_pos
	await get_tree().create_timer(10).timeout
	
	queue_free()
