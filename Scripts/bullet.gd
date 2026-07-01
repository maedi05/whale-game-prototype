extends CharacterBody2D

@export var speed: float = 2000.0
@export var lifetime: float = 2.0   # seconds before auto‑destroy

var pos: Vector2
var rota: float
var dir: float

func _ready():
	global_position = pos
	global_rotation = rota
	
	# Auto‑destroy timer
	var timer = Timer.new()
	timer.wait_time = lifetime
	timer.one_shot = true
	add_child(timer)
	timer.start()
	timer.timeout.connect(queue_free)

func _physics_process(_delta):
	velocity = Vector2(speed, 0).rotated(dir)
	move_and_slide()
	
	# If we hit something, destroy the bullet
	if get_last_slide_collision():
		queue_free()
