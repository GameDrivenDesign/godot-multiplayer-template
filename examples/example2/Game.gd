extends Node2D

func _ready():
	pass
	#$Player.connect("health_changed", self, "update_health")

func update_health(percentage):
	$Healthbar.rect_scale = Vector2(percentage, 1)

func _process(_delta):
	if Input.is_action_pressed("ui_accept") and is_network_master():
		var players = get_tree().get_nodes_in_group("players")
		var spawn_position = Vector2(rand_range(100, 1000), rand_range(100, 700))
		var target_id = players[randi() % players.size()].name
		spawn_enemy(spawn_position, target_id)

func spawn_enemy(spawn_position, target_id):
	var enemyClass = preload("res://examples/example2/Enemy.tscn")
	var enemy = enemyClass.instance()
	enemy.set_network_master(1)
	enemy.position = spawn_position
	enemy.target_id = target_id
	add_child(enemy)
	return enemy
