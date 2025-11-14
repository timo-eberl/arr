extends Node3D

@export var bullet_scene: PackedScene
@export var bullet_speed: float = 50.0
@export var fire_rate: float = 0.25

@export var ray_length: float = 1000.0
@export var collision_mask: int = 2
@export var camera_path: NodePath
@export var ship_body_path: NodePath   # <- RigidBody3D des Schiffs hier zuweisen

@onready var cam: Camera3D = get_node(camera_path) as Camera3D
@onready var left_muzzle: Marker3D = $Kanone2/Muzzle
@onready var right_muzzle: Marker3D = $Kanone1/Muzzle
@onready var ship_body: RigidBody3D = get_node(ship_body_path) as RigidBody3D

var _cooldown: float = 0.0

func _process(delta: float) -> void:
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

	# Kugel an die Mündung setzen
	bullet.global_transform = muzzle.global_transform

	# Richtung aus der Kanone
	var dir: Vector3 = -muzzle.global_transform.basis.z

	# Schiffsgeschwindigkeit holen (falls kein ship_body gesetzt ist -> Vector3.ZERO)
	var ship_vel: Vector3 = Vector3.ZERO
	if ship_body:
		ship_vel = ship_body.linear_velocity

	# Endgeschwindigkeit der Kugel = Schiffbewegung + Mündungsgeschwindigkeit
	bullet.linear_velocity = ship_vel + dir * bullet_speed
