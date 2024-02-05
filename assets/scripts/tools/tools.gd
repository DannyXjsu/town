class_name Tools
extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


static func ease_in(value):
	return pow(value,3.0)
