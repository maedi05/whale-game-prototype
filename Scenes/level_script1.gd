extends Node2D

const projectile_scene: PackedScene = preload("res://Scenes/projectile.tscn")

func _on_player_scene_shoot(pos: Vector2) -> void:
	var projectile = projectile_scene.instantiate()
	$Projectiles.add_child(projectile)
	print('shoot from player')
	print(pos)
	projectile.pos = global_position # -> pos is position of the player
