shader_type spatial;
render_mode cull_disabled;

uniform vec4 grass_color : source_color;

// Player interaction parameters
uniform vec3 player_position = vec3(0.0);
uniform float interaction_power = 0.5;
uniform float interaction_radius = 1.0;

// Wind sway parameters
uniform sampler2D wind_noise;
uniform vec2 wind_horizontal_direction = vec2(1.0, 0.0);
uniform float wind_texture_tile_size = 20.0;
uniform float wind_speed = 0.05;
uniform float wind_strength = 1.0;
uniform float wind_vertical_strength = 0.5;

void vertex() {
	// Player position distort shader
    // Transform vertex position from model space to world space
    vec3 world_vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

    // Calculate direction vector from the player to the vertex, ignoring the vertical component
    vec3 direction_to_player = world_vertex - player_position;
    direction_to_player.y = 0.0;
    direction_to_player = normalize(direction_to_player);

    // Calculate the distance between the player and the vertex
    float distance_to_player = distance(player_position, world_vertex);

    // Calculate the interaction power based on the distance within the specified radius
    float interaction_strength = smoothstep(interaction_radius, 0.0, distance_to_player);

    // Transform the direction vector from world space back to model space
    direction_to_player = (vec4(direction_to_player, 1.0) * MODEL_MATRIX).xyz;

    // Modify the vertex position based on player interaction
    VERTEX += direction_to_player * interaction_strength * interaction_power * (1.0 - UV.y);
	// Wind shader
	vec3 world_vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	vec2 normalized_wind_direction = normalize(wind_horizontal_direction);
	vec2 world_uv = world_vertex.xz / wind_texture_tile_size + normalized_wind_direction * TIME * wind_speed;
	// we displace only the top part of the mesh
	// note that this means that the mesh needs to have UV in a way that the bottom of UV space
	// is at the top of the mesh
	float displacement_affect = (1.0 - UV.y);
	float wind_noise_intensity = (textureLod(wind_noise, world_uv , 0.0).r - 0.5);

	// We convert the direction of the wind into model space from world space
	// if we used it directly in vertex space, rotated blades of grass wouldn't behave properly
	vec2 model_space_horizontal_direction = (inverse(MODEL_MATRIX) * vec4(wind_horizontal_direction, 0.0,0.0)).xy;
	model_space_horizontal_direction = normalize(model_space_horizontal_direction);
	vec3 wind_vector = vec3(
		wind_noise_intensity * model_space_horizontal_direction.x,
		1.0 - wind_noise_intensity,
		wind_noise_intensity * model_space_horizontal_direction.y 
	);
	normalize(wind_vector);
	wind_vector *= vec3(
		wind_strength,
		wind_vertical_strength,
		wind_strength
	);
	VERTEX += wind_vector * displacement_affect;
}

void fragment() {
    // Set the fragment color to the specified grass color
    ALBEDO = grass_color.rgb;
}