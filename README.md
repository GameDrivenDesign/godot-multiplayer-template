# Godot Multiplayer Template

Enables a peer-to-peer connection between instances of a Godot game.

## How to Play

In order to start the game, first export it. Start one game as the host, then other clients can join.

The host has the id `1`, and can be set as network authority for all objects, other than the individual players.

E.g. starting my game on Linux

```
# Start the host
./mygame.x86_64
# Start the host on a specified port and IP address
./mygame.x86_64 --port=8888 --ip=127.0.0.1


# Join as a client
./mygame.x86_64 --client
./mygame.x86_64 --client --port=8888 --ip=127.0.0.1

# Export game and start it right away (needs to export via UI once first!)
# Example shown here works only for Linux, adapt accordingly :)
../Godot_v3.4-stable_x11.64 --export-debug "Linux/X11" && ./mygame.x86_64 --client
```

## Getting Started

In the following, typical concerns of a multiplayer game are described.

### Setup
* Create a level scene, here you can design your level and players will be spawned inside.
* Create a player scene.
* Open `Launcher.tscn` and set the level and player scene files in the Launcher's configuration. The Launcher scene will be started as the game's main scene and will then place your selected level inside itself.

### Syncing on game start
Each object, that should be synced among the clients, needs a `Sync` node, found in `sync/sync.tscn`.
For example, to ensure that all objects are in the same position on game start, add the `position` property to the `synced_properties` list (if you're building a 3d game, use `transform` instead).

`Sync` will ensure that the object appears on newly connected clients in the same state.
After connection, you are responsible for keeping things synchronized.

### Synchronizing

**Summary of the below**: if the property you want to synchronize...
* ...is the same for all players: you don't need to do anything.
* ...is only changed at game start, but is different for each player: you only need to add it to the `synced_properties` list.
* ...changes throughout the game:
	1. add it to the `synced_properties` list
	2. use `rset_config` to enable live synchronization
	3. use `rset` to change the property.

**Details and Examples**

To synchronize a property of a node throughout the game, call `rset_config("propname", MultiplayerAPI.RPC_MODE_REMOTESYNC)` and use `rset("propname", value)` to set the property.
If you use a function that applies the change, set the config to `RPC_MODE_REMOTE` (this way only the other people will also hear of it) and set the property again:
```
func _ready():
	rset_config("position", MultiplayerAPI.RPC_MODE_REMOTE)

func _process(delta):
	# we're only doing this on the client that owns this player
	if is_network_master():
		# changes our position on our client but isn't synchronized
		move_and_slide(Vector2(20 * delta, 0))
		# now we're synchronizing it with everyone else! (because of RPC_MODE_REMOTE)
		rset("position", position)
```

Otherwise, if you change the property directly, use `MultiplayerAPI.RPC_MODE_REMOTESYNC` (which applies the change on both your machine and the remotes):
```
func _ready():
	rset_config("position", MultiplayerAPI.RPC_MODE_REMOTESYNC)

func _process(delta):
	# we're only doing this on the client that owns this player
	if is_network_master():
		# change our position and let us and everyone else apply it (because of RPC_MODE_REMOTESYNC)
		rset("position", position + Vector2(20 * delta, 0))
```

To call a function on all devices, use `rpc("funcname", arg1)`.
Put either `remote` or `remotesync` in front of the function name to let Godot know who should get the call.

```
func shoot():
	rpc("spawn_projectile", Vector2(40, 30), 100)

remotesync func spawn_projectile(position, velocity):
	var p = preload("res://Projectile.tscn")
	p.position = position
	p.velocity = velocity
	get_parent().add_child(p)
```

### Physics & RigidBodies
When using physics objects, such as RigidBodies, use the `SyncableRigidBody` script.
It extends the default RigidBody by implementing the `_integrate_forces` function, which is the only method allow by the simulation to set properties such as position.

### Configuration
You can configure the IP address, the port, the maximum number of players in the inspector on the main game scene. By default the game will run on `localhost:8877` and allow for up to 200 players. Both can be overridden by command line arguments.

## Examples

The example folder contains two small game demos.

### Pong

Set `res://example1/PongExample.tscn` as the main scene, and `res://example1/player/Player.tscn` as player and launch the game.

Once a player joined, they are assigned a random color, and can move around using the arrow keys. Pressing Enter allows players to spawn blocks in the world. Their position will be synced as well. Several physics blocks are in the scene, they can be kicked around by any player. Holding the mouse button will let the players spawn physics based projectiles. They can also move the blocks, or "kill" other players.

### Enemies

Set `res://example2/ShooterExample.tscn` as the main scene, and `res://example2/Player.tscn` as player and launch the game.

Move around using the arrow keys, hold the mouse to shoot projectiles. Pressing enter, will spawn enemies on the board. Each enemy, will randomly choose an existing player and move towards them. On being touched by an enemy, the player will loose health. Shooting enemies removes them.

### 3D Example

Set `res://example3/3DLevel.tscn` as the main scene, and `res://example3/Player.tscn` as player and launch the game.

Players will simply choose a random color for themselves and move to the right of the screen.
