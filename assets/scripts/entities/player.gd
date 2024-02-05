extends CharacterBody3D

const MAX_SPEED : float = 2.5
const MAX_SPRINT_SPEED : float = MAX_SPEED * 2.65
const MAX_CROUCH_SPEED : float = 1.2
const MAX_ACCEL : float = 10 * MAX_SPEED
const MAX_AIR_ACCEL : float = 0.5
const FRICTION_FLOOR_STRENGHT = 1.12
#const FRICTION_FLOOR_STRENGHT = 1.0
const FRICTION_AIR_STRENGHT = 1.00001
const JUMP_FORCE : float  = 3.25/1.4

const PLAYER_HEIGHT : float = 2.0
const PLAYER_CROUCH_HEIGHT : float = 1.38
const PLAYER_HEAD_HEIGHT : float = 1.75
const PLAYER_HEAD_CROUCH_HEIGHT : float = 1.75/PLAYER_CROUCH_HEIGHT
const PLAYER_DEAD_HEAD_ANGULAR_DAMP : float = 2.15
const PLAYER_RAGDOLL_MIN_VELOCITY : float = 12.5
const PLAYER_RAGDOLL_SND_IMPACT_HARD_MIN : float = 7.15
const PLAYER_RAGDOLL_SND_IMPACT_MEDIUM_MIN : float = 4.0
const PLAYER_RAGDOLL_SND_IMPACT_SOFT_MIN : float = 0.5
const PLAYER_RAGDOLL_START_IMPULSE_FORCE : float = 1.0 # Very buggy, avoid using

# BOOL
var is_crouching : bool = false
var is_sprinting : bool = false
var is_near_ledge : bool = false
var is_dead : bool = false
var is_ragdolling : bool = false

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity") * 1.5
var mouse_sensitivity : float  = ProjectSettings.get_setting("game/mouse/sensitivity")

@onready var editor = %Editor
@onready var editor_pivot = %"Editor Pivot"
@onready var editor_velocity = %"Editor Velocity"
@onready var editor_direction = %"Editor Direction"
@onready var editor_body = %Body
var editor_direction_lerp : Vector3 = Vector3.ZERO 

@onready var hud = %HUD

@onready var head = %Head
@onready var camera = %Camera
@onready var pivot = %Pivot
@onready var collision = %Collision

@onready var ledge_ray_hor = %hor
@onready var ledge_ray_ver = %ver

# SOUNDS
@onready var audio_stream_player = %AudioStreamPlayer
const SND_BODY_IMPACT_SOFT_1 = preload("res://assets/sounds/physics/body/body_medium_impact_soft1.wav")
const SND_BODY_IMPACT_SOFT_2 = preload("res://assets/sounds/physics/body/body_medium_impact_soft2.wav")
const SND_BODY_IMPACT_SOFT_3 = preload("res://assets/sounds/physics/body/body_medium_impact_soft3.wav")
const SND_BODY_IMPACT_SOFT_4 = preload("res://assets/sounds/physics/body/body_medium_impact_soft4.wav")
const SND_BODY_IMPACT_SOFT_5 = preload("res://assets/sounds/physics/body/body_medium_impact_soft5.wav")
const SND_BODY_IMPACT_SOFT_6 = preload("res://assets/sounds/physics/body/body_medium_impact_soft6.wav")
const SND_BODY_IMPACT_SOFT_7 = preload("res://assets/sounds/physics/body/body_medium_impact_soft7.wav")
const SND_BODY_IMPACT_MEDIUM_1 = preload("res://assets/sounds/physics/body/body_medium_impact_hard1.wav")
const SND_BODY_IMPACT_MEDIUM_2 = preload("res://assets/sounds/physics/body/body_medium_impact_hard2.wav")
const SND_BODY_IMPACT_MEDIUM_3 = preload("res://assets/sounds/physics/body/body_medium_impact_hard3.wav")
const SND_BODY_IMPACT_MEDIUM_4 = preload("res://assets/sounds/physics/body/body_medium_impact_hard4.wav")
const SND_BODY_IMPACT_MEDIUM_5 = preload("res://assets/sounds/physics/body/body_medium_impact_hard5.wav")
const SND_BODY_IMPACT_MEDIUM_6 = preload("res://assets/sounds/physics/body/body_medium_impact_hard6.wav")
const SND_BODY_IMPACT_HARD_1 = preload("res://assets/sounds/physics/body/body_medium_break2.wav")
const SND_BODY_IMPACT_HARD_2 = preload("res://assets/sounds/physics/body/body_medium_break3.wav")
const SND_BODY_IMPACT_HARD_3 = preload("res://assets/sounds/physics/body/body_medium_break4.wav")
const SND_BODY_SCRAPE_SMOOTH_LOOP_1 = preload("res://assets/sounds/physics/body/body_medium_scrape_smooth_loop1.wav")

