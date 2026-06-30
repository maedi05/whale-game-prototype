extends Node2D

@export var circle_color: Color = Color.WHITE
@export var max_radius: float = 200.0
@export var grow_duration: float = 3.0
@export var fade_duration: float = 1.0
@export var cooldown_time: float = 1.0

# Use a setter to redraw whenever radius changes
var current_radius: float = 0.0:
	set(value):
		current_radius = value
		queue_redraw()

var is_animating: bool = false
var can_trigger: bool = true
var cooldown_timer: Timer

func _ready():
	modulate.a = 0.0          # start invisible
	current_radius = 0.0

	cooldown_timer = Timer.new()
	cooldown_timer.one_shot = true
	add_child(cooldown_timer)
	cooldown_timer.timeout.connect(_on_cooldown_finished)

func _draw():
	draw_circle(Vector2.ZERO, current_radius, circle_color)

func _input(event):
	if event.is_action_pressed("shoot") and can_trigger:
		start_animation()

func start_animation():
	can_trigger = false       # block new inputs immediately
	is_animating = true
	modulate.a = 1.0          # become fully visible
	current_radius = 0.0      # reset radius

	var tween = create_tween()
	# Grow
	tween.tween_property(self, "current_radius", max_radius, grow_duration)\
		 .set_trans(Tween.TRANS_QUAD)
	# Fade out
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)\
		 .set_delay(0.1)
	# Start cooldown after fade finishes
	tween.tween_callback(start_cooldown)

func start_cooldown():
	is_animating = false
	cooldown_timer.start(cooldown_time)

func _on_cooldown_finished():
	can_trigger = true
	# Optional: you can also reset radius here, but it's already reset on next trigger
