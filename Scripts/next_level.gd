extends Area2D

const FILE_BEGIN = "res://Scenes/test_level_"  # e.g., "test_level_1.tscn"
@export var required_coins: int = 3           # coins needed to unlock

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
	
	# Check if we have enough coins
	if Global.total_coins < required_coins:
		print("Need ", required_coins, " coins, have ", Global.total_coins)
		return  # Not enough coins – do nothing
	
	# Extract the current level number from the scene file path
	var current_path = get_tree().current_scene.scene_file_path
	var current_number = _extract_level_number(current_path)
	if current_number == -1:
		print("Could not extract level number from: ", current_path)
		return
	
	var next_number = current_number + 1
	var next_level_path = FILE_BEGIN + str(next_number) + ".tscn"
	
	# Check if the next level file actually exists (optional)
	if not ResourceLoader.exists(next_level_path):
		print("Next level not found: ", next_level_path)
		return
	
	# Change to the next level
	get_tree().call_deferred("change_scene_to_file", next_level_path)

# Helper to extract number from filename like "test_level_2.tscn" → 2
func _extract_level_number(path: String) -> int:
	var filename = path.get_file()  # e.g., "test_level_2.tscn"
	# Remove extension
	var base = filename.trim_suffix(".tscn")
	# Split by "_" and take last part, then convert to int
	var parts = base.split("_")
	if parts.size() < 2:
		return -1
	var num_str = parts[-1]
	if num_str.is_valid_int():
		return num_str.to_int()
	return -1