@onready var sound_impact_soft = [
	SND_BODY_IMPACT_SOFT_1,
	SND_BODY_IMPACT_SOFT_2,
	SND_BODY_IMPACT_SOFT_3,
	SND_BODY_IMPACT_SOFT_4,
	SND_BODY_IMPACT_SOFT_5,
	SND_BODY_IMPACT_SOFT_6,
	SND_BODY_IMPACT_SOFT_7
]
@onready var sound_impact_medium = [
	SND_BODY_IMPACT_MEDIUM_1,
	SND_BODY_IMPACT_MEDIUM_2,
	SND_BODY_IMPACT_MEDIUM_3,
	SND_BODY_IMPACT_MEDIUM_4,
	SND_BODY_IMPACT_MEDIUM_5,
	SND_BODY_IMPACT_MEDIUM_6
]
@onready var sound_impact_hard = [
	SND_BODY_IMPACT_HARD_1,
	SND_BODY_IMPACT_HARD_2,
	SND_BODY_IMPACT_HARD_3
]

@onready var sound_scrape_soft = [
	SND_BODY_SCRAPE_SMOOTH_LOOP_1
]

@export_category("Debug")
@export var draw_editor_things : bool = false

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Remove stuff that is only supposed to be visible on the editor
	if !draw_editor_things:
		editor.queue_free()

func _input(event):
	if event is InputEventMouseMotion:
		# modify accumulated mouse rotation
		if !is_ragdolling:
			pivot.rotate_y(-event.relative.x * mouse_sensitivity)
			head.rotate_x(-event.relative.y * mouse_sensitivity)
			head.rotation.x = clamp(head.rotation.x,-PI/2, PI/2)
			
		if draw_editor_things:
			editor_pivot.rotation = pivot.rotation
	elif event is InputEventKey:
		if Input.is_action_just_pressed("ragdoll_toggle"):
			if !is_ragdolling:
				ragdoll()
			else:
				if not is_dead:
					ragdoll_wakeup()
		if Input.is_key_pressed(KEY_K):
			die()

func die():
	if !is_dead:
		ragdoll()
		is_dead = true

