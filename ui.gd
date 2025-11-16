extends Control

@onready var gold_label: Label = $GoldLabel

func _ready():
	# Verbindung zu GameState
	GameState.gold_changed.connect(update_gold)
	update_gold(GameState.gold)

func update_gold(value: int):
	gold_label.text = str(value)
