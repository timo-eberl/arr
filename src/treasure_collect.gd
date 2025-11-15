extends Area3D

@onready var collected_treasure_parent : Node3D = $"../../CollectedTreasure"
@onready var treasure_spawn : Marker3D = $"../TreasureSpawn"
@onready var ship_body : RigidBody3D = $".."

func _on_area_entered(area: Area3D) -> void:
	if area is CollectableTreasure:
		#var rb := RigidBody3D.new()
		#collected_treasure_parent.add_child(rb)
		#rb.global_position = treasure_spawn.global_position
		#for child in area.get_children():
			#child.get_parent().remove_child(child)
			#rb.add_child(child)
		var collected : RigidBody3D = area.collected_variant.instantiate()
		collected_treasure_parent.add_child(collected)
		collected.global_position = treasure_spawn.global_position
		
		area.queue_free()
