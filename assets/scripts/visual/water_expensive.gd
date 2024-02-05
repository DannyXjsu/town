extends Node3D

@onready var camera_3d = $SubViewport/Camera3D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#camera_3d.transform.origin.y = get_tree().root.get_viewport().get_camera_3d().transform.origin.y
	camera_3d.rotation = -get_tree().root.get_viewport().get_camera_3d().rotation
	pass
