extends RigidBody3D

func _physics_process(delta):
	var global_2d := Vector2(self.global_position.x, self.global_position.z)
	self.global_position.y = WaveHeight.height(global_2d)

	var normal = calculateNormal(global_2d)
	var myBasis = Basis();
	myBasis.y = normal.normalized();    # set the UP direction
	myBasis.x = basis.y.cross(-Vector3.FORWARD).normalized()
	myBasis.z = basis.x.cross(basis.y).normalized()

	var current_up = global_transform.basis.y
	var target_up = myBasis.y

	# Axis of rotation needed to align current_up → target_up
	var rotation_axis = current_up.cross(target_up)

	# How far we are from pointing up
	var angle = current_up.angle_to(target_up)

	var strength = .05

	# Set angular velocity (direction * magnitude)
	angular_velocity += rotation_axis.normalized() * angle * strength
	linear_velocity += Vector3(basis.z.x, 0, basis.z.z);

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
