extends Node

var xp_sound: AudioStreamPlayer

var xp_cooldown := 0.0
var time_since_xp := 999.0
var xp_pitch := 1.0

const XP_SOUND_DELAY := 0.055
const XP_RESET_TIME := 0.20

const XP_START_PITCH := 0.95
const XP_PITCH_STEP := 0.005
const XP_MAX_PITCH := 1.15


func _ready():
	xp_sound = AudioStreamPlayer.new()
	add_child(xp_sound)

	xp_sound.stream = preload(
		"res://Sounds/VFX/SFX_XP_VampireSurvivors_processed.wav"
		
	)

	# Make it clearly audible while testing
	xp_sound.volume_db = -1

	# Make sure it uses the normal master bus
	xp_sound.bus = "Master"


func _process(delta):
	if xp_cooldown > 0.0:
		xp_cooldown -= delta

	time_since_xp += delta

	# Reset pitch after the player stops collecting XP
	if time_since_xp >= XP_RESET_TIME:
		xp_pitch = XP_START_PITCH


func play_xp():
	# Tell the system that XP was just collected
	time_since_xp = 0.0

	# Don't play sounds too rapidly
	if xp_cooldown > 0.0:
		return

	xp_cooldown = XP_SOUND_DELAY

	# Set pitch
	xp_sound.pitch_scale = xp_pitch

	# Play
	xp_sound.play()

	# Increase pitch for next pickup
	xp_pitch += XP_PITCH_STEP

	# Limit maximum pitch
	xp_pitch = min(xp_pitch, XP_MAX_PITCH)
