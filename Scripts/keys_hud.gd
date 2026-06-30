extends Label

func _ready() -> void:
	Global.keys_changed.connect(_on_keys_changed)
	_on_keys_changed(Global.collected_keys, Global.KEYS_REQUIRED)

func _on_keys_changed(current: int, required: int) -> void:
	text = "Keys: %d/%d" % [current, required]
