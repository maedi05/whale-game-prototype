extends Control

@onready var label = $Label

func _ready():
	EventController.coin_collected.connect(on_event_coin_collected)

func on_event_coin_collected(value: int) -> void:
	label.text = str(value)
