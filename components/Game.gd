extends Node

export var port = 8877
export var ip = 'localhost'
export var max_players = 200
export(String, FILE, "*.tscn") var default_level = ""
export(String, FILE, "*.tscn") var player_scene = ""
var is_server = false

var clients = []

# Note: this are only emitted on the main instance with id 1
signal player_joined(player, game)
signal player_left(player, game)

func get_num_players():
	return clients.size()

func _ready():
	var peer = NetworkedMultiplayerENet.new()
	var is_client = "--client" in OS.get_cmdline_args()
	var is_dedicated = "--dedicated" in OS.get_cmdline_args()
	is_server = not is_client
	
	var level_container = preload("res://components/LoadScene.tscn").instance()
	level_container.name = "Level"
	add_child(level_container)
	
	# Other arguments are in the style of "--arg=value"
	for argument in OS.get_cmdline_args():
		if argument.find("=") > -1:
			var key_value = argument.split("=")
			match key_value[0]:
				'--ip': ip=key_value[1]
				'--port': port=int(key_value[1])
	
	if is_client:
		assert(peer.create_client(ip, port) == OK)
		assert(get_tree().connect("server_disconnected", self, "client_note_disconnected") == OK)
	else:
		print("Listening for connections on " + String(port) + " ...")
		assert(peer.create_server(port, max_players) == OK)
		assert(get_tree().connect("network_peer_connected", self, "server_client_connected") == OK)
		assert(get_tree().connect("network_peer_disconnected", self, "server_client_disconnected") == OK)
	
	get_tree().set_network_peer(peer)
	
	# this must happen after the network peer is set
	if not is_client:
		if not is_dedicated:
			register_client(1)
		switch_level(default_level)

func switch_level(level_path: String):
	$Level.set_level(level_path)
	
	for object in get_tree().get_nodes_in_group("synced"):
		var s = object.get_node("Sync")
		if s.is_new:
			s.is_new = false
			if object.has_method("_network_ready"):
				object._network_ready(is_server)
			# the level is always manually spawned
			if object.get_parent() != $Level:
				s.spawned_at_start = true
	
	for client in clients:
		spawn_new_player(client.id)

func spawn_new_player(id: int):
	# inform all our players about the new player
	var new_player = spawn_object(String(id), $Level.get_path(), player_scene, {}, id)
	spawn_object_on_clients(new_player)
	return new_player

func sync_state_for(object: Node):
	var sync_node = object.get_node_or_null("Sync")
	var sync_state = {}
	if sync_node == null:
		push_error("Trying to remotely spawn object '%s', which doesn't have a 'Sync' node!" % object.name)
	else:
		sync_state = sync_node.get_sync_state()
	return sync_state

func spawn_object_on_clients(object: Node):
	rpc("spawn_object", object.name, object.get_parent().get_path(), object.filename, sync_state_for(object), 0)

func client_note_disconnected():
	print("Server disconnected from player, exiting ...")
	get_tree().quit()

func register_client(id: int):
	var client = preload("res://components/Client.gd").new()
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
	rpc_id(client_id, "spawn_object", object.name, object.get_parent().get_path(), object.filename, sync_state_for(object))

func sync_spawned_object_for(client_id: int, object: Node):
	rpc_id(client_id, "sync_object", object.get_path(), sync_state_for(object))

func server_client_connected(new_id: int):
	if new_id != 1:
		print("Connected ", new_id)
		register_client(new_id)
		spawn_object_for(new_id, $Level)
		
		# get our new player informed about all the old players and objects
		for node in get_tree().get_nodes_in_group("synced"):
			if not node.get_node('Sync').spawned_at_start:
				spawn_object_for(new_id, node)
			else:
				sync_spawned_object_for(new_id, node)
		
		var player = spawn_new_player(new_id)
		emit_signal("player_joined", player, self)

func server_client_disconnected(id: int):
	print("Disconnected ", id)
	var player = unregister_player(id)
	
	rpc("unregister_player", id)
	remove_client(id)
	
	emit_signal("player_left", player, self)

remote func sync_object(pathOrNode, state: Dictionary, send_ready = true):
	var object = pathOrNode if pathOrNode is Node else get_node(pathOrNode)
	
	# rigid bodys need to be our syncable_rigid_body because you can't set the
	# position or any other physics property outside of its own _integrate_forces
	if object is RigidBody2D:
		object.use_update(state)
	else:
		for property in state:
			if property == '__network_master_id':
				object.set_network_master(state[property])
			else:
				object.set(property, state[property])
	
	if send_ready and object.has_method("_network_ready"):
		object._network_ready(is_server)

remote func spawn_object(name: String, parent_path: NodePath, filename: String, state: Dictionary, master_id: int = 0):
	# The parent_node MUST exist before spawning the object
	var parent: Node = get_node(parent_path)
	var add_to_scene = false
	
	# either create the object or just find the existing one
	var object: Node = parent.get_node_or_null(name)
	if not object:
		object = load(filename).instance()
		object.name = name
		add_to_scene = true
	
	if master_id > 0:
		object.set_network_master(master_id)
	sync_object(object, state, false)
	
	if add_to_scene:
		parent.add_child(object)
	
	if object.has_method("_network_ready"):
		object._network_ready(is_server)
	
	return object

remote func unregister_player(player_id: int):
	var player = $Level.get_node(String(player_id))
	$Level.remove_child(player)
	return player
