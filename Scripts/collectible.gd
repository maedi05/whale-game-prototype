extends Area2D

@onready var sprite_2d: Sprite2D = $Sprite2D

var collected := false

func _on_body_entered(body: Node2D) -> void:
	if collected:
		return
	if not body.is_in_group("Player"):
		return

	collected = true
	Global.add_key()

	set_deferred("monitoring", false)
	_play_pickup_effect.call_deferred()

func _play_pickup_effect() -> void:
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite_2d, "scale", sprite_2d.scale * 1.4, 0.15)
	tween.tween_property(sprite_2d, "modulate:a", 0.0, 0.15)
	tween.chain().tween_callback(queue_free)
