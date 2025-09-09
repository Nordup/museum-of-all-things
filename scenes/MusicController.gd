extends Node3D

const BASE_URL := "https://thegates.io/worlds/exports/museum_of_all_things/Music"
const MUSIC_DIR := "user://music"
const TRACK_FILENAMES := [
  "MoAT Track 1 - Waiting on the Weather.ogg",
  "MoAT Track 2 - Comfort on the way.ogg",
  "MoAT Track 3 - Life is Older Than You Knew.ogg",
  "MoAT Track 4 - Blue Sky Inside.ogg",
  "MoAT Track 5 - Waiting for a ride.ogg",
  "MoAT Track 6 - Memory In Passing.ogg",
  "MoAT Track 7 - Blue Sky Outside.ogg",
  "MoAT Track 8 - Stillness After Closing.ogg",
]

@export var min_space_start: float = 20.0
@export var min_space: float = 60.0 * 3
@export var max_space: float = 60.0 * 6

var last_track_index: int = -1
var next_track_index: int = -1
var next_track_local_path: String = ""
var next_track_ready: bool = false
var play_when_download_finishes: bool = false
var current_track_path: String = ""

var http_request: HTTPRequest
var pending_download_path: String = ""
var pending_download_index: int = -1

func _ready() -> void:
  DirAccess.make_dir_recursive_absolute(MUSIC_DIR)
  http_request = HTTPRequest.new()
  add_child(http_request)
  http_request.request_completed.connect(on_request_completed)

  prepare_next_track()

  var wait_time = randf_range(min_space_start, 30)
  if OS.is_debug_build():
    print("waiting for first track. time=", wait_time)
  get_tree().create_timer(wait_time).timeout.connect(play_track_when_ready)
  $AudioStreamPlayer.finished.connect(_reset_timer)

func prepare_next_track() -> void:
  var track_index: int
  if last_track_index == -1:
    track_index = randi() % len(TRACK_FILENAMES)
  else:
    track_index = (last_track_index + (randi() % (len(TRACK_FILENAMES) - 1))) % len(TRACK_FILENAMES)
  next_track_index = track_index

  var filename: String = TRACK_FILENAMES[track_index]
  next_track_local_path = MUSIC_DIR + "/" + filename

  if FileAccess.file_exists(next_track_local_path):
    next_track_ready = true
    if OS.is_debug_build():
      print("retrieved from user:// ", next_track_local_path)
  else:
    next_track_ready = false
    start_download(filename)

func start_download(filename: String) -> void:
  var url := BASE_URL + "/" + filename.uri_encode()
  if OS.is_debug_build():
    print("download started: ", filename, " ← ", url)
  var err := http_request.request(url)
  if err != OK:
    push_warning("Failed to start download: " + url + ", error=" + str(err))
    return
  pending_download_index = next_track_index
  pending_download_path = next_track_local_path

func play_track_when_ready() -> void:
  if next_track_ready:
    play_path(next_track_local_path)
    last_track_index = next_track_index
    prepare_next_track()
  else:
    if OS.is_debug_build():
      print("waiting on download before playing…")
    play_when_download_finishes = true

func play_path(path: String) -> void:
  var stream := AudioStreamOggVorbis.load_from_file(path)
  if stream == null:
    push_warning("Failed to load audio stream from " + path)
    return
  current_track_path = path
  if OS.is_debug_build():
    print("started playing: ", current_track_path)
  $AudioStreamPlayer.stream = stream
  $AudioStreamPlayer.seek(0.0)
  $AudioStreamPlayer.play()

func _reset_timer():
  var wait_time = randf_range(min_space, max_space)
  if OS.is_debug_build():
    print("stopped playing: ", current_track_path)
    print("waiting for next track. time=", wait_time)
  get_tree().create_timer(wait_time).timeout.connect(play_track_when_ready)

func on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
  if OS.is_debug_build():
    print("download headers count=", headers.size())
  if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
    push_warning("Download failed (" + str(response_code) + ") for index " + str(pending_download_index))
    next_track_ready = false
    if play_when_download_finishes:
      prepare_next_track()
      play_track_when_ready()
    return

  var dir_ok := DirAccess.make_dir_recursive_absolute(MUSIC_DIR)
  if dir_ok != OK:
    push_warning("Failed to ensure music directory exists: " + MUSIC_DIR)
  var file := FileAccess.open(pending_download_path, FileAccess.WRITE)
  if file == null:
    push_warning("Failed to open file for writing: " + pending_download_path)
    return
  file.store_buffer(body)
  file.flush()
  file.close()
  if OS.is_debug_build():
    print("download completed (", body.size(), " bytes), saved: ", pending_download_path)

  if pending_download_index == next_track_index:
    next_track_ready = true
    if play_when_download_finishes:
      play_when_download_finishes = false
      play_path(next_track_local_path)
      last_track_index = next_track_index
      prepare_next_track()
