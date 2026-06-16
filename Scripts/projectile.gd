extends Area2D

var facing_right: bool = true
@onready var sprite = $Sprite2D

func _ready() -> void:
	if sprite:
		sprite.flip_h = not facing_right
	await get_tree().create_timer(.5).timeout
	queue_free()
		
func _process(delta):
	var direction = 1.0 if facing_right else -1.0
	position.x += 300 * delta * direction
	
func _on_body_entered(body: Node2D) -> void:
	print("Hit!", body.name)
	if body is Player:
		return 
	queue_free()
		
