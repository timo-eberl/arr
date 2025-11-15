extends RigidBody3D

@export var life_time: float = 3.0
@onready var water : Water = get_tree().root.get_node("World/Water")

@export var plank_scene: PackedScene

@export var enter_plank_count: int = 5
@export var enter_plank_impulse: float = 10.0
@export_range(0.0, 1.0) var enter_direction_alignment: float = 0.4

@export_range(0.0, 1.0) var enter_speed_factor: float = 0.5

@export var exit_plank_count: int = 10
@export var exit_plank_impulse: float = 10
@export_range(0.0, 1.0) var exit_direction_alignment: float = 0.4


@onready var hit_area: Area3D = $HitArea

var splash_spawned := false
var _time_passed: float = 0.0

# Wird von der Kanone gesetzt (Richtung, in die die Kugel fliegt)
var shoot_direction: Vector3 = Vector3.FORWARD

var explosion_sound_player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
var splash_sound_player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
var explosion_sounds = ["res://Sounds/explosion1.wav", "res://Sounds/explosion2.wav", "res://Sounds/explosion3.wav", "res://Sounds/explosion4.wav", "res://Sounds/explosion5.wav", "res://Sounds/explosion6.wav", "res://Sounds/explosion7.wav", "res://Sounds/explosion8.wav"]
var splash_sounds = ["res://Sounds/splash1.wav", "res://Sounds/splash2.wav", "res://Sounds/splash3.wav", "res://Sounds/splash4.wav"]

func _ready() -> void:
	explosion_sound_player.stream = load(explosion_sounds.pick_random())
	splash_sound_player.stream = load(splash_sounds.pick_random())
	get_tree().root.add_child(explosion_sound_player)
	get_tree().root.add_child(splash_sound_player)

	linear_damp = 0.0
	angular_damp = 0.0
	randomize()

	collision_layer = 0
	collision_mask = 0

	contact_monitor = false

	hit_area.body_entered.connect(_on_body_entered)
	hit_area.body_exited.connect(_on_body_exited)

	print("CannonBall ready. dir =", shoot_direction)


func _physics_process(delta: float) -> void:
	_time_passed += delta
	if _time_passed >= life_time:
		queue_free()
	
	if not splash_spawned:
		var water_height := WaveHeight.height(Vector2(global_position.x, global_position.z))
		if water_height > self.global_position.y:
			water.add_splash(global_position)
			water.add_foam(global_position, 8.0)
			self.linear_velocity *= 0.7
			splash_spawned = true
			splash_sound_player.position = self.global_position
			splash_sound_player.play()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy_ship") and body is PhysicsBody3D:
		print("ENTER hit:", body.name)
		_spawn_planks(
			body as PhysicsBody3D,
			enter_plank_count,
			enter_plank_impulse,
			-1.0,
			enter_direction_alignment
		)
		explosion_sound_player.position = self.global_position
		explosion_sound_player.play()





func _on_body_exited(body: Node) -> void:
	if body.is_in_group("enemy_ship") and body is PhysicsBody3D:
		print("EXIT hit:", body.name)
		# Austritt -> Bretter eher MIT der Kugel
		_spawn_planks(
			body as PhysicsBody3D,
			exit_plank_count,
			exit_plank_impulse,
			1.0,
			exit_direction_alignment
		)
		
		if enter_speed_factor < 1.0:
			linear_velocity *= enter_speed_factor

func _spawn_planks(
		ship_body: PhysicsBody3D,
		count: int,
		impulse: float,
		dir_sign: float,
		alignment: float
	) -> void:
	if plank_scene == null:
		push_warning("plank_scene ist not set")
		return

	var parent := get_tree().current_scene
	var origin := global_transform.origin

	# Basisrichtung aus Flugrichtung der Kugel
	var main_dir := shoot_direction
	if main_dir.length() < 0.001:
		main_dir = Vector3.FORWARD
	main_dir = main_dir.normalized() * dir_sign

	for i in range(count):
		var plank := plank_scene.instantiate() as RigidBody3D

		# Planke soll Schiff nicht wegschubsen
		plank.collision_layer = 1      # z.B. Welt
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


		# Zufallsrichtung (für Streuung)
		var random_dir := Vector3(
			randf_range(-1.0, 1.0),
			randf_range(0.2, 1.0),
			randf_range(-1.0, 1.0)
		).normalized()

		# Mischung aus Haupt-Richtung und Zufall
		var dir := (main_dir * alignment + random_dir * (1.0 - alignment)).normalized()

		# Impuls durch Aufprall
		plank.apply_impulse(dir * impulse)

		# Drehimpuls
		var torque := Vector3(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		).normalized() * impulse
		plank.apply_torque_impulse(torque)
