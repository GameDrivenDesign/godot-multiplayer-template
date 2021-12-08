extends Node2D

func _ready():
	$Player.connect("health_changed", self, "update_health")

func update_health(percentage):
	$Healthbar.rect_scale = Vector2(percentage, 1)

func _process(delta):
	if Input.is_action_pressed("ui_accept"):
		var EnemyClass = preload("res://example2/enemy.tscn")
		var enemy = EnemyClass.instance()
		enemy.position = Vector2(rand_range(100, 1000), rand_range(100, 700))
		enemy.target = $Player
		add_child(enemy)
