import 'dart:convert';

// ─── Image URL helper ───────────────────────────────────────────────

String tidalImageUrl(String? imageId, {int width = 640, int height = 640}) {
  if (imageId == null || imageId.isEmpty) return '';
  final path = imageId.replaceAll('-', '/');
  return 'https://resources.tidal.com/images/$path/${width}x$height.jpg';
}

// ─── Artist ─────────────────────────────────────────────────────────

class Artist {
  final int id;
  final String name;
  final String? picture;
  final int? popularity;

  Artist({
    required this.id,
    required this.name,
    this.picture,
    this.popularity,
  });

  String get imageUrl => tidalImageUrl(picture);

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Unknown Artist',
      picture: json['picture'] as String?,
      popularity: json['popularity'] as int?,
    );
  }
}

// ─── Album ──────────────────────────────────────────────────────────

class Album {
  final int id;
  final String title;
  final String? cover;
  final int? numberOfTracks;
  final int? duration;
  final String? releaseDate;
  final String? copyright;
  final List<Artist> artists;
  final String? audioQuality;

  Album({
    required this.id,
    required this.title,
    this.cover,
    this.numberOfTracks,
    this.duration,
    this.releaseDate,
    this.copyright,
    this.artists = const [],
    this.audioQuality,
  });

  String get imageUrl => tidalImageUrl(cover);
  String get artistNames => artists.map((a) => a.name).join(', ');
  String? get year => releaseDate?.split('-').firstOrNull;

  factory Album.fromJson(Map<String, dynamic> json) {
    List<Artist> artists = [];
    if (json['artists'] != null) {
      artists = (json['artists'] as List<dynamic>)
          .map((a) => Artist.fromJson(a as Map<String, dynamic>))
          .toList();
    } else if (json['artist'] != null) {
      artists = [Artist.fromJson(json['artist'] as Map<String, dynamic>)];
    }

    return Album(
      id: json['id'] as int,
      title: json['title'] as String? ?? 'Unknown Album',
      cover: json['cover'] as String?,
      numberOfTracks: json['numberOfTracks'] as int?,
      duration: json['duration'] as int?,
      releaseDate: json['releaseDate'] as String?,
      copyright: json['copyright'] as String?,
      artists: artists,
      audioQuality: json['audioQuality'] as String?,
    );
  }
}

// ─── Track ──────────────────────────────────────────────────────────

class Track {
  final int id;
  final String title;
  final int duration;
  final int trackNumber;
  final String? version;
  final List<Artist> artists;
  final Album? album;
  final String? audioQuality;
  final bool explicit;

  Track({
    required this.id,
    required this.title,
    required this.duration,
    this.trackNumber = 0,
    this.version,
    this.artists = const [],
    this.album,
    this.audioQuality,
    this.explicit = false,
  });

  String get artistNames => artists.map((a) => a.name).join(', ');
  String get imageUrl => album?.imageUrl ?? '';

  String get durationFormatted {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get displayTitle {
    if (version != null && version!.isNotEmpty) {
      return '$title ($version)';
    }
    return title;
  }

  factory Track.fromJson(Map<String, dynamic> json) {
    List<Artist> artists = [];
    if (json['artists'] != null) {
      artists = (json['artists'] as List<dynamic>)
          .map((a) => Artist.fromJson(a as Map<String, dynamic>))
          .toList();
    } else if (json['artist'] != null) {
      artists = [Artist.fromJson(json['artist'] as Map<String, dynamic>)];
    }

    Album? album;
    if (json['album'] != null) {
      album = Album.fromJson(json['album'] as Map<String, dynamic>);
    }

    return Track(
      id: json['id'] as int,
      title: json['title'] as String? ?? 'Unknown Track',
      duration: json['duration'] as int? ?? 0,
      trackNumber: json['trackNumber'] as int? ?? 0,
      version: json['version'] as String?,
      artists: artists,
      album: album,
      audioQuality: json['audioQuality'] as String?,
      explicit: json['explicit'] as bool? ?? false,
    );
  }
}

// ─── Playlist ───────────────────────────────────────────────────────

class Playlist {
  final String uuid;
  final String title;
  final String? description;
  final String? image;
  final String? squareImage;
  final int numberOfTracks;
  final int duration;
  final String? creator;

  Playlist({
    required this.uuid,
    required this.title,
    this.description,
    this.image,
    this.squareImage,
    this.numberOfTracks = 0,
    this.duration = 0,
    this.creator,
  });

  String get imageUrl => tidalImageUrl(squareImage ?? image, width: 640, height: 640);

  factory Playlist.fromJson(Map<String, dynamic> json) {
    String? creatorName;
    if (json['creator'] is Map) {
      creatorName = (json['creator'] as Map<String, dynamic>)['name'] as String?;
    }

    return Playlist(
      uuid: json['uuid'] as String,
      title: json['title'] as String? ?? 'Unknown Playlist',
      description: json['description'] as String?,
      image: json['image'] as String?,
      squareImage: json['squareImage'] as String?,
      numberOfTracks: json['numberOfTracks'] as int? ?? 0,
      duration: json['duration'] as int? ?? 0,
      creator: creatorName,
    );
  }
}

// ─── Search Results ─────────────────────────────────────────────────

class SearchResults {
  final List<Artist> artists;
  final List<Album> albums;
  final List<Track> tracks;
  final List<Playlist> playlists;

