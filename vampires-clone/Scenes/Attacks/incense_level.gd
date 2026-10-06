class_name IncenseLevel
extends Node
## Stats for one Charming Incense level. Lives as a child of Player/Attack/IncenseBase (Level1..Level4).
## Level1 = first time the weapon is picked, Level2 = first upgrade, and so on.
## Edit the numbers in the Inspector - no code needed.

## Bombs dropped per volley.
@export var bombs: int = 1
## Seconds from dropping a bomb until it explodes.
@export var fuse_time: float = 4.0
## Multiplier on IncenseBase damage (1.25 = +25%). Absolute, not stacked on the previous level.
@export var damage_multiplier: float = 1.0
## Multiplier on IncenseBase explosion radius (1.3 = +30%). Absolute, not stacked.
@export var area_multiplier: float = 1.0
## Seconds between volleys (player cooldown upgrades shorten it).
@export var cooldown: float = 4.0
## After the explosion the area stays and keeps hurting enemies (see the Puddle group on IncenseBase).
@export var leaves_puddle: bool = false
