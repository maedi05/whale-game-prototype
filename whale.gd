extends CharacterBody2D

# ---- Nodes ----
@onready var body: Line2D = $body
@onready var limb_left: Line2D = $limb_left
@onready var limb_right: Line2D = $limb_right
@onready var fin: Line2D = $fin
@onready var fin_left: Line2D = $fin_left
@onready var fin_right: Line2D = $fin_right

# ---- Exported parameters ----
@export var radius: int = 20
@export var fin_radius: int = 20
@export var fin_pos: int = 9
@export var limb_angle: float = 0.8
@export var fin_angle: float = 0.8

@export var max_turn_speed: float = 3.0
@export_range(0.0, 1000.0, 10.0) var acceleration: float = 500.0
@export_range(0.0, 1.0, 0.01) var friction: float = 0.92
@export_range(0.0, 500.0, 10.0) var max_speed: float = 250.0

# ---- Feature toggles ----
@export var enable_bullets: bool = true
@export var enable_circle_attack: bool = true

# ---- Circle attack ----
@export var circle_color: Color = Color.WHITE
@export var circle_max_radius: float = 200.0
@export var circle_grow_duration: float = 3.0
@export var circle_fade_duration: float = 1.0
@export var circle_cooldown: float = 1.0
@export var circle_attach_point: int = 0

var velocity_m: Vector2 = Vector2.ZERO
var heading: Vector2 = Vector2.UP

# Bullet stuff
var bullet_path = preload("res://Scenes/bullet.tscn")

# Circle state
var circle_active: bool = false
var circle_radius: float = 0.0
var circle_alpha: float = 0.0
var can_trigger_circle: bool = true
var circle_tween: Tween
var circle_cooldown_timer: Timer

func _ready():
	_initialize_geometry()
	_setup_circle_timer()

func _process(delta: float):
	_update_movement(delta)
	_update_body(delta)
	_update_limbs()
	_update_tail()
	
	if circle_active:
		queue_redraw()
		
func _draw():
	if not circle_active:
		return
	var attach_pos = body.points[circle_attach_point]
	var color = Color(circle_color.r, circle_color.g, circle_color.b, circle_alpha)
	draw_circle(attach_pos, circle_radius, color)

func _input(event: InputEvent):
	# Circle attack – only if enabled and the circle can trigger
	if event.is_action_pressed("shoot") and enable_circle_attack and can_trigger_circle:
		_start_circle_attack()
	
	# Bullet firing – only if enabled
	if event.is_action_pressed("shoot") and enable_bullets:
		fire()

# ----- Initialisation helpers -----
func _initialize_geometry():
	var pts = body.points
	for i in pts.size():
		pts[i] = Vector2(0, i * radius)
	body.points = pts
	
	_init_chain(limb_left, -10.0)
	_init_chain(limb_right, 10.0)
	_init_chain(fin, 0.0, fin_pos)
	_init_chain(fin_left, -10.0, fin_pos)
	_init_chain(fin_right, 10.0, fin_pos)
	
	limb_left.points[0] = body.points[1]
	limb_right.points[0] = body.points[1]
	fin.points[0] = body.points[fin_pos]
	fin_left.points[0] = body.points[fin_pos]
	fin_right.points[0] = body.points[fin_pos]

func _init_chain(line: Line2D, x_offset: float, start_index: int = 0):
	var p = line.points
	for i in p.size():
		p[i] = Vector2(x_offset, (start_index + i) * radius)
	line.points = p

func _setup_circle_timer():
	circle_cooldown_timer = Timer.new()
	circle_cooldown_timer.one_shot = true
	add_child(circle_cooldown_timer)
	circle_cooldown_timer.timeout.connect(_on_circle_cooldown_finished)

# ----- Movement -----
func _update_movement(delta: float):
	var input = Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("down") - Input.get_action_strength("up")
	)
	
	if input != Vector2.ZERO:
		var target = input.normalized()
		if velocity.length() > 0.1:
			var angle_diff = velocity.normalized().angle_to(target)
			var max_angle = max_turn_speed * delta
			if abs(angle_diff) > max_angle:
				angle_diff = sign(angle_diff) * max_angle
			velocity = velocity.rotated(angle_diff)
			heading = velocity.normalized()
		else:
			heading = target
		velocity += heading * acceleration * delta
		velocity = velocity.limit_length(max_speed)
	else:
		velocity *= pow(friction, delta)
		if velocity.length() < 0.1:
			velocity = Vector2.ZERO
		if velocity.length() > 0:
			heading = velocity.normalized()
	
	global_position += velocity * delta

