extends Node

var gold: int = 0

signal gold_changed(new_value: int)

func add_gold(amount: int) -> void:
	gold += amount
	emit_signal("gold_changed", gold)
