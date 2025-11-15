extends RigidBody3D

@export var life_time: float = 3.0

@export var plank_scene: PackedScene
@export var plank_count: int = 20
@export var plank_impulse: float = 5

var _time_passed: float = 0.0


func _ready() -> void:
	linear_damp = 0.0
	angular_damp = 0.0

	randomize()

	# Kollisionsüberwachung aktivieren, damit body_entered-Signal funktioniert
	contact_monitor = true
	max_contacts_reported = 8

	# Signal verbinden
	body_entered.connect(_on_body_entered)

	print("CannonBall ready. plank_scene =", plank_scene)


func _physics_process(delta: float) -> void:
	_time_passed += delta
	if _time_passed >= life_time:
		queue_free()


func _on_body_entered(body: Node) -> void:
	# Debug-Ausgabe, damit wir sehen, ob überhaupt eine Kollision erkannt wird
	print("CannonBall kollidiert mit:", body.name, " | Gruppen:", body.get_groups())

	# Zum Testen: erstmal IMMER Planken spawnen, egal was getroffen wurde
	_spawn_planks()

	# Wenn du später nur Schiffe willst, nimm stattdessen:
	# if body.is_in_group("ship"):
	#     _spawn_planks()

	queue_free()


func _spawn_planks() -> void:
	if plank_scene == null:
		push_warning("plank_scene ist nicht gesetzt! Keine Planken werden gespawnt.")
		return

	var parent := get_tree().current_scene
	var origin := global_transform.origin

	for i in range(plank_count):
		var plank := plank_scene.instantiate() as RigidBody3D

		# Position in der Nähe der Einschlagstelle
		var random_offset := Vector3(
			randf_range(-0.5, 0.5),
			randf_range(-0.5, 0.5),
			randf_range(-0.5, 0.5)
		)

		# zufällige Rotation (Euler)
		var random_rot := Vector3(
			randf_range(0.0, TAU),
			randf_range(0.0, TAU),
			randf_range(0.0, TAU)
		)

		var t := plank.global_transform
		t.origin = origin + random_offset

		# ✅ Godot 4-kompatibel:
		# Variante A: über Quaternion
		var q := Quaternion.from_euler(random_rot)
		t.basis = Basis(q)

		# (Alternativ, falls deine Version es unterstützt:)
		# t.basis = Basis.from_euler(random_rot)

		plank.global_transform = t

		parent.add_child(plank)

		# Zufällige Flugrichtung nach außen / oben
		var dir := Vector3(
			randf_range(-1.0, 1.0),
			randf_range(0.2, 1.0),
			randf_range(-1.0, 1.0)
		).normalized()

		plank.apply_impulse(dir * plank_impulse)

		# optional: zufälliger Drall / Drehimpuls
		var torque := Vector3(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		).normalized() * plank_impulse
		plank.apply_torque_impulse(torque)