var ragdoll_head_rbody : RigidBody3D
var ragdoll_head_col : CollisionShape3D
var ragdoll_old_head : Node3D
func ragdoll():
	if !is_ragdolling:
		is_ragdolling = true
		# fall_dir is going to be used to determine which direction (we also get the magnitude from
		# the velocity vector) we will be falling to. If we are mid-air we don't need to worry so
		# much about this, so we just use the velocity vector from Godot's CharacterBody3D. If we
		# are on the floor, we need to maintain the floor direction, we can do this with V+N*(V·(-N)),
		# where V is the velocity vector and N is the floor normal. This way, whenever we ragdoll, we 
		# fall perpendicular to the floor direction.
		# This method is not perfect due to how Godot handles the CharacterBody3D on the floor,
		# but the inconsistency is barely noticeable.
		var fall_dir : Vector3
		# Before disabling collision, we need to get a few floor values
		if is_on_floor():
			fall_dir = velocity + get_floor_normal() * velocity.dot(-get_floor_normal())
		else:
			fall_dir = velocity
		collision.set_deferred("disabled", true)
		
		ragdoll_head_rbody = RigidBody3D.new()
		ragdoll_head_col = CollisionShape3D.new()
		ragdoll_old_head = Node3D.new()
		ragdoll_head_rbody.name = "PLAYER_RAGDOLL_BODY_" + str(ragdoll_head_rbody.get_instance_id())
		ragdoll_head_col.name = "PLAYER_RAGDOLL_BODY_COLLISION_" + str(ragdoll_head_col.get_instance_id())
		ragdoll_old_head.name = "PLAYER_HEAD_TEMPORARY_" + str(ragdoll_old_head.get_instance_id())
		
		pivot.add_child(ragdoll_old_head)
		ragdoll_old_head.position = head.position
		ragdoll_head_col.rotation = head.rotation
		add_child(ragdoll_head_rbody)
		ragdoll_head_rbody.add_child(ragdoll_head_col)
		ragdoll_head_col.shape = CapsuleShape3D.new()
		ragdoll_head_col.shape.height = 1.25
		ragdoll_head_rbody.angular_damp = PLAYER_DEAD_HEAD_ANGULAR_DAMP
		ragdoll_head_rbody.contact_monitor = true
		
		ragdoll_head_rbody.position = head.position
		ragdoll_head_rbody.reparent(get_tree().root)
		head.reparent(ragdoll_head_rbody)
		head.position = Vector3.ZERO
		#camera.position = Vector3.ZERO
		ragdoll_head_rbody.apply_impulse(fall_dir * PLAYER_RAGDOLL_START_IMPULSE_FORCE)
		velocity = Vector3.ZERO

func ragdoll_wakeup():
	if is_ragdolling:
		is_ragdolling = false
		head.reparent(pivot)
		head.position = ragdoll_old_head.position
		head.rotation = ragdoll_head_col.rotation
		position = ragdoll_head_rbody.position
		position.y -= ragdoll_head_col.shape.radius
		velocity = ragdoll_head_rbody.linear_velocity
		
		ragdoll_old_head.queue_free()
		ragdoll_head_col.queue_free()
		ragdoll_head_rbody.queue_free()
		
		collision.set_deferred("disabled", false)
		audio_stream_player.stream = null

func _process(_delta):
	hud.set_info_speed(velocity.length())
	hud.set_info_velocity(velocity)
	
	if position.y < -20:
		position = Vector3.ZERO
		
	# Ledge Detection
	if ledge_ray_hor.is_colliding():
		var hor_col_point : Vector3 = ledge_ray_hor.get_collision_point()
		var dist : float = Vector3(ledge_ray_hor).distance_to(hor_col_point)
		if ledge_ray_ver.is_colliding():
			is_near_ledge = true
	elif ledge_ray_ver.is_colliding():
		var ver_col_point : Vector3 = ledge_ray_ver.get_collision_point()
		ledge_ray_hor.position.z = (ver_col_point * pivot.transform.basis.z).z
		if ledge_ray_ver.is_colliding():
			is_near_ledge = true

func jump():
	velocity += get_floor_normal() + Vector3.UP * JUMP_FORCE * sqrt(collision.shape.size.y)

