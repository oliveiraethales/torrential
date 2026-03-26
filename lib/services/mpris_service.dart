import 'package:dbus/dbus.dart';
import 'package:flutter/foundation.dart';
import 'audio_player.dart';

const _mprisInterface = 'org.mpris.MediaPlayer2';
const _playerInterface = 'org.mpris.MediaPlayer2.Player';
const _propertiesInterface = 'org.freedesktop.DBus.Properties';

class _MprisObject extends DBusObject {
  final AudioPlayerService audioPlayer;

  _MprisObject(this.audioPlayer)
      : super(DBusObjectPath('/org/mpris/MediaPlayer2'));

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface == _playerInterface) {
      switch (methodCall.name) {
        case 'PlayPause':
          audioPlayer.togglePlayPause();
          return DBusMethodSuccessResponse();
        case 'Play':
          audioPlayer.play();
          return DBusMethodSuccessResponse();
        case 'Pause':
          audioPlayer.pause();
          return DBusMethodSuccessResponse();
        case 'Next':
          audioPlayer.playNext();
          return DBusMethodSuccessResponse();
        case 'Previous':
          audioPlayer.playPrevious();
          return DBusMethodSuccessResponse();
      }
    }
    return DBusMethodErrorResponse.unknownMethod();
  }

  @override
  Future<DBusMethodResponse> getProperty(String interface, String name) async {
    if (interface == _mprisInterface) {
      switch (name) {
        case 'CanQuit':
          return DBusGetPropertyResponse(const DBusBoolean(false));
        case 'CanRaise':
          return DBusGetPropertyResponse(const DBusBoolean(false));
        case 'HasTrackList':
          return DBusGetPropertyResponse(const DBusBoolean(false));
        case 'Identity':
          return DBusGetPropertyResponse(const DBusString('Torrential'));
        case 'SupportedUriSchemes':
          return DBusGetPropertyResponse(DBusArray.string([]));
        case 'SupportedMimeTypes':
          return DBusGetPropertyResponse(DBusArray.string([]));
      }
    }

    if (interface == _playerInterface) {
      switch (name) {
        case 'PlaybackStatus':
          final status = audioPlayer.isPlaying ? 'Playing' : 'Paused';
          return DBusGetPropertyResponse(DBusString(status));
        case 'CanPlay':
          return DBusGetPropertyResponse(const DBusBoolean(true));
        case 'CanPause':
          return DBusGetPropertyResponse(const DBusBoolean(true));
        case 'CanGoNext':
          return DBusGetPropertyResponse(const DBusBoolean(true));
        case 'CanGoPrevious':
          return DBusGetPropertyResponse(const DBusBoolean(true));
        case 'CanSeek':
          return DBusGetPropertyResponse(const DBusBoolean(false));
        case 'CanControl':
          return DBusGetPropertyResponse(const DBusBoolean(true));
        case 'Metadata':
          return DBusGetPropertyResponse(_buildMetadata());
      }
    }

    return DBusMethodErrorResponse.unknownProperty();
  }

  @override
  Future<DBusMethodResponse> getAllProperties(String interface) async {
    if (interface == _mprisInterface) {
      return DBusGetAllPropertiesResponse({
        'CanQuit': const DBusBoolean(false),
        'CanRaise': const DBusBoolean(false),
        'HasTrackList': const DBusBoolean(false),
        'Identity': const DBusString('Torrential'),
        'SupportedUriSchemes': DBusArray.string([]),
        'SupportedMimeTypes': DBusArray.string([]),
      });
    }

    if (interface == _playerInterface) {
      return DBusGetAllPropertiesResponse({
        'PlaybackStatus':
            DBusString(audioPlayer.isPlaying ? 'Playing' : 'Paused'),
        'CanPlay': const DBusBoolean(true),
        'CanPause': const DBusBoolean(true),
        'CanGoNext': const DBusBoolean(true),
        'CanGoPrevious': const DBusBoolean(true),
        'CanSeek': const DBusBoolean(false),
        'CanControl': const DBusBoolean(true),
        'Metadata': _buildMetadata(),
      });
    }

    return DBusGetAllPropertiesResponse({});
  }

  DBusValue _buildMetadata() {
    final track = audioPlayer.currentTrack;
    final entries = <DBusString, DBusValue>{
      const DBusString('mpris:trackid'): DBusObjectPath(
        '/org/mpris/MediaPlayer2/Track/${track?.id ?? 0}',
      ),
    };

    if (track != null) {
      entries[const DBusString('xesam:title')] =
          DBusString(track.displayTitle);
      entries[const DBusString('xesam:artist')] =
          DBusArray.string([track.artistNames]);
      if (track.album != null) {
        entries[const DBusString('xesam:album')] =
            DBusString(track.album!.title);
      }
      if (track.imageUrl.isNotEmpty) {
        entries[const DBusString('mpris:artUrl')] =
            DBusString(track.imageUrl);
      }
      entries[const DBusString('mpris:length')] =
          DBusInt64(track.duration * 1000000); // microseconds
    }

    return DBusDict(
      DBusSignature('s'),
      DBusSignature('v'),
      entries.map((k, v) => MapEntry(k, DBusVariant(v))),
    );
  }

  void emitPlaybackChanged(Map<String, DBusValue> changed) {
    emitSignal(
      _propertiesInterface,
      'PropertiesChanged',
      [
        const DBusString(_playerInterface),
        DBusDict.stringVariant(changed),
        DBusArray(DBusSignature('s'), []),
      ],
    );
  }
}

class MprisService {
  DBusClient? _client;
  _MprisObject? _object;

  Future<void> initialize(AudioPlayerService audioPlayer) async {
    try {
      _client = DBusClient.session();
      _object = _MprisObject(audioPlayer);

      await _client!.requestName('org.mpris.MediaPlayer2.torrential');
      await _client!.registerObject(_object!);

      audioPlayer.playingStream.listen((playing) {
        _object?.emitPlaybackChanged({
          'PlaybackStatus': DBusString(playing ? 'Playing' : 'Paused'),
        });
      });

      audioPlayer.trackStream.listen((_) {
        _object?.emitPlaybackChanged({
          'Metadata': _object!._buildMetadata(),
        });
      });

      debugPrint('MPRIS service registered');
    } catch (e) {
      debugPrint('MPRIS init failed: $e');
    }
  }

  Future<void> dispose() async {
    await _client?.close();
  }
}
