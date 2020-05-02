extends KinematicBody2D
class_name Player

var id
var color: Color setget set_color
const speed = 200

func _ready():
	rset_config("position", MultiplayerAPI.RPC_MODE_REMOTESYNC)
	add_to_group("players")
	set_process(true)
	randomize()
	set_color(Color.from_hsv(randf(), 1, 1))

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
			rpc("spawn_box", position)
		if Input.is_mouse_button_pressed(BUTTON_LEFT):
			rpc("spawn_projectile", position, -(position - get_viewport().get_mouse_position()).normalized())

func set_color(_color: Color):
	color = _color
	$player.modulate = color

func get_sync_state():
	# place all synced properties in here
	var properties = ['color']
	
	var state = {}
	for p in properties:
		state[p] = get(p)
	return state

remotesync func spawn_projectile(position, direction):
	var projectile = preload("res://physics_projectile/physics_projectile.tscn").instance()
	projectile.set_network_master(1)
	projectile.position = position
	projectile.direction = direction
	projectile.owned_by = self
	get_parent().add_child(projectile)

remotesync func spawn_box(position):
	var box = preload("res://block/block.tscn").instance()
	box.position = position
	get_parent().add_child(box)

remotesync func kill():
	hide()
