import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart' hide Track;
import 'package:path_provider/path_provider.dart';
import '../core/tidal_api.dart';
import '../models/models.dart';

/// Wraps media_kit Player for Tidal audio streaming.
/// Handles DASH manifest (FLAC/Hi-Res) and BTS manifest (AAC) playback.
class AudioPlayerService {
  final Player _player;
  final TidalApi api;

  // Current state
  Track? _currentTrack;
  PlaybackInfo? _currentPlaybackInfo;
  List<Track> _queue = [];
  int _queueIndex = -1;

  // Stream controllers for UI updates
  final _trackController = StreamController<Track?>.broadcast();
  final _playbackInfoController = StreamController<PlaybackInfo?>.broadcast();
  final _queueController = StreamController<List<Track>>.broadcast();

  Stream<Track?> get trackStream => _trackController.stream;
  Stream<PlaybackInfo?> get playbackInfoStream => _playbackInfoController.stream;
  Stream<List<Track>> get queueStream => _queueController.stream;

  // Expose player streams directly
  Stream<bool> get playingStream => _player.stream.playing;
  Stream<Duration> get positionStream => _player.stream.position;
  Stream<Duration> get durationStream => _player.stream.duration;
  Stream<bool> get completedStream => _player.stream.completed;

  // Direct state access
  bool get isPlaying => _player.state.playing;
  Duration get position => _player.state.position;
  Duration get duration => _player.state.duration;
  Track? get currentTrack => _currentTrack;
  PlaybackInfo? get currentPlaybackInfo => _currentPlaybackInfo;
  List<Track> get queue => _queue;
  int get queueIndex => _queueIndex;

  AudioPlayerService({required this.api})
      : _player = Player() {
    // Auto-advance to next track on completion
    _player.stream.completed.listen((completed) {
      if (completed && _queueIndex < _queue.length - 1) {
        playNext();
      }
    });
  }

  /// Play a track, optionally setting the queue.
  Future<void> playTrack(Track track,
      {List<Track>? trackList, int? index}) async {
    _currentTrack = track;
    _trackController.add(track);

    if (trackList != null) {
      _queue = List.from(trackList);
      _queueIndex = index ?? 0;
      _queueController.add(_queue);
    }

    try {
      // Fetch playback info (stream URLs)
      _currentPlaybackInfo = await api.getPlaybackInfo(track.id);
      _playbackInfoController.add(_currentPlaybackInfo);

      final info = _currentPlaybackInfo!;
      String mediaUri;

      if (info.isDash) {
        // DASH manifest (FLAC / Hi-Res FLAC)
        // Save MPD to temp file and play from file://
        final tempDir = await getTemporaryDirectory();
        final mpdFile = File('${tempDir.path}/torrential_manifest.mpd');
        await mpdFile.writeAsString(info.decodedManifest);
        mediaUri = mpdFile.uri.toString();
      } else if (info.isBts) {
        // BTS manifest (AAC) — direct URL
        final urls = info.streamUrls;
        if (urls.isEmpty) throw Exception('No stream URLs in BTS manifest');
        mediaUri = urls.first;
      } else {
        throw Exception('Unknown manifest type: ${info.manifestMimeType}');
      }

      await _player.open(Media(mediaUri));

      debugPrint(
          'Playing: ${track.title} [${info.audioQuality} ${info.qualityLabel}]');
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
    await _player.setVolume(volume * 100); // media_kit uses 0-100
  }

  Future<void> playNext() async {
    if (_queue.isEmpty || _queueIndex >= _queue.length - 1) return;
    _queueIndex++;
    await playTrack(_queue[_queueIndex],
        trackList: _queue, index: _queueIndex);
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
      await playTrack(_queue[_queueIndex],
          trackList: _queue, index: _queueIndex);
    }
  }

  void dispose() {
    _player.dispose();
    _trackController.close();
    _playbackInfoController.close();
    _queueController.close();
  }
}
