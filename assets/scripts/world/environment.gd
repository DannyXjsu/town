extends Node3D

@onready var directional_light_3d = %DirectionalLight3D
@onready var world_environment = %WorldEnvironment

var time : float = 0
#var time_scale : float = 0.001
var time_scale : float = 0.1

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time += delta
	time = fmod(time, 60)
	
	
