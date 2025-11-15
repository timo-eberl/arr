extends RigidBody3D

@export var life_time: float = 3.0

@export var plank_scene: PackedScene

# --- Parameter für Eintritt in Schiff ---
@export var enter_plank_count: int = 7
@export var enter_plank_impulse: float = 5

# --- Parameter für Austritt aus Schiff ---
@export var exit_plank_count: int = 15
@export var exit_plank_impulse: float = 10

@onready var hit_area: Area3D = $HitArea

var _time_passed: float = 0.0


func _ready() -> void:
	linear_damp = 0.0
	angular_damp = 0.0
	randomize()

	collision_layer = 0
	collision_mask = 0

	contact_monitor = false

	hit_area.body_entered.connect(_on_body_entered)
	hit_area.body_exited.connect(_on_body_exited)

	print("CannonBall ready.")


func _physics_process(delta: float) -> void:
	_time_passed += delta
	if _time_passed >= life_time:
		queue_free()


# -------------------------------------------------------------------------
#                   SIGNAL HANDLER
# -------------------------------------------------------------------------

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy_ship") and body is PhysicsBody3D:
		print("ENTER hit:", body.name)
		_spawn_planks(body, enter_plank_count, enter_plank_impulse)


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("enemy_ship") and body is PhysicsBody3D:
		print("EXIT hit:", body.name)
		_spawn_planks(body, exit_plank_count, exit_plank_impulse)


# -------------------------------------------------------------------------
#                   PLANK SPAWNING
# -------------------------------------------------------------------------

func _spawn_planks(ship_body: PhysicsBody3D, count: int, impulse: float) -> void:
	if plank_scene == null:
		push_warning("plank_scene ist not set")
		return

	var parent := get_tree().current_scene
	var origin := global_transform.origin

	for i in range(count):
		var plank := plank_scene.instantiate() as RigidBody3D
		
		# Planken sollen Schiff NICHT wegschieben
		plank.collision_layer = 1      # Kollidiert z.B. mit Welt
		plank.collision_mask = 1
		plank.add_collision_exception_with(ship_body)

		# Position & Rotation
		var random_offset := Vector3(
			randf_range(-0.5, 0.5),
			randf_range(-0.5, 0.5),
			randf_range(-0.5, 0.5)
		)

		var random_rot := Vector3(
			randf_range(0.0, TAU),
			randf_range(0.0, TAU),
			randf_range(0.0, TAU)
		)

		parent.add_child(plank)

		var t := plank.global_transform
		t.origin = origin + random_offset
		var q := Quaternion.from_euler(random_rot)
		t.basis = Basis(q)
		plank.global_transform = t


		# Bewegungsrichtung
		var dir := Vector3(
			randf_range(-1.0, 1.0),
			randf_range(0.2, 1.0),
			randf_range(-1.0, 1.0)
		).normalized()

		plank.apply_impulse(dir * impulse)

		# Drall
		var torque := Vector3(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		).normalized() * impulse
		plank.apply_torque_impulse(torque)
