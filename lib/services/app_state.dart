import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/tidal_auth.dart';
import '../core/tidal_api.dart';
import '../models/models.dart';

/// Navigation destinations in the app.
enum NavDestination {
  home,
  search,
  albums,
  artists,
  playlists,
}

/// Central app state managed via ChangeNotifier (Provider).
class AppState extends ChangeNotifier {
  final TidalAuth auth;
  late final TidalApi api;

  // ─── Auth state ─────────────────────────────────────────────────
  bool _isLoading = true;
  bool _isLoggingIn = false;
  String? _loginError;
  DeviceAuthResult? _deviceAuth;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => auth.isLoggedIn;
  bool get isLoggingIn => _isLoggingIn;
  String? get loginError => _loginError;
  DeviceAuthResult? get deviceAuth => _deviceAuth;

  // ─── Navigation ─────────────────────────────────────────────────
  NavDestination _currentNav = NavDestination.home;
  NavDestination get currentNav => _currentNav;

  // ─── Content state ──────────────────────────────────────────────
  SearchResults? _searchResults;
  List<Album> _favoriteAlbums = [];
  List<Artist> _favoriteArtists = [];
  List<Playlist> _userPlaylists = [];
  List<Track> _favoriteTracks = [];
  Album? _selectedAlbum;
  List<Track> _selectedAlbumTracks = [];
  Artist? _selectedArtist;
  List<Album> _selectedArtistAlbums = [];
  List<Track> _selectedArtistTopTracks = [];
  Playlist? _selectedPlaylist;
  List<Track> _selectedPlaylistTracks = [];
  bool _contentLoading = false;

  SearchResults? get searchResults => _searchResults;
  List<Album> get favoriteAlbums => _favoriteAlbums;
  List<Artist> get favoriteArtists => _favoriteArtists;
  List<Playlist> get userPlaylists => _userPlaylists;
  List<Track> get favoriteTracks => _favoriteTracks;
  Album? get selectedAlbum => _selectedAlbum;
  List<Track> get selectedAlbumTracks => _selectedAlbumTracks;
  Artist? get selectedArtist => _selectedArtist;
  List<Album> get selectedArtistAlbums => _selectedArtistAlbums;
  List<Track> get selectedArtistTopTracks => _selectedArtistTopTracks;
  Playlist? get selectedPlaylist => _selectedPlaylist;
  List<Track> get selectedPlaylistTracks => _selectedPlaylistTracks;
  bool get contentLoading => _contentLoading;

  // ─── Playback state ─────────────────────────────────────────────
  Track? _currentTrack;
  PlaybackInfo? _currentPlaybackInfo;
  List<Track> _queue = [];
  int _queueIndex = -1;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _totalDuration = Duration.zero;

  Track? get currentTrack => _currentTrack;
  PlaybackInfo? get currentPlaybackInfo => _currentPlaybackInfo;
  List<Track> get queue => _queue;
  int get queueIndex => _queueIndex;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get totalDuration => _totalDuration;

  // ─── Navigation history (for back navigation) ───────────────────
  final List<_NavState> _navHistory = [];

  AppState() : auth = TidalAuth() {
    api = TidalApi(auth: auth);
  }

  /// Initialize the app — try to restore session.
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    final restored = await auth.tryRestoreSession();
    if (restored) {
      // Load initial data
      await _loadFavorites();
    }

