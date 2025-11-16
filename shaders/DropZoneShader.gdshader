shader_type spatial;

uniform float radius : hint_range(0.0, 1.0) = 5.4;      // Inner radius of the ring
uniform float thickness : hint_range(0.0, 1.0) = 0.05;  // Width of the ring
uniform vec3 ring_color : source_color = vec3(1.0, 0.0, 0.0); // Red

void fragment() {
    vec2 uv = UV * 2.0 - 1.0;        // Convert UV to range [-1,1]
    float dist = length(uv);         // Distance from center
	
	float outer = abs(sin(TIME));
	outer = 0.75 + outer / 4.0;
	
	if(dist > outer)
		ALPHA = 0.0;
	else
		if(dist > outer - 0.1)
			ALPHA = 1.0;
		else
			ALPHA = 0.0;
			
	ALBEDO = vec3(1.0, 0.0, 0.0);
}