## The Autoload in charge of all things sound, from OSTs to SFXs
extends Node

#region Declarations
enum BusID {
	MASTER,
	OST,
	SFX,
	UI,
	AMBIENT
}

@export var ost_pool : Array[OstHolder] = [] ## The entire collection of OSTs available to use in the game.
@export var sfx_pool : Dictionary[StringName, AudioStream] = {} ## The entire collection of SFXs
@export var ui_pool : Dictionary[StringName, AudioStream] = {} ## The entire collection of UI SFXs
@export var ambient_pool : Dictionary[StringName, AudioStream] = {} ## The entire collection of Ambient SFXs

@onready var main_music_player : AudioStreamPlayer = $OSTPlayers/MainPlayer ## The Primary player for OSTs
## The Secondary player for OSTs, used for crossfading.
@onready var secondary_music_player : AudioStreamPlayer = $OSTPlayers/SecondaryPlayer
@onready var sfx_player_1 : AudioStreamPlayer = $SoundPlayers/SFXPlayer
@onready var sfx_player_2 : AudioStreamPlayer = $SoundPlayers/SFXPlayer2
@onready var ui_player : AudioStreamPlayer = $SoundPlayers/UIPlayer
@onready var ambient_player : AudioStreamPlayer = $SoundPlayers/AmbientPlayer

var current_song : OstHolder ## The currently playing song via [OstHolder]
var crossfade := false ## If [member current_song] is currently cross fading to another.
#endregion

#region Events
func _ready() -> void:
	_connect_sound_signals()

## Connects all the audio players so that when they're finished, they specifically pass on their own data
## to [method _on_player_finished] to remove the [AudioStream]
func _connect_sound_signals() -> void:
	sfx_player_1.finished.connect(_on_player_finished.bind(sfx_player_1))
	sfx_player_2.finished.connect(_on_player_finished.bind(sfx_player_2))
	ui_player.finished.connect(_on_player_finished.bind(ui_player))
	ambient_player.finished.connect(_on_player_finished.bind(ambient_player))

## Attempts to play a song by their [param id] at [param position] seconds within the song. [br]
## The [member current_song] can either be abruptly stopped, or if [param crossover] is true, then [br]
## the two songs will fade between each other.
func play_ost(id: StringName, position: float = 0, crossover: bool = false) -> void:
	current_song = _find_ost(id)
	if not current_song:
		push_error("@Audiomanager/Error: There's no song by the name %s in song_pool" % id)
		return
	
	if crossover:
		_crossover(id)
	else:
		main_music_player.stream = current_song.stream
		main_music_player.play(position)

## Plays a short jingle either just on its own or by crossfading [member current_song] assuming [br]
## it is playing
func play_jingle(sfx_id: StringName) -> void:
	if main_music_player.playing:
		_crossover(sfx_id, true)
	else:
		play_sound(sfx_id)

## Plays a sound as long as it exists within any pool based on [param id]
func play_sound(id: StringName) -> void:
	var sound := _find_sound(id)
	var player : AudioStreamPlayer
	if sound.get(1):
		player = _get_player(sound.get(1))
	
	if not player:
		return
	
	player.stream = sound.get(0)
	player.play()

## Grabs an ost to be used in another AudioPlayer, for example: Spatial Sounds.
func grab_ost(id: StringName) -> OstHolder:
	for ost in ost_pool:
		if ost.id == id:
			return ost
	
	push_warning("@AudioManager: There is no ost by that ID.")
	return null

## Grabs a sound to be used in another AudioPlayer, for example: Spatial Sounds.
func grab_sound(id: StringName) -> AudioStream:
	var sound = _find_sound(id)
	return sound.get(0)

## Handles the crossfade between [member current_song] with [param id]. [br]
## If [param sfx_crossover] is true, then the crossover will wait until after the SFX has played.
func _crossover(id: StringName, sfx_crossover := false) -> void:
	crossfade = true
	if !sfx_crossover:
		# Setup the new ost on Secondary
		secondary_music_player.stream = _find_ost(id).stream
		secondary_music_player.volume_linear = 0
		secondary_music_player.play()
		
		# Create the crossover tween
		var tween = get_tree().create_tween().bind_node(self).set_trans(Tween.TRANS_SINE)
		tween.tween_property(main_music_player, "volume_linear", 0, 1.0)
		tween.parallel().tween_property(secondary_music_player, "volume_linear", 1, 1.0)
		
		await tween.finished
		# Move from Secondary to Main
		main_music_player.stream = secondary_music_player.stream
		main_music_player.volume_linear = 1
		secondary_music_player.volume_linear = 0
		main_music_player.play(secondary_music_player.get_playback_position())
		secondary_music_player.stop()
		secondary_music_player.stream = null
	else:
		# Fade out stream on Main, play our SFX, then fade back in
		var tween = get_tree().create_tween().bind_node(self).set_trans(Tween.TRANS_SINE)
		tween.tween_property(main_music_player, "volume_linear", 0, 5.0)
		await tween.finished
		play_sound(id)
		tween.tween_property(main_music_player, "volume_linear", 1, 5.0)
		await tween.finished
	
	crossfade = false
#endregion

#region Processes
func _process(_delta: float) -> void:
	if current_song:
		if not current_song.can_loop:
			return
		
		var current_pos = main_music_player.get_playback_position()
		if current_song.loop_vector.y == -1:
			if current_pos >= current_song.stream.get_length():
				play_ost(current_song.id, current_song.loop_vector.x)
		elif current_song.loop_vector.y != -1 and not crossfade:
			if current_pos >= current_song.loop_vector.y:
				play_ost(current_song.id, current_song.loop_vector.x)
#endregion

#region Helpers
## Finds the ost with the id [param id].
func _find_ost(id: StringName) -> OstHolder:
	for ost in ost_pool:
		if ost.id == id:
			return ost
	
	return null

## Attempts to find a sound based on its [param id], returns an array of [br]
## [[enum BusID], [AudioStream]]
func _find_sound(id: StringName) -> Array:
	var bus : BusID
	var sound : AudioStream
	if sfx_pool.has(id):
		bus = BusID.SFX
		sound = sfx_pool.get(id)
	elif ui_pool.has(id):
		bus = BusID.UI
		sound = ui_pool.get(id)
	elif ambient_pool.has(id):
		bus = BusID.AMBIENT
		sound = ambient_pool.get(id)
	
	return [sound, bus]

## Based on [param bus], will grab a corresponding and [b]open[/b] player.
func _get_player(bus: BusID) -> AudioStreamPlayer:
	match(bus):
		BusID.SFX:
			if sfx_player_1.stream == null:
				return sfx_player_1
			elif sfx_player_2.stream == null:
				return sfx_player_2
			else:
				push_warning("@AudioManager: Both SFX players are in use, cannot return player")
				return null
		BusID.UI:
			if ui_player.stream == null:
				return ui_player
			else:
				push_warning("@AudioManager: UI Player is currently in use, cannot return player")
		BusID.AMBIENT:
			if ambient_player.stream == null:
				return ambient_player
			else:
				push_warning("@AudioManager: Ambient Player is currently in use, cannot return player")
		_:
			push_warning("@AudioManager: The bus given, is not a correct bus type")
			return null
	
	return null
#endregion

#region Signal Callbacks
## When a player's audio is finished (specifically for sound), will then ensure the is stopped and then
## removes the [AudioStream] from the player.
func _on_player_finished(player: AudioStreamPlayer) -> void:
	player.stop()
	player.stream = null
#endregion
