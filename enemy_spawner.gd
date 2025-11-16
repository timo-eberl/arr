extends Node3D

@export var enemy_scene: PackedScene
@export var spawn_points_path: NodePath
@export var max_ships: int = 6
@export var spawn_check_interval: float = 2.0
@export var min_spawn_distance: float = 6.0

@export var target_container_path: NodePath


@onready var spawn_points: Node3D = get_node_or_null(spawn_points_path)
@onready var target_container: Node3D = get_node_or_null(target_container_path)


var _spawn_timer: float = 0.0


func _ready() -> void:
	randomize()


func _physics_process(delta: float) -> void:
	_spawn_timer += delta
	if _spawn_timer < spawn_check_interval:
		return

	_spawn_timer = 0.0
	_spawn_until_full()


func _spawn_until_full() -> void:
	if enemy_scene == null:
		push_warning("enemy_scene ist nicht gesetzt!")
		return
	if spawn_points == null:
		push_warning("spawn_points_path ist nicht gesetzt oder ungültig!")
		return

	var current_ships := get_tree().get_nodes_in_group("enemy_ship").size()
	while current_ships < max_ships:
		if not _spawn_one_ship():
			# wenn aus irgendeinem Grund kein Spawn möglich ist -> abbrechen
			break
		current_ships += 1


func _spawn_one_ship() -> bool:
	if spawn_points == null:
		push_warning("SpawnPoints ist nicht gesetzt!")
		return false

	var spawn_list: Array[Node3D] = []
	for child in spawn_points.get_children():
		if child is Node3D:
			spawn_list.append(child)

	if spawn_list.is_empty():
		push_warning("SpawnPoints enthält keine Node3D-Kinder!")
		return false

	var ships := get_tree().get_nodes_in_group("enemy_ship")

	var free_spawns: Array[Node3D] = []
	for sp in spawn_list:
		var sp_pos: Vector3 = sp.global_transform.origin
		var too_close := false

		for s in ships:
			if s is Node3D:
				var ship_pos: Vector3 = (s as Node3D).global_transform.origin
				if sp_pos.distance_to(ship_pos) < min_spawn_distance:
					too_close = true
					break

		if not too_close:
			free_spawns.append(sp)

	if free_spawns.is_empty():
		print("Kein freier Spawnpunkt (alle Schiffe zu nah).")
		return false

	var spawn_point: Node3D = free_spawns[randi() % free_spawns.size()]

	var ship := enemy_scene.instantiate()
	if ship == null:
		push_warning("Konnte enemy_scene nicht instanzieren!")
		return false

	get_tree().current_scene.add_child(ship)

	if ship is Node3D:
		var ship3d := ship as Node3D
		var t: Transform3D = ship3d.global_transform
		t.origin = spawn_point.global_transform.origin
		t.basis = spawn_point.global_transform.basis
		ship3d.global_transform = t

		# 🔥 Ziel-Container an Gegner-Schiff übergeben
		if target_container != null and ship3d.has_method("set_target_container"):
			ship3d.set_target_container(target_container)

	return true
