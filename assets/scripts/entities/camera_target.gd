extends Camera3D

@export var target : Node3D

var lerp_target : Vector3
var lerp_target_pos : Vector3

# Called when the node enters the scene tree for the first time.
func _ready():
	lerp_target = target.global_position

func _physics_process(delta):
	lerp_target = lerp(lerp_target, target.global_position, 2*delta)
	lerp_target_pos = lerp(lerp_target_pos, target.global_position, 0.25*delta) # Used for self camera pos
	
	position = lerp_target_pos + target.transform.basis.y * 3 + target.transform.basis.z * -10

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	look_at(lerp_target)
