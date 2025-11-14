extends Node3D

@export var bullet_scene: PackedScene
@export var bullet_speed: float = 50.0
@export var fire_rate: float = 0.25

@onready var muzzle: Marker3D = $Muzzle

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

	var bullet := bullet_scene.instantiate() as RigidBody3D

	get_tree().current_scene.add_child(bullet)

	bullet.global_transform = muzzle.global_transform

	var dir: Vector3 = -muzzle.global_transform.basis.z
	bullet.linear_velocity = dir * bullet_speed
