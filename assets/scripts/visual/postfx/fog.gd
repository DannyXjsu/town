extends Node3D

@onready var camera_3d = $Camera3D

# Called when the node enters the scene tree for the first time.
func _ready():
	get_viewport().size = get_tree().root.get_viewport().size


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	camera_3d.transform = get_tree().root.get_viewport().get_camera_3d().get_camera_transform()
	if get_viewport().size != get_tree().root.get_viewport().size:
		get_viewport().size = get_tree().root.get_viewport().size
