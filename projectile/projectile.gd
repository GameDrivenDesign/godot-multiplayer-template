extends Area2D

var direction: Vector2
var owned_by: Node2D
const speed = 10

func _ready():
	set_physics_process(true)

func _physics_process(delta):
	position += direction * speed

func _on_projectile_body_entered(body):
	if is_network_master() and body != owned_by:
		body.rpc("kill")
