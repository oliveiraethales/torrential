# 🌊 Torrential

A modern and sleek, native Linux client for TIDAL with Hi-Res FLAC streaming (24-bit/192kHz).

Built with Flutter — not Electron. Native GPU-rendered UI, lossless audio via libmpv.

![License](https://img.shields.io/badge/license-MIT-blue)
![Platform](https://img.shields.io/badge/platform-Linux-green)
![Audio](https://img.shields.io/badge/audio-Hi--Res%20FLAC-gold)

## Features

- 🎵 **Hi-Res FLAC** — stream up to 24-bit/192kHz lossless audio
- 🔍 **Search** — find artists, albums, tracks, and playlists
- 📚 **Library** — browse your favorite albums, artists, and playlists
- 🎨 **Dark theme** — pitch black UI designed for focus on music
- ⚡ **Native performance** — Flutter compiles to native code, renders via Skia
- 🔊 **Lossless chain** — DASH → FLAC decode → PCM → PipeWire → DAC

## Screenshots

*Coming soon*

## Requirements

- Linux (tested on EndeavourOS/Arch)
- Active TIDAL subscription (Max quality for Hi-Res FLAC)
- System dependencies:
  ```bash
  # Arch/EndeavourOS
  sudo pacman -S clang ninja cmake gtk3 pkg-config mpv

  # Debian/Ubuntu
  sudo apt install clang ninja-build cmake libgtk-3-dev pkg-config libmpv-dev
  ```

## Building

```bash
# Clone
git clone https://github.com/YOUR_USERNAME/torrential.git
cd torrential

# Ensure Flutter is in PATH
export PATH="/path/to/flutter/bin:$PATH"

# Build
flutter build linux

# Run
./build/linux/x64/release/bundle/torrential
```

## How It Works

Torrential uses TIDAL's internal API (`api.tidal.com/v1`) — the same API used by the official apps — to authenticate, browse, and stream music. Audio playback is handled by [media_kit](https://github.com/media-kit/media-kit) (libmpv), which natively supports MPEG-DASH + FLAC decoding.

The audio chain is fully lossless:
```
TIDAL CDN → DASH demux → FLAC decode → PCM (24-bit/192kHz) → PipeWire → DAC
```

Authentication uses the OAuth2 device authorization flow — click "Sign in", visit the link, authorize in your browser, done.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI Framework | Flutter (Dart) — Material 3, dark theme |
| Audio Engine | media_kit → libmpv → PipeWire |
| API | TIDAL internal v1 (same as official apps) |
| Auth | OAuth2 device authorization flow |
| State | Provider + ChangeNotifier |

## Disclaimer

This is an **unofficial** third-party client, not affiliated with TIDAL in any way. Use at your own risk. Requires a valid TIDAL subscription.

## License

MIT
