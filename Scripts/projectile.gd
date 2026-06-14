extends CharacterBody2D

@export var PROJECTILESPEED = 50

var dir: float
var spawnPos: Vector2
var spawnRot: float

func _ready():
	global_position = spawnPos
	global_rotation = spawnRot

func _physics_process(delta):
	velocity = Vector2(0, - PROJECTILESPEED).rotated(dir)
	move_and_slide()
	
	
