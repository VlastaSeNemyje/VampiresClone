extends Node

# Template player — stream, volume and bus are configured on the XpSound node
# in Scenes/audio_manager.tscn. The voices below copy its settings.
@onready var xp_sound: AudioStreamPlayer = $XpSound

# ---- Tuning ----------------------------------------------------------------
# Pickups are queued and played at a steady rate, so a vacuumed pile of gems
# becomes an even rising run of notes instead of a same-frame burst.
const XP_INTERVAL := 0.08       # seconds between notes while a queue drains
const XP_MAX_QUEUE := 6         # extra pickups beyond this are merged (no long tail)
const XP_RESET_TIME := 0.4      # silence after which the run starts from the bottom again

const XP_BASE_PITCH := 0.7      # pitch of the first note in a run
const XP_SCALE: Array[int] = [0, 2, 4, 7, 9]  # major pentatonic, in semitones
const XP_MAX_STEP := 4          # highest note of the run (4 = 9 semitones up, ~1.18 pitch)

const XP_VOLUME_STEP_DB := 0.8  # each step up the run gets this much quieter...
const XP_VOLUME_FLOOR_DB := 6.0 # ...down to at most this far below the base volume

const VOICE_COUNT := 8          # overlapping voices, so notes ring out instead of being cut
# -----------------------------------------------------------------------------

var voices: Array[AudioStreamPlayer] = []
var voice_index := 0

var pending := 0          # queued pickups waiting to be played
var note_timer := 0.0     # time until the next queued note may play
var time_since_note := 999.0
var step := 0             # position in the rising run


func _ready():
	for i in VOICE_COUNT:
		var p := AudioStreamPlayer.new()
		p.stream = xp_sound.stream
		p.bus = xp_sound.bus
		add_child(p)
		voices.append(p)


func _process(delta):
	note_timer -= delta
	time_since_note += delta

	if pending > 0 and note_timer <= 0.0:
		pending -= 1
		note_timer = XP_INTERVAL
		_play_note()


func play_xp():
	pending = mini(pending + 1, XP_MAX_QUEUE)


func _play_note():
	if time_since_note >= XP_RESET_TIME:
		step = 0
	time_since_note = 0.0

	var p := voices[voice_index]
	voice_index = (voice_index + 1) % VOICE_COUNT

	p.pitch_scale = XP_BASE_PITCH * pow(2.0, _semitones(step) / 12.0)
	p.volume_db = xp_sound.volume_db - minf(step * XP_VOLUME_STEP_DB, XP_VOLUME_FLOOR_DB)
	p.play()

	step = mini(step + 1, XP_MAX_STEP)


# Semitone offset of the given step: walks up the scale, wrapping into the
# next octave when it runs past the end.
func _semitones(s: int) -> float:
	var size := XP_SCALE.size()
	@warning_ignore("integer_division")
	var octave := s / size
	return 12.0 * octave + XP_SCALE[s % size]
