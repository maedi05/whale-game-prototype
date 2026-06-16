extends Node2D

#onst projectile_scene: PackedScene = preload("res://Scenes/projectile.tscn")

#unc _on_player_scene_shoot(pos , facing_right): #-> void:
	#ar projectile = projectile_scene.instantiate()
	#f "facing_right" in projectile:
		#rojectile.facing_right = facing_right
#$Projectiles.add_child(projectile)
#projectile.position = pos # -> pos is position of the player
