class_name Ship
extends Node3D
@export var winkel = 0;
@export var speed := 0.0;

@export var speed_slow := 7.0
@export var speed_fast := 16.0

var speed_mode : SPEED_MODE

enum SPEED_MODE { NO, SLOW, FAST }

var schiffLaenge = 1;
var Laenge = 1;

func setShipLength() -> void:
	if Laenge != schiffLaenge:
		schiffLaenge = Laenge;
	pass

func get_target_speed() -> float:
	if speed_mode == SPEED_MODE.SLOW:
		return speed_slow
	elif speed_mode == SPEED_MODE.FAST:
		return speed_fast
	return 0.0

func _process(delta: float) -> void:
	var lenkinput = Input.get_axis("LinksLenken", "RechtsLenken")
	
	if Input.is_action_just_pressed("Gasgeben"):
		if speed_mode == SPEED_MODE.NO:
			speed_mode = SPEED_MODE.SLOW
		elif speed_mode == SPEED_MODE.SLOW:
			speed_mode = SPEED_MODE.FAST
	if Input.is_action_just_pressed("Brenmsen"):
		if speed_mode == SPEED_MODE.FAST:
			speed_mode = SPEED_MODE.SLOW
		elif speed_mode == SPEED_MODE.SLOW:
			speed_mode = SPEED_MODE.NO
	
	print(speed_mode)
	
	winkel += lenkinput * delta * (speed / 10.0);
	speed = lerp(speed, -get_target_speed(), delta)
	

	#$"../RigidBody3D".add_constant_force(transform.basis.x * lenkinput * _delta * 20.0, transform.basis.y * 2.0);
	
	global_transform.origin += -global_transform.basis.z * speed * delta;
	
	var global_2d := Vector2(self.global_position.x, self.global_position.z)
	self.global_position.y = WaveHeight.height(global_2d)
	
	var normal = calculateNormal(global_2d)
	
	var basis = Basis()               # identity basis
	basis.y = normal.normalized().rotated(global_basis.z, lenkinput / 4.0).rotated(global_basis.x, -0.15 * abs(lenkinput))     # set the UP direction
	basis.x = basis.y.cross(-Vector3.FORWARD.rotated(Vector3(0, 1, 0), winkel)).normalized()
	basis.z = basis.x.cross(basis.y).normalized()

	global_transform = Transform3D(basis, position)

func calculateNormal(xz: Vector2) -> Vector3:
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
