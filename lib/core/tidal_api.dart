import 'dart:convert';
import 'package:http/http.dart' as http;
import 'tidal_auth.dart';
import '../models/models.dart';

/// Client for Tidal's internal API (api.tidal.com/v1).
class TidalApi {
  static const _baseUrl = 'https://api.tidal.com/v1';
  final TidalAuth auth;
  final http.Client _httpClient;

  TidalApi({required this.auth, http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, String>? params,
  }) async {
    await auth.ensureValidToken();

    final queryParams = {
      'countryCode': auth.countryCode,
      'limit': '50',
      ...?params,
    };

    final uri = Uri.parse(
      '$_baseUrl$path',
    ).replace(queryParameters: queryParams);
    final response = await _httpClient.get(uri, headers: auth.apiHeaders);

    if (response.statusCode == 401 || response.statusCode == 500) {
      await auth.ensureValidToken(force: true);
      final retryResponse = await _httpClient.get(
        uri,
        headers: auth.apiHeaders,
      );
      if (retryResponse.statusCode != 200) {
        throw Exception('API request failed: ${retryResponse.statusCode}');
      }
      return jsonDecode(retryResponse.body) as Map<String, dynamic>;
    }

    if (response.statusCode != 200) {
      throw Exception(
        'API request failed: ${response.statusCode} ${response.body}',
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<dynamic>> _getList(
    String path, {
    Map<String, String>? params,
  }) async {
    await auth.ensureValidToken();

    final queryParams = {
      'countryCode': auth.countryCode,
      'limit': '50',
      ...?params,
    };

    final uri = Uri.parse(
      '$_baseUrl$path',
    ).replace(queryParameters: queryParams);
    final response = await _httpClient.get(uri, headers: auth.apiHeaders);

    if (response.statusCode == 401 || response.statusCode == 500) {
      await auth.ensureValidToken(force: true);
      final retryResponse = await _httpClient.get(
        uri,
        headers: auth.apiHeaders,
      );
      if (retryResponse.statusCode != 200) {
        throw Exception('API request failed: ${retryResponse.statusCode}');
      }
      return jsonDecode(retryResponse.body) as List<dynamic>;
    }

    if (response.statusCode != 200) {
      throw Exception(
        'API request failed: ${response.statusCode} ${response.body}',
      );
    }

    return jsonDecode(response.body) as List<dynamic>;
  }

  // ─── Search ───────────────────────────────────────────────────────

  Future<SearchResults> search(String query, {int limit = 20}) async {
    final data = await _get(
      '/search',
      params: {
        'query': query,
        'limit': '$limit',
        'types': 'ARTISTS,ALBUMS,TRACKS,PLAYLISTS',
      },
    );
    return SearchResults.fromJson(data);
  }

  // ─── Artists ──────────────────────────────────────────────────────

  Future<Artist> getArtist(int id) async {
    final data = await _get('/artists/$id');
    return Artist.fromJson(data);
  }

  Future<List<Album>> getArtistAlbums(int artistId, {int limit = 50}) async {
    final data = await _get(
      '/artists/$artistId/albums',
      params: {'limit': '$limit'},
    );
    final items = data['items'] as List<dynamic>;
    return items.map((e) => Album.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Track>> getArtistTopTracks(int artistId, {int limit = 20}) async {
    final data = await _get(
      '/artists/$artistId/toptracks',
      params: {'limit': '$limit'},
    );
    final items = data['items'] as List<dynamic>;
    return items.map((e) => Track.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ─── Albums ───────────────────────────────────────────────────────

  Future<Album> getAlbum(int id) async {
    final data = await _get('/albums/$id');
    return Album.fromJson(data);
  }

  Future<List<Track>> getAlbumTracks(int albumId) async {
    final data = await _get(
      '/albums/$albumId/tracks',
      params: {'limit': '100'},
    );
    final items = data['items'] as List<dynamic>;
    return items.map((e) => Track.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<AlbumCredits> getAlbumCredits(int albumId) async {
    final data = await _getList('/albums/$albumId/credits');
    return AlbumCredits.fromJsonList(data);
  }

  // ─── Tracks ───────────────────────────────────────────────────────

  Future<Track> getTrack(int id) async {
    final data = await _get('/tracks/$id');
    return Track.fromJson(data);
  }

  /// Get the playback manifest for a track. This is the key endpoint
  /// for streaming — returns CDN URLs for the audio segments.
  Future<PlaybackInfo> getPlaybackInfo(
    int trackId, {
    AudioQuality quality = AudioQuality.hiResLossless,
  }) async {
    final data = await _get(
      '/tracks/$trackId/playbackinfopostpaywall',
      params: {
        'playbackmode': 'STREAM',
        'audioquality': quality.apiValue,
        'assetpresentation': 'FULL',
      },
    );
    return PlaybackInfo.fromJson(data);
  }

  // ─── Playlists ────────────────────────────────────────────────────

  Future<Playlist> getPlaylist(String uuid) async {
    final data = await _get('/playlists/$uuid');
    return Playlist.fromJson(data);
  }

  Future<List<Track>> getPlaylistTracks(String uuid, {int limit = 100}) async {
    final data = await _get(
      '/playlists/$uuid/tracks',
      params: {'limit': '$limit'},
    );
    final items = data['items'] as List<dynamic>;
    return items.map((e) => Track.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ─── User Collection (Favorites) ─────────────────────────────────

  Future<({List<Album> items, int totalItems})> getFavoriteAlbums({int limit = 100, int offset = 0}) async {
    final userId = auth.userId;
    if (userId == null) throw Exception('User not logged in');
    final data = await _get(
      '/users/$userId/favorites/albums',
      params: {'limit': '$limit', 'offset': '$offset', 'order': 'DATE', 'orderDirection': 'DESC'},
    );
    final items = data['items'] as List<dynamic>;
    final totalItems = data['totalNumberOfItems'] as int? ?? items.length;
    return (
      items: items
          .map((e) => Album.fromJson(e['item'] as Map<String, dynamic>))
          .toList(),
      totalItems: totalItems,
    );
  }

  Future<List<Artist>> getFavoriteArtists({int limit = 100}) async {
    final userId = auth.userId;
    if (userId == null) throw Exception('User not logged in');
    final data = await _get(
      '/users/$userId/favorites/artists',
      params: {'limit': '$limit', 'order': 'DATE', 'orderDirection': 'DESC'},
    );
    final items = data['items'] as List<dynamic>;
    return items
        .map((e) => Artist.fromJson(e['item'] as Map<String, dynamic>))
        .toList();
  }

  Future<List<Track>> getFavoriteTracks({int limit = 100}) async {
    final userId = auth.userId;
    if (userId == null) throw Exception('User not logged in');
    final data = await _get(
      '/users/$userId/favorites/tracks',
      params: {'limit': '$limit', 'order': 'DATE', 'orderDirection': 'DESC'},
    );
    final items = data['items'] as List<dynamic>;
    return items
        .map((e) => Track.fromJson(e['item'] as Map<String, dynamic>))
        .toList();
  }

  Future<List<Playlist>> getFavoritePlaylists({int limit = 100}) async {
    final userId = auth.userId;
    if (userId == null) throw Exception('User not logged in');
    final data = await _get(
      '/users/$userId/favorites/playlists',
      params: {'limit': '$limit', 'order': 'DATE', 'orderDirection': 'DESC'},
    );
    final items = data['items'] as List<dynamic>;
    return items
        .map((e) => Playlist.fromJson(e['item'] as Map<String, dynamic>))
        .toList();
  }

  Future<List<Playlist>> getUserPlaylists({int limit = 100}) async {
    final userId = auth.userId;
    if (userId == null) throw Exception('User not logged in');
    final data = await _get(
      '/users/$userId/playlists',
      params: {'limit': '$limit', 'order': 'DATE', 'orderDirection': 'DESC'},
    );
    final items = data['items'] as List<dynamic>;
    return items
        .map((e) => Playlist.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── Add/Remove Favorites ────────────────────────────────────────

  Future<void> addFavoriteTrack(int trackId) async {
    await _post(
      '/users/${auth.userId}/favorites/tracks',
      body: {'trackId': '$trackId'},
    );
  }

  Future<void> addFavoriteAlbum(int albumId) async {
    await _post(
      '/users/${auth.userId}/favorites/albums',
      body: {'albumId': '$albumId'},
    );
  }

  Future<void> addFavoriteArtist(int artistId) async {
    await _post(
      '/users/${auth.userId}/favorites/artists',
      body: {'artistId': '$artistId'},
    );
  }

  Future<void> removeFavoriteTrack(int trackId) async {
    await _delete('/users/${auth.userId}/favorites/tracks/$trackId');
  }

  Future<void> removeFavoriteAlbum(int albumId) async {
    await _delete('/users/${auth.userId}/favorites/albums/$albumId');
  }

  Future<void> removeFavoriteArtist(int artistId) async {
    await _delete('/users/${auth.userId}/favorites/artists/$artistId');
  }

  // ─── Playlist creation ───────────────────────────────────────────

  /// Create a new user playlist with the given [title] and optional
  /// [description]. Returns the freshly created [Playlist].
  Future<Playlist> createPlaylist(String title, {String description = ''}) async {
    await auth.ensureValidToken();
    final userId = auth.userId;
    final response = await _postRaw(
      '/users/$userId/playlists',
      body: {
        'title': title,
        'description': description,
      },
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return Playlist.fromJson(data);
  }

  // ─── Playlist mutation ───────────────────────────────────────────

  /// Fetch a playlist's ETag, required by Tidal for any mutation
  /// (`If-None-Match` header on POST/DELETE).
  Future<String> _getPlaylistEtag(String uuid) async {
    await auth.ensureValidToken();
    final uri = Uri.parse(
      '$_baseUrl/playlists/$uuid',
    ).replace(queryParameters: {'countryCode': auth.countryCode});
    final response = await _httpClient.get(uri, headers: auth.apiHeaders);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch playlist ETag: ${response.statusCode}');
    }
    final etag = response.headers['etag'];
    if (etag == null) {
      throw Exception('Playlist response missing ETag header');
    }
    return etag;
  }

  /// Add one or more tracks to a user playlist.
  /// Returns the number of tracks actually added (duplicates skipped if any).
  Future<int> addTracksToPlaylist(String uuid, List<int> trackIds) async {
    if (trackIds.isEmpty) return 0;
    final etag = await _getPlaylistEtag(uuid);
    final response = await _postRaw(
      '/playlists/$uuid/items',
      body: {
        'trackIds': trackIds.join(','),
        'onArtifactNotFound': 'FAIL',
        'onDupes': 'ADD',
      },
      extraHeaders: {'If-None-Match': etag},
    );
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final added = data['addedItemIds'] as List<dynamic>?;
      if (added != null) return added.length;
    } catch (_) {}
    return trackIds.length;
  }

  // ─── HTTP helpers ─────────────────────────────────────────────────

  Future<http.Response> _postRaw(
    String path, {
    Map<String, String>? body,
    Map<String, String>? extraHeaders,
  }) async {
    await auth.ensureValidToken();
    final uri = Uri.parse(
      '$_baseUrl$path',
    ).replace(queryParameters: {'countryCode': auth.countryCode});
    final response = await _httpClient.post(
      uri,
      headers: {
        ...auth.apiHeaders,
        'Content-Type': 'application/x-www-form-urlencoded',
        ...?extraHeaders,
      },
      body: body,
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('POST failed: ${response.statusCode} ${response.body}');
    }
    return response;
  }

  Future<void> _post(String path, {Map<String, String>? body}) async {
    await _postRaw(path, body: body);
  }

  Future<void> _delete(String path) async {
    await auth.ensureValidToken();
    final uri = Uri.parse(
      '$_baseUrl$path',
    ).replace(queryParameters: {'countryCode': auth.countryCode});
    final response = await _httpClient.delete(uri, headers: auth.apiHeaders);
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('DELETE failed: ${response.statusCode} ${response.body}');
    }
  }
}
