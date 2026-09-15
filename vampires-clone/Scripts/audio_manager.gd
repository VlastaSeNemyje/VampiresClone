extends Node

# Main "full" pickup sound — plays for a single, non-rapid pickup
var xp_sound: AudioStreamPlayer

# Small pool of players for rapid/stacked pickups, so quick successive
# ticks can overlap slightly without cutting each other off
var tick_pool: Array[AudioStreamPlayer] = []
const TICK_POOL_SIZE := 4
var tick_index := 0

var xp_cooldown := 0.0
var time_since_xp := 999.0
var xp_pitch := 1.0

const XP_SOUND_DELAY := 0.055
const XP_RESET_TIME := 0.20

const XP_START_PITCH := 0.95
const XP_PITCH_STEP := 0.005
const XP_MAX_PITCH := 1.15

# How much of the sound a "stacked" tick is allowed to play before being cut
const TICK_LENGTH := 0.07


func _ready():
	xp_sound = AudioStreamPlayer.new()
	add_child(xp_sound)
	xp_sound.stream = preload("res://Sounds/VFX/SFX_XP_VampireSurvivors_processed.wav")
	xp_sound.volume_db = -1
	xp_sound.bus = "Master"

	for i in TICK_POOL_SIZE:
		var p = AudioStreamPlayer.new()
		p.stream = xp_sound.stream   # reuse the same clip, just truncated
		p.volume_db = -6             # quieter, so it reads as a "tick" not a duplicate hit
		p.bus = "Master"
		add_child(p)
		tick_pool.append(p)


func _process(delta):
	if xp_cooldown > 0.0:
		xp_cooldown -= delta

	time_since_xp += delta
	if time_since_xp >= XP_RESET_TIME:
		xp_pitch = XP_START_PITCH


func play_xp():
	var is_rapid = xp_cooldown > 0.0
	time_since_xp = 0.0

	if is_rapid:
		_play_tick()
		return

	xp_cooldown = XP_SOUND_DELAY
	xp_sound.pitch_scale = xp_pitch
	xp_sound.play()

	xp_pitch = min(xp_pitch + XP_PITCH_STEP, XP_MAX_PITCH)


func _play_tick():
	var p = tick_pool[tick_index]
	tick_index = (tick_index + 1) % TICK_POOL_SIZE

	p.pitch_scale = xp_pitch
	p.play()

	# cut it short so it reads as a quick "tick" instead of a full pickup sound
	await get_tree().create_timer(TICK_LENGTH).timeout
	if p.playing:
		p.stop()

	xp_pitch = min(xp_pitch + XP_PITCH_STEP, XP_MAX_PITCH)
