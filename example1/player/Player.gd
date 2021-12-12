extends KinematicBody2D

const speed = 200
var color: Color setget set_color

func _ready():
	add_to_group("players")
	
	rset_config("position", MultiplayerAPI.RPC_MODE_REMOTESYNC)
	set_process(true)
	randomize()
	position = Vector2(rand_range(0, get_viewport_rect().size.x), rand_range(0, get_viewport_rect().size.y))
	# pick our color, even though this will be called on all clients, everyone
	# else's random picks will be overriden by the first sync_state from the master
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
			var direction = -(position - get_viewport().get_mouse_position()).normalized()
			rpc("spawn_projectile", position, direction, Uuid.v4())

func set_color(_color: Color):
	color = _color
	$Sprite.modulate = color

remotesync func spawn_projectile(position, direction, name):
	var projectile = preload("res://example1/physics_projectile/PhysicsProjectile.tscn").instance()
	projectile.set_network_master(1)
	projectile.name = name
	projectile.position = position
	projectile.direction = direction
	projectile.owned_by = self
	get_parent().add_child(projectile)
	return projectile

remotesync func spawn_box(position):
	var box = preload("res://example1/Block.tscn").instance()
	box.position = position
	get_parent().add_child(box)

remotesync func kill():
	hide()