    _isLoading = false;
    notifyListeners();
  }

  // ─── Auth ───────────────────────────────────────────────────────

  Future<void> startLogin() async {
    _isLoggingIn = true;
    _loginError = null;
    notifyListeners();

    try {
      _deviceAuth = await auth.startDeviceAuth();
      notifyListeners();

      // Poll for completion
      while (_isLoggingIn) {
        await Future.delayed(Duration(seconds: _deviceAuth!.interval));
        try {
          final success = await auth.pollForToken(_deviceAuth!);
          if (success) {
            _isLoggingIn = false;
            _deviceAuth = null;
            await _loadFavorites();
            notifyListeners();
            return;
          }
        } catch (e) {
          _loginError = e.toString();
          _isLoggingIn = false;
          _deviceAuth = null;
          notifyListeners();
          return;
        }
      }
    } catch (e) {
      _loginError = e.toString();
      _isLoggingIn = false;
      notifyListeners();
    }
  }

  void cancelLogin() {
    _isLoggingIn = false;
    _deviceAuth = null;
    notifyListeners();
  }

  Future<void> logout() async {
    await auth.logout();
    _favoriteAlbums = [];
    _favoriteArtists = [];
    _userPlaylists = [];
    _favoriteTracks = [];
    _currentTrack = null;
    _queue = [];
    _searchResults = null;
    notifyListeners();
  }

  // ─── Navigation ─────────────────────────────────────────────────

  void navigateTo(NavDestination dest) {
    if (dest != _currentNav) {
      _navHistory.add(_NavState(
        nav: _currentNav,
        album: _selectedAlbum,
        artist: _selectedArtist,
        playlist: _selectedPlaylist,
      ));
      _currentNav = dest;
      _selectedAlbum = null;
      _selectedArtist = null;
      _selectedPlaylist = null;
      notifyListeners();
    }
  }

  bool get canGoBack => _navHistory.isNotEmpty || _selectedAlbum != null || _selectedArtist != null || _selectedPlaylist != null;

  void goBack() {
    if (_selectedAlbum != null || _selectedArtist != null || _selectedPlaylist != null) {
      _selectedAlbum = null;
      _selectedArtist = null;
      _selectedPlaylist = null;
      notifyListeners();
      return;
    }
    if (_navHistory.isNotEmpty) {
      final prev = _navHistory.removeLast();
      _currentNav = prev.nav;
      _selectedAlbum = prev.album;
      _selectedArtist = prev.artist;
      _selectedPlaylist = prev.playlist;
      notifyListeners();
    }
  }

  // ─── Content loading ────────────────────────────────────────────

  Future<void> _loadFavorites() async {
    try {
      final results = await Future.wait([
        api.getFavoriteAlbums(),
        api.getFavoriteArtists(),
        api.getUserPlaylists(),
        api.getFavoriteTracks(),
      ]);
      _favoriteAlbums = results[0] as List<Album>;
      _favoriteArtists = results[1] as List<Artist>;
      _userPlaylists = results[2] as List<Playlist>;
      _favoriteTracks = results[3] as List<Track>;
    } catch (e) {
      debugPrint('Failed to load favorites: $e');
    }
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = null;
      notifyListeners();
      return;
    }
    _contentLoading = true;
    notifyListeners();

    try {
      _searchResults = await api.search(query);
    } catch (e) {
      debugPrint('Search failed: $e');
    }

    _contentLoading = false;
    notifyListeners();
  }

  Future<void> selectAlbum(Album album) async {
    _selectedAlbum = album;
    _contentLoading = true;
    notifyListeners();

    try {
      final fullAlbum = await api.getAlbum(album.id);
      _selectedAlbum = fullAlbum;
      _selectedAlbumTracks = await api.getAlbumTracks(album.id);
    } catch (e) {
      debugPrint('Failed to load album: $e');
    }

    _contentLoading = false;
    notifyListeners();
  }

  Future<void> selectArtist(Artist artist) async {
    _selectedArtist = artist;
    _contentLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        api.getArtistAlbums(artist.id),
        api.getArtistTopTracks(artist.id),
      ]);
      _selectedArtistAlbums = results[0] as List<Album>;
      _selectedArtistTopTracks = results[1] as List<Track>;
    } catch (e) {
      debugPrint('Failed to load artist: $e');
    }

    _contentLoading = false;
    notifyListeners();
  }

  Future<void> selectPlaylist(Playlist playlist) async {
    _selectedPlaylist = playlist;
    _contentLoading = true;
    notifyListeners();

    try {
      _selectedPlaylistTracks = await api.getPlaylistTracks(playlist.uuid);
    } catch (e) {
      debugPrint('Failed to load playlist: $e');
    }

    _contentLoading = false;
    notifyListeners();
  }

  // ─── Playback ───────────────────────────────────────────────────

  Future<void> playTrack(Track track, {List<Track>? trackList, int? index}) async {
    _currentTrack = track;
    if (trackList != null) {
      _queue = List.from(trackList);
      _queueIndex = index ?? 0;
    }
    notifyListeners();

    try {
      _currentPlaybackInfo = await api.getPlaybackInfo(track.id);
      _totalDuration = Duration(seconds: track.duration);
      _isPlaying = true;
      notifyListeners();
      // TODO: Actually start audio playback via media_kit
    } catch (e) {
      debugPrint('Failed to get playback info: $e');
    }
  }

  void togglePlayPause() {
    _isPlaying = !_isPlaying;
    notifyListeners();
    // TODO: Toggle actual playback
  }

  Future<void> playNext() async {
    if (_queue.isEmpty) return;
    if (_queueIndex < _queue.length - 1) {
      _queueIndex++;
      await playTrack(_queue[_queueIndex], trackList: _queue, index: _queueIndex);
    }
  }

  Future<void> playPrevious() async {
    if (_queue.isEmpty) return;
    if (_queueIndex > 0) {
      _queueIndex--;
      await playTrack(_queue[_queueIndex], trackList: _queue, index: _queueIndex);
    }
  }

  void updatePosition(Duration position) {
    _position = position;
    notifyListeners();
  }
}

class _NavState {
  final NavDestination nav;
  final Album? album;
  final Artist? artist;
  final Playlist? playlist;

  _NavState({required this.nav, this.album, this.artist, this.playlist});
}
