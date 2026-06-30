extends Area2D

@export var coin_value: int = 1

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Check if the body touching the coin is the whale
	if body.is_in_group("Player"):
		Global.coin_collected(coin_value)  # Update score
		queue_free()  # Destroy the coin
