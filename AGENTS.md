# Torrential — Agent Instructions

## Project Overview

Torrential is a native Linux TIDAL client with Hi-Res FLAC support (24-bit/192kHz). Built with Flutter/Dart, it uses TIDAL's internal API (`api.tidal.com/v1`) for browsing, searching, and streaming, and `media_kit` (libmpv) for audio playback.

**This is NOT an Electron app.** Flutter compiles to native code with GPU-rendered UI via Skia.

## Architecture

```
lib/
├── main.dart                    # Entry point, MediaKit init, Provider setup
├── core/
│   ├── tidal_auth.dart          # OAuth2 device auth flow, token management
│   └── tidal_api.dart           # Tidal internal API client (v1, NOT the public v2 API)
├── models/
│   └── models.dart              # Data models: Artist, Album, Track, Playlist, PlaybackInfo, etc.
├── services/
│   ├── app_state.dart           # Central state (ChangeNotifier/Provider), navigation, content loading
│   └── audio_player.dart        # media_kit Player wrapper, DASH/BTS manifest handling
└── ui/
    ├── theme/
    │   └── app_theme.dart       # Dark theme (Material 3)
    ├── screens/
    │   ├── login_screen.dart    # Device auth login flow
    │   ├── main_shell.dart      # App shell: sidebar + content area + now playing bar
    │   ├── home_screen.dart     # Home view (favorite albums, liked tracks)
    │   ├── search_screen.dart   # Search with debounced input
    │   ├── album_detail_screen.dart
    │   ├── artist_detail_screen.dart
    │   ├── playlist_detail_screen.dart
    │   └── collection_screen.dart  # Albums/Artists/Playlists collection views
    └── widgets/
        ├── album_grid.dart      # Responsive album grid with hover effects
        ├── track_list.dart      # Track list rows with quality badges
        └── now_playing_bar.dart # Bottom playback bar with seekable progress
```

## Key Technical Details

### Tidal API

- Uses the **internal** API at `api.tidal.com/v1`, NOT the public developer API at `openapi.tidal.com/v2`.
- The public API does not expose streaming endpoints (`playbackinfopostpaywall`).
- Auth uses **OAuth2 device authorization flow** with credentials extracted from the official Tidal app (same approach as [python-tidal](https://github.com/tamland/python-tidal)).
- Credentials are stored lightly obfuscated (reversed + base64) in `tidal_auth.dart`.
- Tokens are persisted via `shared_preferences`.

### Audio Playback

- `media_kit` wraps `libmpv` — handles DASH (FLAC) and direct URL (AAC) playback.
- For FLAC/Hi-Res: API returns base64-encoded MPEG-DASH MPD manifest → decoded → written to temp file → played via `file://` URI.
- For AAC: API returns base64-encoded JSON with direct CDN URLs → played directly.
- The audio chain is **lossless**: DASH demux → FLAC decode → PCM → PipeWire → DAC.
- `libmpv` must be installed on the system (`pacman -S mpv` on Arch).

### State Management

- Single `AppState` class using `ChangeNotifier` + `Provider`.
- `AudioPlayerService` streams state changes (playing, position, duration, track) to `AppState` which calls `notifyListeners()`.

## Conventions

- **Dark theme only** — pitch black background (`#0A0A0A`), card surfaces at `#1E1E1E`.
- **No comments unless complex** — code should be self-documenting.
- **Minimal dependencies** — don't add packages without checking if existing ones cover the need.
- **Linux only** — no need to consider Android/iOS/web platform concerns.
- **Error handling** — use `debugPrint` for dev errors, show user-facing errors via `SnackBar`.
- **Hover effects** — album cards scale on hover, track rows highlight. Maintain this interactive feel.

## Building & Running

```bash
export PATH="$HOME/projects/personal/fluttersdk/flutter/bin:$PATH"
cd ~/projects/personal/torrential

# Build
flutter build linux

# Run
./build/linux/x64/release/bundle/torrential
```

### System Dependencies (Arch/EndeavourOS)

```bash
sudo pacman -S clang ninja cmake gtk3 pkg-config mpv
```

## Roadmap / TODO

- [x] **Composer filter** — filter albums by composer in Albums collection view (uses `/albums/{id}/credits` endpoint, `Composer`/`Writer`/`Lyricist` credit types)
- [ ] **Volume control** — slider in now playing bar (`audioPlayer.setVolume()`)
- [ ] **Shuffle & repeat** — toggle buttons in now playing bar
- [ ] **Keyboard shortcuts** — Space=play/pause, Left/Right=seek, Ctrl+F=search
- [ ] **MPRIS integration** — system media key support (play/pause/next/prev from DE)
- [x] **App icon** — custom icon for desktop shortcut and window
- [ ] **Gapless playback polish** — pre-fetch next track manifest for seamless transition
- [ ] **Offline caching** — cache album art and metadata locally
- [ ] **Settings screen** — audio quality selector, audio output device, cache management

## Workflow

- **Small batches** — work incrementally, commit often after verifying each change builds.
- **Review & test** — run `flutter analyze` and `flutter build linux` after each change.
- **When in doubt, ask** — don't guess requirements; ask the user for clarification.
- **Follow existing patterns** — read surrounding code before making changes.
- **Update AGENTS.md** — keep the roadmap and docs in sync with completed work.

## Important Notes

- This is an **unofficial** third-party client. Not affiliated with TIDAL.
- Requires an active TIDAL subscription with Max quality for Hi-Res FLAC.
- The internal API may change without notice — if auth or playback breaks, check [python-tidal](https://github.com/tamland/python-tidal) for updated endpoints/credentials.
