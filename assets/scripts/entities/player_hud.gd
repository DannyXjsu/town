extends Control

@onready var info_speed = %speed
@onready var info_velocity = %velocity


func set_info_speed(value : float):
	info_speed.text = "PLAYER_SPEED: " + str(value)

func set_info_velocity(vector_val : Vector3):
	info_velocity.text = "velocity.x: " + str(vector_val.x) + "\nvelocity.y: " + str(vector_val.y) + "\nvelocity.z: " + str(vector_val.z)
