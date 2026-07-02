extends Area2D
@onready var sprite_2d: Sprite2D = $Sprite2D

func _on_area_entered(_area: Area2D) -> void:
	var tween = get_tree().create_tween()
	tween.tween_method(set_shader_blinkintensity, 12.0, 0.0, 0.5)

func set_shader_blinkintensity(newValue : float):
	sprite_2d.material.set_shader_parameter("thickness", newValue)
