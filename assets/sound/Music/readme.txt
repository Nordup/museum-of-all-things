Museum music is not stored in the project. Tracks are downloaded on demand
from https://thegates.io/worlds/exports/museum_of_all_things/Music,
cached to user://music, and then played from the cached file.

Track filenames are listed in scenes/MusicController.gd (TRACK_FILENAMES).
To clear the cache, delete the user://music folder.

This folder contains a .gdignore so Godot won’t import or bundle anything
placed here; the runtime downloader handles delivery and caching.
