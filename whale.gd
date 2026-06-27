extends Node2D

@onready var body: Line2D = $body
@onready var limb_left: Line2D = $limb_left
@onready var limb_right: Line2D = $limb_right
@onready var fin: Line2D = $fin
@onready var fin_left: Line2D = $fin_left
@onready var fin_right: Line2D = $fin_right

# --- CONFIG ---
@export var radius :int = 20
@export var fin_radius :int = 20
@export var fin_pos :int = 9          # Which body point the tail attaches to
@export var limb_angle :float = 0.8   # Pectoral fin spread (i dont even know what pectoral means lmao)
@export var fin_angle :float = 0.8    # Tail fluke spread (i think it meant the tail fins lol)
@export var velocity :int = 250

# NEW: turning smoothness
@export var max_turn_speed : float = 3.0   # radians per second

var is_moving = false
var head_dir : Vector2 = Vector2.RIGHT     # current heading direction

func _ready() -> void:
	# Initialize straight shapes
	for i in range(0, body.points.size()):
		body.points[i] = Vector2(i*2, 200.0)
	for i in range(1, limb_left.points.size()):
		limb_left.points[i] = Vector2(i*2, -200.0)
	for i in range(1, limb_right.points.size()):
		limb_right.points[i] = Vector2(i*2, 400.0)
	for i in range(1, fin.points.size()):
		fin.points[i] = Vector2(i*2, 400.0)
	for i in range(1, fin_left.points.size()):
		fin_left.points[i] = Vector2(i*2, -200.0)
	for i in range(1, fin_right.points.size()):
		fin_right.points[i] = Vector2(i*2, 400.0)
	
	# Attach bases
	limb_left.points[0] = body.points[1]
	limb_right.points[0] = body.points[1]
	fin.points[0] = body.points[fin_pos]
	fin_left.points[0] = body.points[fin_pos]
	fin_right.points[0] = body.points[fin_pos]

func _process(delta: float) -> void:
	var body_pts = body.points
	var lb_lf_pts = limb_left.points
	var lb_rf_pts = limb_right.points
	var fin_pts = fin.points
	var fin_l_pts = fin_left.points
	var fin_r_pts = fin_right.points
	
	# --- 1. INPUT & HEAD MOVEMENT (with smooth turning) ---
	var move_input = Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("down") - Input.get_action_strength("up")
	)
	
	if move_input != Vector2.ZERO:
		is_moving = true
		var target_dir = move_input.normalized()
		# Compute the angle between current heading and desired direction
		var angle_diff = head_dir.angle_to(target_dir)
		# Clamp the rotation to max_turn_speed per second
		var max_angle = max_turn_speed * delta
		if abs(angle_diff) > max_angle:
			angle_diff = sign(angle_diff) * max_angle
		head_dir = head_dir.rotated(angle_diff)
		# Move the head in the smoothed direction
		body_pts[0] += head_dir * velocity * delta
	else:
		is_moving = false
	
	# --- 2. BODY CHAIN CONSTRAINT
	# Each segment follows the previous one with a fixed distance (radius)
	for i in range(1, body_pts.size()):
		body_pts[i] = body_pts[i - 1] + (body_pts[i] - body_pts[i - 1]).limit_length(radius)
	body.points = body_pts 
	
	# --- 3. PECTORAL LIMBS (Left & Right - unchanged) ---
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
	
	# --- 4. TAIL BASE (Middle spike - unchanged) ---
	fin_pts[0] = body_pts[fin_pos]
	for i in range(1, fin_pts.size()):
		fin_pts[i] = fin_pts[i - 1] + (fin_pts[i] - fin_pts[i - 1]).limit_length(radius)
	fin.points = fin_pts
	
	# --- 5. TAIL FLUKES (FIXED - now correctly follows the TAIL) ---
	var tail_base = body_pts[fin_pos]
	var tail_dir = (body_pts[fin_pos] - body_pts[fin_pos - 1]).normalized()
	
	# left fin placement
	fin_l_pts[0] = tail_base
	var left_lobe_dir = tail_dir.rotated(-PI/2 + fin_angle)
	for i in range(1, fin_l_pts.size()):
		fin_l_pts[i] = fin_l_pts[i-1] + left_lobe_dir * fin_radius
	fin_left.points = fin_l_pts
	
	# right fin placement
	fin_r_pts[0] = tail_base
	var right_lobe_dir = tail_dir.rotated(PI/2 - fin_angle)
	for i in range(1, fin_r_pts.size()):
		fin_r_pts[i] = fin_r_pts[i-1] + right_lobe_dir * fin_radius
	fin_right.points = fin_r_pts
