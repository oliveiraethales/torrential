import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart' hide Track;
import 'package:path_provider/path_provider.dart';
import '../core/tidal_api.dart';
import '../core/tidal_auth.dart';
import '../models/models.dart';

enum PlayerRepeatMode { off, all, one }

/// Wraps media_kit Player for Tidal audio streaming.
/// Handles DASH manifest (FLAC/Hi-Res) and BTS manifest (AAC) playback.
class AudioPlayerService {
  final Player _player;
  final TidalApi api;

  // Current state
  Track? _currentTrack;
  PlaybackInfo? _currentPlaybackInfo;
  List<Track> _queue = [];
  List<Track> _originalQueue = [];
  int _queueIndex = -1;
  bool _shuffle = false;
  PlayerRepeatMode _repeat = PlayerRepeatMode.off;
  bool _enableDolbyAtmos = true;

  // Stream controllers for UI updates
  final _trackController = StreamController<Track?>.broadcast();
  final _playbackInfoController = StreamController<PlaybackInfo?>.broadcast();
  final _queueController = StreamController<List<Track>>.broadcast();
  final _shuffleController = StreamController<bool>.broadcast();
  final _repeatController = StreamController<PlayerRepeatMode>.broadcast();
  final _dolbyAtmosController = StreamController<bool>.broadcast();

  Stream<Track?> get trackStream => _trackController.stream;
  Stream<PlaybackInfo?> get playbackInfoStream =>
      _playbackInfoController.stream;
  Stream<List<Track>> get queueStream => _queueController.stream;
  Stream<bool> get shuffleStream => _shuffleController.stream;
  Stream<PlayerRepeatMode> get repeatStream => _repeatController.stream;
  Stream<bool> get dolbyAtmosStream => _dolbyAtmosController.stream;

  // Expose player streams directly
  Stream<bool> get playingStream => _player.stream.playing;
  Stream<Duration> get positionStream => _player.stream.position;
  Stream<Duration> get durationStream => _player.stream.duration;
  Stream<bool> get completedStream => _player.stream.completed;

  // Direct state access
  bool get isPlaying => _player.state.playing;
  double get volume => _player.state.volume;
  Duration get position => _player.state.position;
  Duration get duration => _player.state.duration;
  Track? get currentTrack => _currentTrack;
  PlaybackInfo? get currentPlaybackInfo => _currentPlaybackInfo;
  List<Track> get queue => _queue;
  int get queueIndex => _queueIndex;
  bool get shuffle => _shuffle;
  PlayerRepeatMode get repeat => _repeat;
  bool get enableDolbyAtmos => _enableDolbyAtmos;

  void setEnableDolbyAtmos(bool enable) {
    if (_enableDolbyAtmos == enable) return;
    _enableDolbyAtmos = enable;
    _dolbyAtmosController.add(_enableDolbyAtmos);
    if (_currentTrack != null) {
      playTrack(_currentTrack!);
    }
  }

  void toggleDolbyAtmos() => setEnableDolbyAtmos(!_enableDolbyAtmos);

  AudioPlayerService({required this.api}) : _player = Player() {
    _player.stream.completed.listen((completed) {
      if (!completed) return;
      _onTrackCompleted();
    });
  }

  Future<void> _onTrackCompleted() async {
    if (_repeat == PlayerRepeatMode.one && _currentTrack != null) {
      await playTrack(_currentTrack!);
      return;
    }
    if (_queue.isEmpty) return;
    if (_queueIndex < _queue.length - 1) {
      await playNext();
    } else if (_repeat == PlayerRepeatMode.all) {
      _queueIndex = 0;
      await playTrack(_queue[0], trackList: _queue, index: 0);
    }
  }

