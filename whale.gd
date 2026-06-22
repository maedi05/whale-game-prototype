extends Node2D

@onready var body: Line2D = $body
@onready var limb_left: Line2D = $limb_left
@onready var limb_right: Line2D = $limb_right
@onready var fin: Line2D = $fin #tail of the fish, duh

@export var radius :int = 20
@export var fin_pos :int = 8 # just the point of the array of the body where the fin gets placed
@export var limb_angle :float = 0.8
@export var velocity :int = 250
var is_moving = false

func _ready() -> void:
	for i in range(0,body.points.size()):
		body.points[i] = Vector2(i*2, 200.0) # sets the body point amount ig? he didn't explain it well but as long as it works lol
		
		#creating points for the limbs
	for i in range(1,limb_left.points.size()):
		limb_left.points[i] = Vector2(i*2, -200.0)
		
	for i in range(1, limb_right.points.size()):
		limb_right.points[i] = Vector2(i*2, 400.0)
	
	#creating points for the fin (tail)
	for i in range(1, fin.points.size()):
		fin.points[i] = Vector2(i*2, 400.0)
	
	#attaching limbs and fin to the body
	limb_left.points[0] = body.points[1]
	limb_right.points[0] = body.points[1]
	fin.points[0] = body.points[fin_pos]
	
#drawing points for procedural animation :)
func _process(delta: float) -> void:
	var body_pts = body.points #shortening body.points to just body_pts. nice. i am sure that won't confuse me in the future xD
	var lb_lf_pts = limb_left.points
	var lb_rf_pts = limb_right.points #rf for "right"? alright tutorial guy xD
	var fin_pts = fin.points
	
	#basic movement... this needs some proper changes with tweens or smth for smoother start and stop
	var move = Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("down") - Input.get_action_strength("up")
	) 
	
	if move != Vector2.ZERO:
		is_moving = true
		body_pts[0] += move * velocity * delta #400 is velocity/ speed in our case
	else:
		is_moving = false # i made this myself for future use so i can have a afk animation,omg i can code now TvT (xD barely but still)
		
		#updating the limb points to move with the main body
	lb_lf_pts[0] = lb_lf_pts[0].move_toward(body_pts[1],200 * delta)
	lb_rf_pts[0] = lb_rf_pts[0].move_toward(body_pts[1],200 * delta)
	fin_pts[0] = fin_pts[0].move_toward(body_pts[fin_pos],200 * delta) # in that case fin_pos is just 8, meaning it is placed at the 8th point of the body points chain. idk why the tutorial guy made that a variable but decided not to do the same for the limbs aka fins but okay x.x
	
	#moving the anchor head point (again? o.o me confused)
	if move != Vector2.ZERO and body_pts.size() > 0:
		body_pts[0] += move * velocity * delta
	#attaching the left and right limb to the second point in the array of the body
		lb_lf_pts[0] = body_pts[1]
		lb_rf_pts[0] = body_pts[1]
		fin_pts[0] = body_pts[fin_pos]
	#the all-in-one package to move points after eachother. yay. makes it so it applies to every single point in the body and saves me a lot of lines of code
	for i in range(1, body_pts.size()):
		body_pts[i] = body_pts[i - 1] + (body_pts[i] - body_pts[i -1]).limit_length(radius)
		body.points = body_pts
	
	#Constrain left limb with fixed angular offset
	for i in range(1, lb_lf_pts.size()):
		var body_dir = (body_pts[i] - body_pts[i - 1]).normalized()
		var offset_dir = body_dir.rotated(-limb_angle) #fixed offset
		lb_lf_pts[i] = lb_lf_pts[i - 1] + offset_dir * radius
	limb_left.points = lb_lf_pts
	
	#Constrain right limb with fixed angular offset
	for i in range(1, lb_rf_pts.size()):
		var body_dir = (body_pts[i] - body_pts[i - 1]).normalized()
		var offset_dir = body_dir.rotated(limb_angle) #fixed offset instead of minus limb angle we just put the positive one instead B) so its mirrored. yay im smart
		lb_rf_pts[i] = lb_rf_pts[i - 1] + offset_dir * radius
	limb_right.points = lb_rf_pts
	
	#constrain the fin to the right end of the array
	for i in range(1, fin_pts.size()):
		fin_pts[i] = fin_pts[i - 1] + (fin_pts[i] - fin_pts[i - 1]).limit_length(radius)
		fin.points = fin_pts

	queue_redraw()


#mf said nuh uh. we don't need that anymore T.T what is this tutorial. dont make me do all of dat if i wont use it anyway, aaa

#var anchor :Vector2 = Vector2(200.0,200.0) 
#var point :Vector2 = Vector2(200.0,400.0)

#pts[1] = pts[0] + (pts[1] - pts[0]).limit_length(100) # pts 0 in this case is the first point......bro literially said we don't need this anymore just to prove a point lmao, okay?

#func _draw() -> void:
	#draw_circle (anchor, 10, "white")
	#draw_line(anchor,point,"red",5) # we draw a line starting from point "anchor" to point "point" which has the color red and a set width
	#draw_circle (point, 10, "green")
	
