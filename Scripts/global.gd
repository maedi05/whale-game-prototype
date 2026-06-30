extends Node

var game_controller : GameController

# --- Keys ---
const KEYS_REQUIRED := 3
var collected_keys := 0

signal keys_changed(current: int, required: int)

func add_key() -> void:
	collected_keys += 1
	keys_changed.emit(collected_keys, KEYS_REQUIRED)
	
func reset_keys() -> void:
	collected_keys = 0
	keys_changed.emit(collected_keys, KEYS_REQUIRED)
	
func has_required_keys() -> bool:
	return collected_keys >= KEYS_REQUIRED 