@onready var _stored_vel = 0.0
func _physics_process(delta):
	# Handle Ragdolling
	if velocity.length() > PLAYER_RAGDOLL_MIN_VELOCITY:
		ragdoll()
	if !is_ragdolling:
		# Add the gravity.
		if not is_on_floor():
			velocity.y -= gravity * delta
		
		# Handle jump.
		if Input.is_action_pressed("jump") and is_on_floor():
			jump()
		
		# Handle crouch.
		if Input.is_action_pressed("crouch"):
			is_crouching=true
			collision.shape.size.y = PLAYER_CROUCH_HEIGHT
			collision.position.y = PLAYER_CROUCH_HEIGHT/2.0
			head.position.y = PLAYER_HEAD_CROUCH_HEIGHT
			if draw_editor_things:
				editor_body.mesh.size.y = PLAYER_CROUCH_HEIGHT
				editor_body.position.y = PLAYER_CROUCH_HEIGHT/2.0
		else:
			is_crouching=false
			collision.shape.size.y = PLAYER_HEIGHT
			collision.position.y = PLAYER_HEIGHT/PLAYER_HEIGHT
			head.position.y = PLAYER_HEAD_HEIGHT
			if draw_editor_things:
				editor_body.mesh.size.y = PLAYER_HEIGHT
				editor_body.position.y = PLAYER_HEIGHT/PLAYER_HEIGHT

		# Handle sprint.
		if Input.is_action_pressed("move_sprint"):
			is_sprinting = true
		else:
			is_sprinting = false
		
		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var input_dir : Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		var direction : Vector3 = (pivot.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if draw_editor_things:
			# Velocity arrow
			if not velocity.is_zero_approx():
				editor_velocity.look_at(to_global(Vector3(velocity.x,0.0,velocity.z)))
				#editor_velocity.scale.z = clamp(smoothstep(editor_velocity.scale.z, Vector2(velocity.x,velocity.z).length_squared()/2, 1.0), 0.5, 10.0)
			# Wishdir arrow
			if direction:
				editor_direction_lerp = lerp(editor_direction_lerp, direction, 1)
				editor_direction.look_at(to_global(editor_direction_lerp))
			
		if is_on_floor():
			var max_speed
			var max_accel
			if not is_crouching:
				if not is_sprinting:
					max_speed = MAX_SPEED
					max_accel = MAX_ACCEL
				else:
					max_speed = MAX_SPRINT_SPEED
					max_accel = MAX_SPRINT_SPEED * 10
			else:
				max_speed = MAX_CROUCH_SPEED
				max_accel = MAX_CROUCH_SPEED *10
				
			# TODO: Apply friction to velocity
			# friction()
			velocity /= FRICTION_FLOOR_STRENGHT
			
			# Adding velocity on floor
			var cur_speed = velocity.dot(direction)
			var add_speed = clampf(max_speed -  cur_speed, 0.0, max_accel * delta)
			
			velocity += add_speed * direction
		else:
			# Adding velocity on air
			var cur_speed = velocity.dot(direction)
			var add_speed = clampf(MAX_AIR_ACCEL -  cur_speed, 0.0, MAX_ACCEL * delta)
			 
			velocity /= pow(FRICTION_AIR_STRENGHT, velocity.length())
			velocity += add_speed * direction
		
		if velocity.is_zero_approx():
			velocity = Vector3.ZERO
		move_and_slide()
	else: #IS RAGDOLLING
		# Handling ragdoll impact force
		if abs(_stored_vel - ragdoll_head_rbody.linear_velocity.length()) > PLAYER_RAGDOLL_SND_IMPACT_HARD_MIN:
			if ragdoll_head_rbody.body_entered:
				audio_stream_player.stream = sound_impact_hard[randi_range(0, sound_impact_hard.size()-1)]
				audio_stream_player.play()
		elif (abs(_stored_vel - ragdoll_head_rbody.linear_velocity.length()) > PLAYER_RAGDOLL_SND_IMPACT_MEDIUM_MIN):
			if ragdoll_head_rbody.body_entered:
				audio_stream_player.stream = sound_impact_medium[randi_range(0, sound_impact_medium.size()-1)]
				audio_stream_player.play()
		elif (abs(_stored_vel - ragdoll_head_rbody.linear_velocity.length()) > PLAYER_RAGDOLL_SND_IMPACT_SOFT_MIN):
			if ragdoll_head_rbody.body_entered:
				audio_stream_player.stream = sound_impact_soft[randi_range(0, sound_impact_soft.size() -1)]
				audio_stream_player.play()
				
		_stored_vel = ragdoll_head_rbody.linear_velocity.length() # Refreshing old frame value
