extends KinematicBody2D
class_name Player

var id: int setget set_id

func set_id(new_id: int):
	set_network_master(new_id)
	id = new_id

func _ready():
	_on_ready()

func _on_ready():
	._on_ready()
	
func _process(delta):
	_on_process(delta)

func _on_process(delta):
	._on_process(delta)
	
func _physics_process(delta):
	_on_physics_process(delta)

func _on_physics_process(delta):
	._on_physics_process(delta)
