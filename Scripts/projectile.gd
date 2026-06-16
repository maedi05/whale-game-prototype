extends Area2D

var facing_right: bool = true
@export var projectile_speed := 300


	

func _process(delta):
	var projectile_dir = 1.0 if facing_right else -1.0
	position.x +=  projectile_speed * projectile_dir * delta
	$Sprite2D.flip_h = projectile_dir < 0
