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

### Synchronize a property
1. Set the property on the network master.
2. In the object's `Sync.tscn`, add the property to synced or `unreliable_synced` for faster but potentially dropped updates.

### Initialize a property with randomness
1. Create a `_network_ready(is_server)` func.
2. if `is_server`, decide set the property.
3. if not `is_server`, you will have access to the same value that was decided on the server

### Call a function on all devices

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

### Pattern: Use setters to synchronize derived state
* To ensure that synchronizing a single property has the desired effects, create a setter that receives the new value and applies all changes.

### Pattern: Updating Properties and Calling Remote Procedures
* Use Sync.tscn to sync properties and `rpc()` to call procedures on all clients
* Make sure that these are **only ever called on a single** instance by using `is_network_master`.

### Pattern: Spawning entities on all instances
* Godot identifies nodes by name. By default, is increments a counter that is added to the default scene name on each client, which can get out of sync when many entities of the same scene spawn quickly.
* To make sure the name is always the same on all clients, use a UUID:
```
func ...():
	...
	rpc("spawn_enemy", spawn_position, Uuid.v4())

remotesync func spawn_enemy(spawn_position, name):
	var enemy = preload("res://example2/Enemy.tscn").instance()
	enemy.name = name
	enemy.position = spawn_position
	add_child(enemy)
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




## Advanced Usage of Godot Synchronization

**Synching throughout the game**

There are two cases to be distinguished.

First, if a utility function such as `move_and_slide` changes the property of interest, use `rset_config()` with `RPC_MODE_REMOTE` (which then applies the change only on the remotes, not on your machine where it already happened) as shown below:
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

Second, if you change the property directly, use `MultiplayerAPI.RPC_MODE_REMOTESYNC` (which applies the change on both your machine and the remotes):
```
func _ready():
	rset_config("position", MultiplayerAPI.RPC_MODE_REMOTESYNC)

func _process(delta):
	# we're only doing this on the client that owns this player
	if is_network_master():
		# change our position and let us and everyone else apply it (because of RPC_MODE_REMOTESYNC)
		rset("position", position + Vector2(20 * delta, 0))
```
