extends Node3D

@export var bullet_scene: PackedScene
@export var bullet_speed: float = 40.0
@export var fire_rate: float = 1

@export var ray_length: float = 1000.0
@export var collision_mask: int = 2
@export var camera_path: NodePath

@export var shoot_up_amount: float = 0.1

@onready var cam: Camera3D = get_node(camera_path) as Camera3D
@onready var left_muzzle: Marker3D = $Kanone1/MuzzleKanone1
@onready var right_muzzle: Marker3D = $Kanone2/MuzzleKanone2
@onready var cannon_sound_player: RandomSoundPlayer = $"../../Ship/CannonSounds"

var _cooldown: float = 0.0

var _ship_velocity: Vector3 = Vector3.ZERO
var _last_global_pos: Vector3

func _ready():
	_last_global_pos = global_transform.origin
	print("LEFT =", left_muzzle)
	print("RIGHT =", right_muzzle)


func _physics_process(delta: float) -> void:
	# Schiffsgeschwindigkeit aus Positionsänderung berechnen
	var current_pos: Vector3 = global_transform.origin
	if delta > 0.0:
		_ship_velocity = (current_pos - _last_global_pos) / delta
	_last_global_pos = current_pos

	# Feuerrate / Input wie vorher
	if _cooldown > 0.0:
		_cooldown -= delta

	if Input.is_action_pressed("shoot"):
		fire()


func fire() -> void:
	if _cooldown > 0.0:
		return
	_cooldown = fire_rate

	if bullet_scene == null:
		push_warning("No cannon ball scene")
		return

	var use_right: bool = is_target_on_right_side()
	var muzzle: Marker3D = right_muzzle if use_right else left_muzzle
	
	var bullet := bullet_scene.instantiate() as RigidBody3D
	get_tree().current_scene.add_child(bullet)
	
	if use_right:
		$"../../Ship".SetKippen(.4)
	else:
		$"../../Ship".SetKippen(-.4)
	
	# 1) Basis-Richtung aus Mündung, aber erstmal flach (parallel zum Boden)
	var dir: Vector3 = -muzzle.global_transform.basis.z
	dir.y = 0.0
	dir = dir.normalized()

	# 2) Leichten Up-Kick dazugeben
	dir.y += shoot_up_amount
	dir = dir.normalized()

	var spawn_offset: float = 2.0
	var spawn_pos: Vector3 = muzzle.global_transform.origin + dir * spawn_offset

	var t := bullet.global_transform
	t.origin = spawn_pos
	t.basis = Basis.looking_at(dir, Vector3.UP)
	bullet.global_transform = t

	# Schussrichtung an die Kugel weitergeben (inkl. Up-Kick)
	bullet.shoot_direction = dir

	var ship_body := _find_ship_body()
	if ship_body != null:
		bullet.add_collision_exception_with(ship_body)

	bullet.linear_velocity = _ship_velocity + dir * bullet_speed

	#cannon_sound_player.play_sound()


func is_target_on_right_side() -> bool:
	if cam == null or get_viewport() == null:
		var mouse_pos = get_viewport().get_mouse_position()
		var viewport_size = get_viewport().get_visible_rect().size
		return mouse_pos.x > viewport_size.x * 0.5

	var space_state = get_world_3d().direct_space_state
	var mouse_pos = get_viewport().get_mouse_position()

	var origin: Vector3 = cam.project_ray_origin(mouse_pos)
	var normal: Vector3 = cam.project_ray_normal(mouse_pos)
	var end: Vector3 = origin + normal * ray_length

	var query := PhysicsRayQueryParameters3D.create(origin, end, collision_mask)
	query.collide_with_areas = true

	var result: Dictionary = space_state.intersect_ray(query)

	var target_pos: Vector3 = end
	if result.has("position"):
		target_pos = result["position"]

	var left_pos: Vector3 = left_muzzle.global_transform.origin
	var right_pos: Vector3 = right_muzzle.global_transform.origin
	var center: Vector3 = (left_pos + right_pos) * 0.5

	var right_dir: Vector3 = (right_pos - left_pos)
	if right_dir.length() < 0.001:
		return true
	right_dir = right_dir.normalized()

	var to_target: Vector3 = (target_pos - center)

	var dot: float = right_dir.dot(to_target)

	return dot > 0.0

func _find_ship_body() -> PhysicsBody3D:
	var node: Node = self
	while node != null:
		if node is PhysicsBody3D:
			return node as PhysicsBody3D
		node = node.get_parent()
	return null
