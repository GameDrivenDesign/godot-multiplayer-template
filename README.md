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

```

## Getting Started

Make `components/Game.tscn` the main node at your game. You will need provide a `default level` and a `player scene`.
The `player scene` will be instantiated, whenever a new client connects to the game. This scene should inherit from the `Player` class.

You can also configure the IP address, the port, the maximum number of players in the inspector. By default the game will run on `localhost:8877` and allow for up to 200 players. Both can be overridden by command line arguments.

Each object, that should be synced among the clients, needs a `Sync` node, found in `sync/sync.tscn`.
By default only the position of the object will be synced. You can sync other properties by adding them to the `synced_properties` array.

When using physics objects, such as RigidBodies, use the `SyncableRigidBody`. It extends the default RigidBody by implementing the `integrate_forces` function, allowing for more stable experience.

To call a function on all devices, `rpc()` needs to be used.

## Examples

The example folder contains two small game demos.

### Pong

Set `default level` to `res://example1/PongExample.tscn` and `player scene` to `res://example1/player/Player.tscn`.

Once a player joined, they are assigned a random color, and can move around using the arrow keys. Pressing Enter allows players to spawn blocks in the world. Their position will be synced as well. Several physics blocks are in the scene, they can be kicked around by any player. Holding the mouse button will let the players spawn physics based projectiles. They can also move the blocks, or "kill" other players.

### Enemies

Set `default level` to `res://example2/ShooterExample.tscn` and `player scene` to `res://example2/Player.tscn`.

Move around using the arrow keys, hold the mouse to shoot projectiles. Pressing enter, will spawn enemies on the board. Each enemy, will randomly choose an existing player and move towards them. On being touched by an enemy, the player will loose health. Shooting enemies removes them.