# ----- Body chain -----
func _update_body(delta: float):
	var pts = body.points.duplicate()
	pts[0] += velocity * delta
	for i in range(1, pts.size()):
		var dir = pts[i] - pts[i - 1]
		if dir.length() > radius:
			pts[i] = pts[i - 1] + dir.normalized() * radius
	var offset = pts[0]
	for i in pts.size():
		pts[i] -= offset
	body.points = pts

# ----- Limbs -----
func _update_limbs():
	var body_pts = body.points
	var root_idx = 1
	_update_pectoral(limb_left, body_pts, root_idx, -limb_angle)
	_update_pectoral(limb_right, body_pts, root_idx, limb_angle)

func _update_pectoral(line: Line2D, body_pts: PackedVector2Array, root_idx: int, angle_offset: float):
	var pts = line.points.duplicate()
	pts[0] = body_pts[root_idx]
	for i in range(1, pts.size()):
		var body_dir = (body_pts[i] - body_pts[i - 1]).normalized()
		var dir = body_dir.rotated(angle_offset)
		pts[i] = pts[i - 1] + dir * radius
	line.points = pts

# ----- Tail -----
func _update_tail():
	var body_pts = body.points
	var base_idx = fin_pos
	var tail_base = body_pts[base_idx]
	var tail_dir = (body_pts[base_idx] - body_pts[base_idx - 1]).normalized()
	
	var fin_pts = fin.points.duplicate()
	fin_pts[0] = tail_base
	for i in range(1, fin_pts.size()):
		var dir = fin_pts[i] - fin_pts[i - 1]
		if dir.length() > radius:
			fin_pts[i] = fin_pts[i - 1] + dir.normalized() * radius
	fin.points = fin_pts
	
	var l_pts = fin_left.points.duplicate()
	l_pts[0] = tail_base
	var l_dir = tail_dir.rotated(-PI / 2 + fin_angle)
	for i in range(1, l_pts.size()):
		l_pts[i] = l_pts[i - 1] + l_dir * fin_radius
	fin_left.points = l_pts
	
	var r_pts = fin_right.points.duplicate()
	r_pts[0] = tail_base
	var r_dir = tail_dir.rotated(PI / 2 - fin_angle)
	for i in range(1, r_pts.size()):
		r_pts[i] = r_pts[i - 1] + r_dir * fin_radius
	fin_right.points = r_pts

# ----- Bullet firing -----
func fire():
	if not enable_bullets:  # extra safety
		return
	var bullet = bullet_path.instantiate()
	var mouse_pos = get_global_mouse_position()
	var angle_to_mouse = (mouse_pos - global_position).angle()
	
	bullet.dir = angle_to_mouse
	bullet.pos = $bullet_mouth.global_position
	bullet.rota = angle_to_mouse
	get_parent().add_child(bullet)

# ----- Circle attack -----
func _start_circle_attack():
	if not enable_circle_attack:  # extra safety
		return
	can_trigger_circle = false
	circle_active = true
	circle_radius = 0.0
	circle_alpha = 1.0
	
	if circle_tween and circle_tween.is_valid():
		circle_tween.kill()
	
	circle_tween = create_tween()
	circle_tween.tween_property(self, "circle_radius", circle_max_radius, circle_grow_duration)\
		.set_trans(Tween.TRANS_QUAD)
	circle_tween.tween_property(self, "circle_alpha", 0.0, circle_fade_duration)\
		.set_delay(0.1)
	circle_tween.tween_callback(_on_circle_fade_finished)

func _on_circle_fade_finished():
	circle_active = false
	circle_radius = 0.0
	circle_alpha = 0.0
	queue_redraw()
	circle_cooldown_timer.start(circle_cooldown)

func _on_circle_cooldown_finished():
	can_trigger_circle = true
