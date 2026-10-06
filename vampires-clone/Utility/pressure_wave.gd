extends Resource

class_name Pressure_wave
## A moment where the crowd around the player gets denser. Add these to EnemySpawner > Pressure Waves.

## Second the wave starts and ends (game time).
@export var time_start: int
@export var time_end: int
## During the wave, at least this share (0-1) of all enemies must be near the player.
@export_range(0.0, 1.0) var crowd_fraction: float = 0.95
## How many far-away enemies may be pulled to the player each second during the wave.
@export var pulled_per_second: int = 40
