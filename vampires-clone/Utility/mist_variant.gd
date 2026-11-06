class_name MistVariant
extends Resource

## One visual look for a mist cloud. The Mist node picks randomly between its variants.

## Base stretch of the 64px mist sprite (x = width, y = height). Wide x = long horizontal cloud.
@export var stretch: Vector2 = Vector2(8, 2.5)
## Colour and transparency of the cloud (alpha = how thick it looks).
@export var tint: Color = Color(1, 1, 1, 0.35)
## Slight rotation range in degrees (+/-), keeps clouds from looking identical.
@export_range(0, 45) var tilt_degrees: float = 3.0
## Relative chance of this variant being chosen.
@export var weight: float = 1.0
