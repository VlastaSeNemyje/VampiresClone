class_name StoryLine
extends Resource

## One line of story text shown at the bottom of the screen.

@export var minute: int = 0
@export var second: int = 0
@export_multiline var text: String = ""
## Seconds to fade in.
@export var fade_in: float = 1.0
## Seconds fully visible (after fade in).
@export var hold: float = 5.0
## Seconds to fade out.
@export var fade_out: float = 3.0
