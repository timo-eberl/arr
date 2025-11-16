extends Area3D

@export var ship: RigidBody3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body == ship and ship is Ship:
		if ship.has_method("deposit_treasure"):
			ship.deposit_treasure()
			
