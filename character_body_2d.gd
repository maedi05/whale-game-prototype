extends CharacterBody2D

class_name Player

#attacks or bullets or whatever idk
const BULLET = preload("res://Scenes/Bullet/bullet.tscn")

#Player animations
@onready var animated_sprite = $AnimatedSprite2D


#Player movement
@export var walk_speed = 150.0
@export var run_speed = 275.0 

@export_range(0, 1) var acceleration = 0.1
@export_range(0, 1) var deceleration = 0.1

@export var jump_force = -400.0
@export_range(0, 1) var decelerate_on_jump_release = 0.5

#all about dashing B>
@export var dash_speed = 1000.0
@export var dash_max_distance = 150.0
@export var dash_curve : Curve
@export var dash_cooldown = 1.0

var is_dashing = false

var dash_start_position = 0
var dash_direction = 0
var dash_timer =0

func _physics_process(delta: float) -> void:
	# Dash > Normal movement | Air > Floor
	if dash_timer > 0:
		dash_timer -= delta

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Input direction
	var direction := Input.get_axis	("left", "right")

	#Dash activation
	if Input.is_action_just_pressed("dash") and direction != 0 and not is_dashing and dash_timer <= 0:
		is_dashing = true
		dash_start_position = position.x
		dash_direction = sign(direction) # So it is -1 or 1
		dash_timer = dash_cooldown
	
	#Performs actual dash xD
	if is_dashing:
		var current_distance = abs(position.x - dash_start_position)
		if current_distance >= dash_max_distance or is_on_wall():
			is_dashing = false
		else:
			var curve_factor = dash_curve.sample(current_distance / dash_max_distance) if dash_curve else 1.0 # Better praxis
			velocity.x = dash_direction * dash_speed * curve_factor
			velocity.y = 0
	else:
		# Handle jump.
		if Input.is_action_just_pressed("jump") and (is_on_floor() or is_on_wall()):
			velocity.y = jump_force
		
		if Input.is_action_just_released("jump") and velocity.y < 0:
			velocity.y *= decelerate_on_jump_release
		
		# Velocity on ground
		var current_max_speed = run_speed if Input.is_action_pressed("run") else walk_speed

		# Move or decelerate
		if direction != 0:
			velocity.x = move_toward(velocity.x, direction * current_max_speed, current_max_speed * acceleration)
			animated_sprite.flip_h = direction < 0
		else:
			velocity.x = move_toward(velocity.x, 0, walk_speed * deceleration)
		
	# Funny thing to avoid stepping on each other :D
	update_animations(direction)

	move_and_slide()

#bullet stuff idk what i am doing this guy aint explaining shit
func shooting(delta: float) -> void:
	if.Input.is_action_just_pressed("shoot"):
		var bullet_instance = BULLET.instantiate()
		get_tree().root.add_child(bullet_instance)
		

func update_animations(direction: float) -> void:
	if is_dashing:
		animated_sprite.play("Dash")
	elif not is_on_floor():
		animated_sprite.play("Jump")
	visible_on_ground_anims(direction)

func visible_on_ground_anims(direction: float) -> void:
	if is_on_floor() and not is_dashing:
		if direction != 0:
			if Input.is_action_pressed("run"):
				animated_sprite.play("Run")
			else:
				animated_sprite.play("Walk")
		else:
			animated_sprite.play("Idle") 
#this is the climbing branch
