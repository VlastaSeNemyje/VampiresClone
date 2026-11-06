extends CanvasLayer
## Shows story lines at the bottom of the screen at set times of the run.
## Edit the "Lines" array on this node in the Inspector: each entry has
## minute, second, text and fade timings. Add as many as you like.

@export var lines: Array[StoryLine] = []
@export var font_size: int = 22
## Distance of the text from the bottom edge of the screen.
@export var bottom_margin: int = 40

var _elapsed := 0.0
var _next := 0
var _label: Label
var _tween: Tween


func _ready() -> void:
	layer = 5
	_label = Label.new()
	_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_label.offset_top = -(bottom_margin + font_size + 10)
	_label.offset_bottom = -bottom_margin
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("font_size", font_size)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.modulate.a = 0.0
	add_child(_label)
	# Show lines in time order regardless of how they were entered.
	lines = lines.duplicate()
	lines.sort_custom(func(a, b): return _start(a) < _start(b))


func _start(l: StoryLine) -> float:
	return l.minute * 60.0 + l.second


func _process(delta: float) -> void:
	_elapsed += delta
	while _next < lines.size() and _elapsed >= _start(lines[_next]):
		_show(lines[_next])
		_next += 1


func _show(l: StoryLine) -> void:
	_label.text = l.text
	if _tween:
		_tween.kill()
	var tw := create_tween()
	_tween = tw
	_label.modulate.a = 0.0
	tw.tween_property(_label, "modulate:a", 1.0, maxf(l.fade_in, 0.001))
	tw.tween_interval(l.hold)
	tw.tween_property(_label, "modulate:a", 0.0, maxf(l.fade_out, 0.001))
