extends Resource

class_name Spawn_info

@export var time_start: int
@export var time_end: int
@export var enemy: Resource
@export var enemy_num: int
@export var enemy_spawn_delay: int
## All enemies of one spawn appear close to each other (e.g. Hunters, so they can link nets right away).
@export var grouped: bool = false
## How far from the group's centre each grouped enemy may appear.
@export var group_spread: float = 24.0
## Enemies of one spawn are spread over different screen sides instead of mostly appearing in front of the player.
@export var surround: bool = false

var spawn_delay_counter = 0
