extends Area2D

signal health_changed(percentage)
var health = 1.0

func _on_player_body_entered(body):
	if body.is_in_group("enemy"):
		health -= 0.04
		emit_signal("health_changed", health)
		body.queue_free()

func _process(delta):
	if Input.is_mouse_button_pressed(BUTTON_LEFT):
		var ProjectileClass = preload("res://example2/projectile.tscn")
		var projectile = ProjectileClass.instance()
		projectile.position = position
		projectile.direction = (get_viewport().get_mouse_position() - position).normalized()
		get_parent().add_child(projectile)
