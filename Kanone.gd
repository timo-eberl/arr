extends MeshInstance3D
	
func _process(delta):
	var space_state = get_world_3d().direct_space_state
	var cam = $"../../../Camera3D"
	var mousepos = get_viewport().get_mouse_position()

	var origin = cam.project_ray_origin(mousepos)
	var end = origin + cam.project_ray_normal(mousepos) * 1000
	var query = PhysicsRayQueryParameters3D.create(origin, end, 2)
	query.collide_with_areas = true

	var result = space_state.intersect_ray(query)
