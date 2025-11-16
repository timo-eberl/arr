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

	end_camera.current = true

	coins_label.text = "Treasure collected: " + str(GameState.gold)

	end_screen_ui.visible = true
	
	if ui:
		ui.visible = false
	if minimap:
		minimap.visible = false
		
	$TreasureDeposit/CollisionShape3D.disabled = true
	$TreasureDeposit/MeshInstance3D2.visible = false

func _on_button_pressed() -> void:
	get_tree().reload_current_scene()
	GameState.gold = 0
	#DynamicMusic.update(get_node("CollectedTreasure"), get_node("MusicPlayer"))
