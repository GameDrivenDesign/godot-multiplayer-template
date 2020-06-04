extends KinematicBody2D
class_name Player

var id
var color: Color setget set_color
const speed = 200

func _ready():
	rset_config("position", MultiplayerAPI.RPC_MODE_REMOTESYNC)
	set_process(true)
	randomize()
	position = Vector2(rand_range(0, get_viewport_rect().size.x), rand_range(0, get_viewport_rect().size.y))
	
	# pick our color, even though this will be called on all clients, everyone
	# else's random picks will be overriden by the first sync_state from the master
	set_color(Color.from_hsv(randf(), 1, 1))

func get_sync_state():
	# place all synced properties in here
	var properties = ['position', 'color']
	
	var state = {}
	for p in properties:
		state[p] = get(p)
	return state

func _process(dt):
	if is_network_master():
		if Input.is_action_pressed("ui_up"):
			rset("position", position + Vector2(0, -speed * dt))
		if Input.is_action_pressed("ui_down"):
			rset("position", position + Vector2(0, speed * dt))
		if Input.is_action_pressed("ui_left"):
			rset("position", position + Vector2(-speed * dt, 0))
		if Input.is_action_pressed("ui_right"):
			rset("position", position + Vector2(speed * dt, 0))
		if Input.is_action_just_pressed("ui_accept"):
			# rpc("spawn_box", position)
			get_tree().get_root().find_node("game", true, false).switch_level("res://level/level1.tscn")
		if Input.is_mouse_button_pressed(BUTTON_LEFT):
			var direction = -(position - get_viewport().get_mouse_position()).normalized()
			rpc("spawn_projectile", position, direction, Uuid.v4())

func set_color(_color: Color):
	color = _color
	$sprite.modulate = color

remotesync func spawn_projectile(position, direction, name):
	var projectile = preload("res://examples/physics_projectile/physics_projectile.tscn").instance()
	projectile.set_network_master(1)
	projectile.name = name
	projectile.position = position
	projectile.direction = direction
	projectile.owned_by = self
	get_parent().add_child(projectile)
	return projectile

remotesync func spawn_box(position):
	var box = preload("res://examples/block/block.tscn").instance()
	box.position = position
	get_parent().add_child(box)

remotesync func kill():
	hide()
