extends KinematicBody2D

const speed = 200
var color: Color

func _ready():
	add_to_group("players")

func _network_ready(is_server):
	if is_server:
		randomize()
		color = Color.from_hsv(randf(), 1, 1)
		position = Vector2(rand_range(0, get_viewport_rect().size.x), rand_range(0, get_viewport_rect().size.y))
	
	$Sprite.modulate = color

func _process(dt):
	if is_network_master():
		if Input.is_action_pressed("ui_up"):
			position += Vector2(0, -speed * dt)
		if Input.is_action_pressed("ui_down"):
			position += Vector2(0, speed * dt)
		if Input.is_action_pressed("ui_left"):
			position += Vector2(-speed * dt, 0)
		if Input.is_action_pressed("ui_right"):
			position += Vector2(speed * dt, 0)
		if Input.is_action_just_pressed("ui_accept"):
			rpc("spawn_box", position)
		if Input.is_mouse_button_pressed(BUTTON_LEFT):
			var direction = -(position - get_viewport().get_mouse_position()).normalized()
			rpc("spawn_projectile", position, direction, Uuid.v4())

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
