class_name PlagueLevel
extends Node
## Stats for one Plague level. Lives as a child of Player/Attack/PlagueBase (Level1..Level4).
## Level1 = first time the weapon is picked, Level2 = first upgrade, and so on.
## Edit the numbers in the Inspector - no code needed.

## Projectiles fired per volley.
@export var projectiles: int = 1
## How many more enemies each projectile hits after the first one (bounces).
@export var extra_hits: int = 2
## Multiplier on PlagueBase damage (1.2 = +20%). This is absolute, not stacked on the previous level.
@export var damage_multiplier: float = 1.0
## Seconds between volleys (player cooldown upgrades shorten it).
@export var cooldown: float = 8.0
