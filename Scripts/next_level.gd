extends Area2D

const FILE_BEGIN = "res://Scenes/test_level_" #change that later pls to the finished level name

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		if not Global.has_required_keys():
			print("Need ", Global.KEYS_REQUIRED - Global.collected_keys, " more key(s) before advancing!")
			return
			
		var current_scene_file = get_tree().current_scene.scene_file_path
		var next_level_number = current_scene_file.to_int() + 1 #dont name your folders with numbers otherwise this wont work(
		
		var next_level_path = FILE_BEGIN + str(next_level_number) + ".tscn"
		Global.reset_keys() # New level starts fresh
		#get_tree().change_scene_to_file(next_level_path)
		get_tree().call.call_deferred("change_scene_to_file", next_level_path)
