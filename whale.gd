extends Node2D

# --- ORIGINAL BODY & LIMB VARIABLES ---
@onready var body: Line2D = $body
@onready var limb_left: Line2D = $limb_left
@onready var limb_right: Line2D = $limb_right
@onready var fin: Line2D = $fin
@onready var fin_left: Line2D = $fin_left
@onready var fin_right: Line2D = $fin_right

@export var radius :int = 20
@export var fin_radius :int = 20
@export var fin_pos :int = 9
@export var limb_angle :float = 0.8
@export var fin_angle :float = 0.8

@export var max_turn_speed : float = 3.0
@export_range(0.0, 1000.0, 10.0) var acceleration : float = 500.0
@export_range(0.0, 1.0, 0.01) var friction : float = 0.92
@export_range(0.0, 500.0, 10.0) var max_speed : float = 250.0

var current_velocity : Vector2 = Vector2.ZERO
var head_dir : Vector2 = Vector2.UP          # <-- facing upward initially

# --- NEW: CIRCLE ATTACK VARIABLES ---
@export var circle_color: Color = Color.WHITE
@export var circle_max_radius: float = 200.0
@export var circle_grow_duration: float = 3.0
@export var circle_fade_duration: float = 1.0
@export var circle_cooldown: float = 1.0
@export var circle_attach_point: int = 0   # body_pts index (0 = head)

# State
var circle_radius: float = 0.0
var circle_alpha: float = 0.0
var circle_active: bool = false
var circle_can_trigger: bool = true
var circle_cooldown_timer: Timer
var circle_tween: Tween

func _ready():
	# --- BODY: upright, head at (0,0), tail downward ---
	var base_body_pts = body.points
	for i in range(base_body_pts.size()):
		base_body_pts[i] = Vector2(0.0, i * radius)
	body.points = base_body_pts

	# --- LEFT LIMB (pectoral) ---
	var base_l_limb = limb_left.points
	for i in range(base_l_limb.size()):
		base_l_limb[i] = Vector2(-10.0, i * radius)
	limb_left.points = base_l_limb

	# --- RIGHT LIMB (pectoral) ---
	var base_r_limb = limb_right.points
	for i in range(base_r_limb.size()):
		base_r_limb[i] = Vector2(10.0, i * radius)
	limb_right.points = base_r_limb

	# --- TAIL BASE (fin) ---
	var base_fin = fin.points
	for i in range(base_fin.size()):
		base_fin[i] = Vector2(0.0, (fin_pos + i) * radius)
	fin.points = base_fin

	# --- LEFT FLUKE (tail lobe) ---
	var base_l_fin = fin_left.points
	for i in range(base_l_fin.size()):
		base_l_fin[i] = Vector2(-10.0, (fin_pos + i) * radius)
	fin_left.points = base_l_fin

	# --- RIGHT FLUKE (tail lobe) ---
	var base_r_fin = fin_right.points
	for i in range(base_r_fin.size()):
		base_r_fin[i] = Vector2(10.0, (fin_pos + i) * radius)
	fin_right.points = base_r_fin

	# Attach roots to the correct body points
	limb_left.points[0] = body.points[1]
	limb_right.points[0] = body.points[1]
	fin.points[0] = body.points[fin_pos]
	fin_left.points[0] = body.points[fin_pos]
	fin_right.points[0] = body.points[fin_pos]

	# --- CIRCLE TIMER (unchanged) ---
	circle_cooldown_timer = Timer.new()
	circle_cooldown_timer.one_shot = true
	add_child(circle_cooldown_timer)
	circle_cooldown_timer.timeout.connect(_on_circle_cooldown_finished)

