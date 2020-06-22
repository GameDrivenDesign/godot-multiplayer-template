extends Node2D

var port = 8877
var ip = 'localhost'
var max_players = 200
var clients = []
export var default_level: String = "res://level/level1.tscn"

func _ready():
	var peer = NetworkedMultiplayerENet.new()
	var is_client = "--client" in OS.get_cmdline_args()
	var is_dedicated = "--dedicated" in OS.get_cmdline_args()
	
	# Other arguments are in the style of "--arg=value"
	for argument in OS.get_cmdline_args():
		if argument.find("=") > -1:
			var key_value = argument.split("=")
			match key_value[0]:
				'--ip': ip=key_value[1]
				'--port': port=int(key_value[1])
	
	if is_client:
		peer.create_client(ip, port)
		assert(get_tree().connect("server_disconnected", self, "client_note_disconnected") == OK)
	else:
		print("Listening for connections on " + String(port) + " ...")
		peer.create_server(port, max_players)
		assert(get_tree().connect("network_peer_connected", self, "server_client_connected") == OK)
		assert(get_tree().connect("network_peer_disconnected", self, "server_client_disconnected") == OK)
	
	get_tree().set_network_peer(peer)
	
	# this must happen after the network peer is set
	if not is_client:
		if not is_dedicated:
			register_client(1)
		switch_level(default_level)

func switch_level(level_path: String):
	$level.set_level(level_path)
	
	for client in clients:
		spawn_new_player(client.id)

func spawn_new_player(id: int):
	# inform all our players about the new player
	var new_player = spawn_object(String(id), $level.get_path(), "res://player/player.tscn", {})
	new_player.id = id
	spawn_object_on_clients(new_player)

func spawn_object_on_clients(object: Node):
	var sync_node = object.get_node_or_null("sync")
	var sync_state = {}
	if sync_node == null:
		push_error("Trying to remotely spawn object '%s', which doesn't have a 'sync' node!" % object.name)
	else:
		sync_state = sync_node.get_sync_state()
	rpc("spawn_object", object.name, object.get_parent().get_path(), object.filename, sync_state)

func client_note_disconnected():
	print("Server disconnected from player, exiting ...")
	get_tree().quit()

func register_client(id: int):
	var client = preload("res://game/client.gd").new()
	client.id = id
	clients.append(client)

func remove_client(id: int):
	var index = 0
	for client in clients:
		if client.id == id:
			client.free()
			clients.remove(index)
			return
		else:
			index += 1

func spawn_object_for(client_id: int, object: Node):
	rpc_id(client_id, "spawn_object", object.name, object.get_parent().get_path(), object.filename, object.get_node("sync").get_sync_state())

func server_client_connected(id: int):
	if id != 1:
		print("Connected ", id)
		register_client(id)
		spawn_object_for(id, $level)
		
		# get our new player informed about all the old players and objects
		for node in get_tree().get_nodes_in_group("synced"):
			# Take care not to sync the level twice, otherwise the level gets loaded twice
			if node != $level:
				spawn_object_for(id, node)
		
		spawn_new_player(id)

func server_client_disconnected(id: int):
	print("Disconnected ", id)
	rpc("unregister_player", id)
	remove_client(id)

remote func spawn_object(name: String, parent_path: NodePath, filename: String, state: Dictionary):
	# The parent_node MUST exist before spawning the object
	var parent: Node = get_node(parent_path)
	
	# either create the object or just find the existing one
	var object: Node2D = parent.get_node_or_null(name)
	if not object:
		object = load(filename).instance()
		object.name = name
		parent.add_child(object)
	
	# rigid bodys need to be our syncable_rigid_body because you can't set the
	# position or any other physics property outside of its own _integrate_forces
	if object is RigidBody2D:
		object.use_update(state)
	else:
		for property in state:
			object.set(property, state[property])
	
	return object

remotesync func unregister_player(player_id: int):
	$level.remove_child($level.get_node(String(player_id)))
