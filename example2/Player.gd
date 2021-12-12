extends KinematicBody2D

signal health_changed(percentage)
var health = 1.0
const speed = 200

func _ready():
	add_to_group("players")
	rset_config("position", MultiplayerAPI.RPC_MODE_REMOTESYNC)
	position = Vector2(rand_range(0, get_viewport_rect().size.x), rand_range(0, get_viewport_rect().size.y))
	assert(connect("health_changed", $"../Game", "update_health") == OK)

func take_damage():
	if is_network_master():
		health -= 0.04
		emit_signal("health_changed", health)

func _process(delta):
	if is_network_master():
		if Input.is_action_pressed("ui_up"):
			rset("position", position + Vector2(0, -speed * delta))
		if Input.is_action_pressed("ui_down"):
			rset("position", position + Vector2(0, speed * delta))
		if Input.is_action_pressed("ui_left"):
			rset("position", position + Vector2(-speed * delta, 0))
		if Input.is_action_pressed("ui_right"):
			rset("position", position + Vector2(speed * delta, 0))

		if Input.is_mouse_button_pressed(BUTTON_LEFT):
			var direction = (get_viewport().get_mouse_position() - position).normalized()
			rpc("spawn_projectile", position, direction)

remotesync func spawn_projectile(spawn_position, direction):
	var ProjectileClass = preload("res://example2/Projectile.tscn")
	var projectile = ProjectileClass.instance()
	# Make sure the projectile doesn't spawn on top of us
	projectile.position = spawn_position + direction * 30
	projectile.direction = direction
	projectile.set_network_master(1)
	get_parent().add_child(projectile)
	return projectile
