class_name DynamicMusic

static func update(collected_treasure_node : Node3D, music_player: AudioStreamPlayer) -> void:
	var collected_treasure: int = GameState.gold + collected_treasure_node.get_child_count()
	var stream: AudioStreamSynchronized = music_player.stream
	var main_volume: float = db_to_linear(stream.get_sync_stream_volume(0))
	var gold_per_stage: float = 40.0
	for stage in range(1, 5):
		var linear_volume: float = lerp(0.0, main_volume, 1.0 - clampf(abs(stage * gold_per_stage - collected_treasure), 0.0, gold_per_stage) / gold_per_stage)
		# never fade out last stage
		if(stage == 4 && collected_treasure >= stage * gold_per_stage):
			linear_volume = 1
		stream.set_sync_stream_volume(stage, linear_to_db(linear_volume))
		#print("VOLUME ", stage, "_", linear_volume)