  SearchResults({
    this.artists = const [],
    this.albums = const [],
    this.tracks = const [],
    this.playlists = const [],
  });

  factory SearchResults.fromJson(Map<String, dynamic> json) {
    return SearchResults(
      artists: json['artists'] != null
          ? (json['artists']['items'] as List<dynamic>)
              .map((e) => Artist.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      albums: json['albums'] != null
          ? (json['albums']['items'] as List<dynamic>)
              .map((e) => Album.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      tracks: json['tracks'] != null
          ? (json['tracks']['items'] as List<dynamic>)
              .map((e) => Track.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      playlists: json['playlists'] != null
          ? (json['playlists']['items'] as List<dynamic>)
              .map((e) => Playlist.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}

// ─── Playback Info ──────────────────────────────────────────────────

class PlaybackInfo {
  final int trackId;
  final String audioQuality;
  final String audioMode;
  final String manifestMimeType;
  final String manifest;
  final int? bitDepth;
  final int? sampleRate;
  final double? trackReplayGain;
  final double? trackPeakAmplitude;

  PlaybackInfo({
    required this.trackId,
    required this.audioQuality,
    required this.audioMode,
    required this.manifestMimeType,
    required this.manifest,
    this.bitDepth,
    this.sampleRate,
    this.trackReplayGain,
    this.trackPeakAmplitude,
  });

  /// Whether this is a DASH manifest (used for FLAC).
  bool get isDash => manifestMimeType == 'application/dash+xml';

  /// Whether this is a BTS manifest (used for AAC).
  bool get isBts => manifestMimeType == 'application/vnd.tidal.bts';

  /// Decode the base64 manifest.
  String get decodedManifest => utf8.decode(base64.decode(manifest));

  /// Get direct stream URLs from a BTS manifest.
  List<String> get streamUrls {
    final decoded = jsonDecode(decodedManifest) as Map<String, dynamic>;
    return (decoded['urls'] as List<dynamic>).cast<String>();
  }

  String get qualityLabel {
    if (bitDepth != null && sampleRate != null) {
      return '$bitDepth-bit / ${(sampleRate! / 1000).toStringAsFixed(1)}kHz';
    }
    return audioQuality;
  }

  factory PlaybackInfo.fromJson(Map<String, dynamic> json) {
    return PlaybackInfo(
      trackId: json['trackId'] as int,
      audioQuality: json['audioQuality'] as String? ?? 'LOW',
      audioMode: json['audioMode'] as String? ?? 'STEREO',
      manifestMimeType: json['manifestMimeType'] as String? ?? '',
      manifest: json['manifest'] as String? ?? '',
      bitDepth: json['bitDepth'] as int?,
      sampleRate: json['sampleRate'] as int?,
      trackReplayGain: (json['trackReplayGain'] as num?)?.toDouble(),
      trackPeakAmplitude: (json['trackPeakAmplitude'] as num?)?.toDouble(),
    );
  }
}

// ─── Album Credits ──────────────────────────────────────────────────

class CreditEntry {
  final String type;
  final List<CreditContributor> contributors;

  CreditEntry({required this.type, required this.contributors});

  factory CreditEntry.fromJson(Map<String, dynamic> json) {
    return CreditEntry(
      type: json['type'] as String? ?? '',
      contributors: (json['contributors'] as List<dynamic>? ?? [])
          .map((e) => CreditContributor.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CreditContributor {
  final String name;
  final int? id;

  CreditContributor({required this.name, this.id});

  factory CreditContributor.fromJson(Map<String, dynamic> json) {
    return CreditContributor(
      name: json['name'] as String? ?? '',
      id: json['id'] as int?,
    );
  }
}

class AlbumCredits {
  final List<CreditEntry> entries;

  AlbumCredits({required this.entries});

  /// Get all unique composers across all tracks.
  List<String> get composers {
    final result = <String>{};
    for (final entry in entries) {
      final type = entry.type.toLowerCase();
      if (type.contains('composer') ||
          type.contains('compuesto') ||
          type.contains('arranger') ||
          type.contains('writer') ||
          type.contains('lyricist')) {
        for (final c in entry.contributors) {
          result.add(c.name);
        }
      }
    }
    return result.toList()..sort();
  }

  factory AlbumCredits.fromJson(Map<String, dynamic> json) {
    final items = json['items'] as List<dynamic>? ?? [];
    // Credits come as a list of track credit sets
    final allEntries = <CreditEntry>[];
    for (final trackCredits in items) {
      final credits = trackCredits['credits'] as List<dynamic>? ?? [];
      for (final credit in credits) {
        allEntries.add(CreditEntry.fromJson(credit as Map<String, dynamic>));
      }
    }
    return AlbumCredits(entries: allEntries);
  }

  factory AlbumCredits.fromJsonList(List<dynamic> json) {
    final allEntries = <CreditEntry>[];
    for (final item in json) {
      allEntries.add(CreditEntry.fromJson(item as Map<String, dynamic>));
    }
    return AlbumCredits(entries: allEntries);
  }
}