  /// Play a track, optionally setting the queue.
  Future<void> playTrack(
    Track track, {
    List<Track>? trackList,
    int? index,
  }) async {
    _currentTrack = track;
    _trackController.add(track);

    if (trackList != null) {
      _originalQueue = List.from(trackList);
      final startIndex = index ?? 0;
      if (_shuffle) {
        final shuffled = List<Track>.from(trackList)..shuffle();
        shuffled.removeWhere((t) => identical(t, track) || t.id == track.id);
        shuffled.insert(0, track);
        _queue = shuffled;
        _queueIndex = 0;
      } else {
        _queue = List.from(trackList);
        _queueIndex = startIndex;
      }
      _queueController.add(_queue);
    }

    try {
      // Fetch playback info (stream URLs)
      PlaybackInfo info;
      if (_enableDolbyAtmos && track.isDolbyAtmos) {
        try {
          info = await api.getPlaybackInfo(
            track.id,
            quality: AudioQuality.dolbyAtmos,
          );
        } catch (e) {
          debugPrint('Dolby Atmos request failed, falling back to Hi-Res: $e');
          info = await api.getPlaybackInfo(
            track.id,
            quality: AudioQuality.hiResLossless,
          );
        }
      } else {
        info = await api.getPlaybackInfo(
          track.id,
          quality: AudioQuality.hiResLossless,
        );
      }
      _currentPlaybackInfo = info;
      _playbackInfoController.add(_currentPlaybackInfo);

      final infoRef = _currentPlaybackInfo!;
      String mediaUri;

      if (infoRef.isDash) {
        // DASH manifest (FLAC / Hi-Res FLAC / Dolby Atmos)
        // Save MPD to temp file and play from file://
        final tempDir = await getTemporaryDirectory();
        final mpdFile = File('${tempDir.path}/torrential_manifest.mpd');
        await mpdFile.writeAsString(infoRef.decodedManifest);
        mediaUri = mpdFile.uri.toString();
      } else if (infoRef.isBts) {
        // BTS manifest (AAC / Dolby Atmos BTS) — direct URL
        final urls = infoRef.streamUrls;
        if (urls.isEmpty) throw Exception('No stream URLs in BTS manifest');
        mediaUri = urls.first;
      } else {
        throw Exception('Unknown manifest type: ${infoRef.manifestMimeType}');
      }

      await _player.open(Media(mediaUri));

      debugPrint(
        'Playing: ${track.title} [${infoRef.audioQuality} ${infoRef.qualityLabel}]',
      );
    } catch (e) {
      debugPrint('Playback error: $e');
      _currentPlaybackInfo = null;
      _playbackInfoController.add(null);
    }
  }

  void togglePlayPause() {
    _player.playOrPause();
  }

  void pause() {
    _player.pause();
  }

  void play() {
    _player.play();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }

  Future<void> playNext() async {
    if (_queue.isEmpty) return;
    if (_queueIndex < _queue.length - 1) {
      _queueIndex++;
    } else if (_repeat == PlayerRepeatMode.all) {
      _queueIndex = 0;
    } else {
      return;
    }
    await playTrack(_queue[_queueIndex]);
  }

  Future<void> playFromQueue(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _queueIndex = index;
    await playTrack(_queue[index]);
  }

  Future<void> playPrevious() async {
    if (_queue.isEmpty) return;
    // If we're more than 3 seconds in, restart current track
    if (_player.state.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }
    if (_queueIndex > 0) {
      _queueIndex--;
    } else if (_repeat == PlayerRepeatMode.all) {
      _queueIndex = _queue.length - 1;
    } else {
      return;
    }
    await playTrack(_queue[_queueIndex]);
  }

  void setShuffle(bool enabled) {
    if (_shuffle == enabled) return;
    _shuffle = enabled;
    _shuffleController.add(_shuffle);

    if (_queue.isEmpty) return;

    final current = (_queueIndex >= 0 && _queueIndex < _queue.length)
        ? _queue[_queueIndex]
        : null;

    if (enabled) {
      _originalQueue = List.from(_queue);
      final shuffled = List<Track>.from(_queue);
      if (current != null) {
        shuffled.removeWhere(
          (t) => identical(t, current) || t.id == current.id,
        );
      }
      shuffled.shuffle();
      if (current != null) {
        shuffled.insert(0, current);
        _queueIndex = 0;
      }
      _queue = shuffled;
    } else {
      if (_originalQueue.isNotEmpty) {
        _queue = List.from(_originalQueue);
      }
      if (current != null) {
        final i = _queue.indexWhere((t) => t.id == current.id);
        _queueIndex = i >= 0 ? i : 0;
      }
    }
    _queueController.add(_queue);
  }

  void toggleShuffle() => setShuffle(!_shuffle);

  void setRepeat(PlayerRepeatMode mode) {
    if (_repeat == mode) return;
    _repeat = mode;
    _repeatController.add(_repeat);
  }

  void cycleRepeat() {
    switch (_repeat) {
      case PlayerRepeatMode.off:
        setRepeat(PlayerRepeatMode.all);
        break;
      case PlayerRepeatMode.all:
        setRepeat(PlayerRepeatMode.one);
        break;
      case PlayerRepeatMode.one:
        setRepeat(PlayerRepeatMode.off);
        break;
    }
  }

  void dispose() {
    _player.dispose();
    _trackController.close();
    _playbackInfoController.close();
    _queueController.close();
    _shuffleController.close();
    _repeatController.close();
    _dolbyAtmosController.close();
  }
}
