class_name Ship
extends RigidBody3D
@export var winkel = 0;
@export var speed := 0.0;
var kippen = 0;
var timer = 120

@export var max_speed := 16.0

@export var cam_dist_idle := 40
@export var cam_dist_fast := 70

@onready var camera_controller : CameraController = $CameraTarget

@export var sails : Array[Node3D]

@onready var collected_treasure_parent: Node3D = $"../CollectedTreasure"

var sail_down := 0.0

var target_sail_scale := 0.0
var sail_scale := 0.2

var schiffLaenge = 1;
var Laenge = 1;

var ship_sound: AudioStreamPlayer = AudioStreamPlayer.new()

func setShipLength() -> void:
	if Laenge != schiffLaenge:
		schiffLaenge = Laenge;
	pass

func SetSail() -> void:
	$SchiffExport/Sail.set_blend_shape_value(0, max(0, 1.0 - sail_down));
	$SchiffExport/Sail_001.set_blend_shape_value(0, max(0, 1.0 -  sail_down));
	$SchiffExport/Sail_002.set_blend_shape_value(0, max(0, 1.0 -  sail_down));

func _ready() -> void:
	camera_controller.target_cam_distance = cam_dist_idle
	ship_sound.stream = load("res://Sounds/wind_in_sail.wav")
	self.add_child(ship_sound)

func _process(delta: float) -> void:
	
	$"../UI/RichTextLabel".text = "Time remaining: %d seconds" % timer
	timer -= delta
	
	# TODO set target_sail_scale and camera_controller.target_cam_distance based on velocity
	SetSail()
	
	sail_scale = lerp(sail_scale, target_sail_scale, delta * 1.5)
	for sail in sails:
		sail.scale = Vector3(1,sail_scale,1)
	#$"../RigidBody3D".add_constant_force(transform.basis.x * lenkinput * _delta * 20.0, transform.basis.y * 2.0);
	
	#global_transform.origin += -global_transform.basis.z * speed * delta;
	
	if abs(kippen) > 0:
		kippen *= 0.95;
	
	#basis.y = normal.normalized().rotated(global_basis.z, lenkinput / 4.0 + kippen).rotated(global_basis.x, -0.15 * abs(lenkinput))     # set the UP direction
	#basis.x = basis.y.cross(-Vector3.FORWARD.rotated(Vector3(0, 1, 0), winkel)).normalized()
	#basis.z = basis.x.cross(basis.y).normalized()

func SetKippen(k: float):
	linear_velocity += basis.z * k * 10.0
	angular_velocity += basis.z * k * 5.0

func _physics_process(delta: float) -> void:
	var global_2d := Vector2(self.global_position.x, self.global_position.z)
	var target_height := WaveHeight.height(global_2d)
	var d : float = target_height - global_position.y
	linear_velocity.y = d * 20.0
	
	var lenkinput := Input.get_axis("RechtsLenken", "LinksLenken")
	angular_velocity.y += lenkinput * 4 * delta
	
	var normal = WaveHeight.calculateNormal(global_2d)
	var myBasis = Basis()
	myBasis.y = normal.normalized()        # UP-Richtung setzen
	myBasis.x = myBasis.y.cross(-Vector3.FORWARD).normalized()
	myBasis.z = myBasis.x.cross(myBasis.y).normalized()

	var current_up = global_transform.basis.y
	var target_up = myBasis.y

	var rotation_axis = current_up.cross(target_up)
	var angle = current_up.angle_to(target_up)
	var up_strength = 0.24

	if rotation_axis.length() > 0.0001:
		angular_velocity += rotation_axis.normalized() * angle * up_strength
		angular_velocity -= lenkinput * basis.z * 0.05
		angular_velocity += -abs(lenkinput) * basis.x * 0.02
	
	var lenkWinkel = Vector3(linear_velocity.x, 0, linear_velocity.z).signed_angle_to(basis.z, Vector3.UP)
	
	linear_velocity = linear_velocity.rotated(Vector3(0,1.0,0), lenkWinkel / 2.0)
	
	var speedInput := Input.get_axis("Brenmsen", "Gasgeben") 
	sail_down += speedInput * 0.01
	sail_down = clamp(sail_down, -.1, 1.0)
	#print(sail_down)
	
	#if Input.is_action_pressed("Gasgeben") and linear_velocity.length() < max_speed:
	self.apply_central_force(global_basis.z * sail_down * 15)

	# experimental wind volume
	var velocity_sound: float = clampf(linear_velocity.length() / max_speed, 0.0, 0.8)
	ship_sound.volume_db = -60.0 + velocity_sound ** 4 * 60.0
	#print(" VOLUME    ", sail_down)
	if(!ship_sound.playing):
		ship_sound.play()
	
func get_carried_treasure_amount() -> int:
	return collected_treasure_parent.get_child_count()

func deposit_treasure() -> void:
	var amount := get_carried_treasure_amount()
	if amount <= 0:
		return

	GameState.add_gold(amount)

	var player := AudioStreamPlayer.new()
	add_child(player)
	player.stream = load("res://Sounds/treasure_delivered.wav")
	player.volume_db = -15
	player.play()

	for child in collected_treasure_parent.get_children():
		child.queue_free()

	await player.finished
	player.queue_free()
