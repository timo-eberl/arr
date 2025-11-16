extends Node3D

@export var player_path: NodePath
@export var end_camera_path: NodePath
@export var end_ship_marker_path: NodePath
@export var end_screen_ui_path: NodePath
@export var coins_label_path: NodePath

@export var ui_path: NodePath
@export var minimap_path: NodePath

@onready var ui: Control = get_node_or_null(ui_path)
@onready var minimap: MarginContainer = get_node_or_null(minimap_path)

@onready var player: Node3D = get_node(player_path)
@onready var end_camera: Camera3D = get_node(end_camera_path)
@onready var end_ship_marker: Node3D = get_node(end_ship_marker_path)
@onready var end_screen_ui: CanvasLayer = get_node(end_screen_ui_path)
@onready var coins_label: Label = get_node(coins_label_path)


func _ready() -> void:
	# UI am Anfang ausblenden
	end_screen_ui.visible = false

func show_end_screen() -> void:
	# 1) Steuerung/Physik des Spielerschiffs deaktivieren (falls nötig)
	if player.has_method("set_process"):
		player.set_process(false)
	if player.has_method("set_physics_process"):
		player.set_physics_process(false)

	# 2) Spieler an End-Position teleportieren
	if player is Node3D:
		var t: Transform3D = player.global_transform
		t.origin = end_ship_marker.global_transform.origin
		player.global_transform = t

	# 3) Auf Endkamera umschalten
	end_camera.current = true

	# 4) Münzanzahl updaten
	coins_label.text = "Treasure collected: " + str(GameState.gold)

	# 5) UI einblenden
	end_screen_ui.visible = true
	
	if ui:
		ui.visible = false
	if minimap:
		minimap.visible = false
		
	get_node("TreasureDeposit/CollisionShape3D").disabled = true

func _on_button_pressed() -> void:
	get_tree().reload_current_scene()