func _process(delta: float):
	# Use duplicate() for safety – no more Array type errors
	var body_pts = body.points.duplicate()
	var lb_lf_pts = limb_left.points.duplicate()
	var lb_rf_pts = limb_right.points.duplicate()
	var fin_pts = fin.points.duplicate()
	var fin_l_pts = fin_left.points.duplicate()
	var fin_r_pts = fin_right.points.duplicate()
	
	# --- 1. INPUT & VELOCITY UPDATE ---
	var move_input = Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("down") - Input.get_action_strength("up")
	)
	
	if move_input != Vector2.ZERO:
		var target_dir = move_input.normalized()
		if current_velocity.length() > 0.1:
			var vel_dir = current_velocity.normalized()
			var angle_diff = vel_dir.angle_to(target_dir)
			var max_angle = max_turn_speed * delta
			if abs(angle_diff) > max_angle:
				angle_diff = sign(angle_diff) * max_angle
			current_velocity = current_velocity.rotated(angle_diff)
			head_dir = current_velocity.normalized()
		else:
			head_dir = target_dir
		current_velocity += head_dir * acceleration * delta
		if current_velocity.length() > max_speed:
			current_velocity = current_velocity.normalized() * max_speed
	else:
		var damping = pow(friction, delta)
		current_velocity *= damping
		if current_velocity.length() < 0.1:
			current_velocity = Vector2.ZERO
		if current_velocity.length() > 0:
			head_dir = current_velocity.normalized()
	
	# 1. Move the whole node in global space (camera follows)
	global_position += current_velocity * delta
	
	# 2. Move the head locally (creates the tail‑drag effect)
	body_pts[0] += current_velocity * delta
	
	# --- 2. BODY CHAIN ---
	for i in range(1, body_pts.size()):
		body_pts[i] = body_pts[i - 1] + (body_pts[i] - body_pts[i - 1]).limit_length(radius)
	
	# Shift the whole body so the head stays at (0,0) local
	var offset_to_zero = body_pts[0] - Vector2.ZERO
	for i in range(body_pts.size()):
		body_pts[i] -= offset_to_zero
		
	body.points = body_pts
	
	# --- 3. PECTORAL LIMBS ---
	lb_lf_pts[0] = body_pts[1]
	lb_rf_pts[0] = body_pts[1]
	for i in range(1, lb_lf_pts.size()):
		var body_dir = (body_pts[i] - body_pts[i - 1]).normalized()
		var offset_dir = body_dir.rotated(-limb_angle)
		lb_lf_pts[i] = lb_lf_pts[i - 1] + offset_dir * radius
	limb_left.points = lb_lf_pts
	
	for i in range(1, lb_rf_pts.size()):
		var body_dir = (body_pts[i] - body_pts[i - 1]).normalized()
		var offset_dir = body_dir.rotated(limb_angle)
		lb_rf_pts[i] = lb_rf_pts[i - 1] + offset_dir * radius
	limb_right.points = lb_rf_pts
	
	# --- 4. TAIL BASE ---
	fin_pts[0] = body_pts[fin_pos]
	for i in range(1, fin_pts.size()):
		fin_pts[i] = fin_pts[i - 1] + (fin_pts[i] - fin_pts[i - 1]).limit_length(radius)
	fin.points = fin_pts
	
	# --- 5. TAIL FLUKES ---
	var tail_base = body_pts[fin_pos]
	var tail_dir = (body_pts[fin_pos] - body_pts[fin_pos - 1]).normalized()
	
	fin_l_pts[0] = tail_base
	var left_lobe_dir = tail_dir.rotated(-PI/2 + fin_angle)
	for i in range(1, fin_l_pts.size()):
		fin_l_pts[i] = fin_l_pts[i-1] + left_lobe_dir * fin_radius
	fin_left.points = fin_l_pts
	
	fin_r_pts[0] = tail_base
	var right_lobe_dir = tail_dir.rotated(PI/2 - fin_angle)
	for i in range(1, fin_r_pts.size()):
		fin_r_pts[i] = fin_r_pts[i-1] + right_lobe_dir * fin_radius
	fin_right.points = fin_r_pts
	
	# --- REDRAW CIRCLE IF ACTIVE ---
	if circle_active:
		queue_redraw()

# --- DRAW THE CIRCLE AT THE ATTACHED POINT ---
func _draw():
	if not circle_active:
		return
	var attach_pos = body.points[circle_attach_point]
	var color = Color(circle_color.r, circle_color.g, circle_color.b, circle_alpha)
	draw_circle(attach_pos, circle_radius, color)

# --- INPUT HANDLING ---
func _input(event):
	if event.is_action_pressed("shoot") and circle_can_trigger:
		start_circle_attack()

# --- CIRCLE ATTACK LOGIC ---
func start_circle_attack():
	circle_can_trigger = false
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
	circle_can_trigger = true
