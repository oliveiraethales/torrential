import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../../models/models.dart';
import '../widgets/album_grid.dart';
import '../widgets/track_list.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final query = context.read<AppState>().searchQuery;
    if (query.isNotEmpty) {
      _controller.text = query;
    } else {
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<AppState>().search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final results = state.searchResults;

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: _onSearchChanged,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Search artists, albums, tracks...',
              prefixIcon: const Icon(Icons.search, color: Colors.white38),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _controller.clear();
                        state.search('');
                      },
                    )
                  : null,
            ),
          ),
        ),

        // Results
        Expanded(
          child: results == null
              ? _buildEmptyState(context)
              : state.contentLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildResults(context, results, state),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            'Search for music',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white38,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(
      BuildContext context, SearchResults results, AppState state) {
    final hasArtists = results.artists.isNotEmpty;
    final hasAlbums = results.albums.isNotEmpty;
    final hasTracks = results.tracks.isNotEmpty;

    if (!hasArtists && !hasAlbums && !hasTracks) {
      return Center(
        child: Text(
          'No results found',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Artists
        if (hasArtists) ...[
          Text('Artists', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: results.artists.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final artist = results.artists[index];
                return _ArtistChip(
                  artist: artist,
                  onTap: () => state.selectArtist(artist),
                );
              },
            ),
          ),
          const SizedBox(height: 28),
        ],

        // Albums
        if (hasAlbums) ...[
          Text('Albums', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          AlbumGrid(
            albums: results.albums,
            onTap: (album) => state.selectAlbum(album),
          ),
          const SizedBox(height: 28),
        ],

        // Tracks
        if (hasTracks) ...[
          Text('Tracks', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          TrackList(
            tracks: results.tracks,
            onTap: (track, index) => state.playTrack(
              track,
              trackList: results.tracks,
              index: index,
            ),
          ),
        ],
      ],
    );
  }
}

class _ArtistChip extends StatelessWidget {
  final dynamic artist;
  final VoidCallback onTap;

  const _ArtistChip({required this.artist, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 100,
        child: Column(
          children: [
            CircleAvatar(
              radius: 42,
              backgroundColor: Colors.white10,
              backgroundImage: artist.imageUrl.isNotEmpty
                  ? NetworkImage(artist.imageUrl)
                  : null,
              child: artist.imageUrl.isEmpty
                  ? const Icon(Icons.person, size: 32)
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              artist.name,
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
