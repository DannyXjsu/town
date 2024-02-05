extends Node3D

@export_category("Clouds")
#@onready var mesh : MeshInstance3D = %Mesh
@export var shell_shader : Shader

@export_subgroup("Shader Parameters")
@export_range(1, 256*4) var shell_count : int = 16
@export_range(0.0,1.0) var shell_length : float = 0.15
@export_range(1.0,3.0) var distance_attenuation : float = 1.0
@export_range(1.0,5000.0) var density : float = 100.0
@export_range(0.0,1.0) var noise_min : float = 0.0
@export_range(0.0,1.0) var noise_max : float = 1.0
@export_range(0.0,10.0) var thickness : float = 1.0
@export_color_no_alpha var shell_color
@export_range(0.0, 5.0) var occlusion_attenuation : float = 1.0
@export_range(0.0, 1.0) var occlusion_bias : float = 0.0

#@onready var shell_material : ShaderMaterial = ShaderMaterial.new()
@onready var shells : Array = []
@onready var shell_materials : Array = []

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in range(shell_count):
		shells.insert(i, MeshInstance3D.new())
		shell_materials.insert(i, ShaderMaterial.new())
		shell_materials[i].shader = shell_shader
		shells[i].name = "Shell " + str(i)
		shells[i].mesh = SphereMesh.new()
		shells[i].material_override = shell_materials[i]
		shells[i].material_override.set_shader_parameter("_ShellCount", shell_count)
		shells[i].material_override.set_shader_parameter("_ShellIndex", i)
		shells[i].material_override.set_shader_parameter("_ShellLength", shell_length)
		shells[i].material_override.set_shader_parameter("_Density", density)
		shells[i].material_override.set_shader_parameter("_Thickness", thickness)
		shells[i].material_override.set_shader_parameter("_Attenuation", occlusion_attenuation)
		shells[i].material_override.set_shader_parameter("_ShellDistanceAttenuation", distance_attenuation)
		shells[i].material_override.set_shader_parameter("_NoiseMin", noise_min)
		shells[i].material_override.set_shader_parameter("_NoiseMax", noise_max)
		shells[i].material_override.set_shader_parameter("_ShellColor", shell_color)
		add_child(shells[i])


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
