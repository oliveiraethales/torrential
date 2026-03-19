import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../widgets/album_grid.dart';
import '../widgets/track_list.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Welcome back',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 24),

        // Recently favorited albums
        if (state.favoriteAlbums.isNotEmpty) ...[
          _SectionHeader(title: 'Your Albums'),
          const SizedBox(height: 12),
          AlbumGrid(
            albums: state.favoriteAlbums.take(12).toList(),
            onTap: (album) => state.selectAlbum(album),
          ),
          const SizedBox(height: 32),
        ],

        // Favorite tracks
        if (state.favoriteTracks.isNotEmpty) ...[
          _SectionHeader(title: 'Liked Tracks'),
          const SizedBox(height: 12),
          TrackList(
            tracks: state.favoriteTracks.take(10).toList(),
            onTap: (track, index) => state.playTrack(
              track,
              trackList: state.favoriteTracks,
              index: index,
            ),
          ),
        ],

        // Empty state
        if (state.favoriteAlbums.isEmpty && state.favoriteTracks.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 80),
              child: Column(
                children: [
                  Icon(Icons.library_music_outlined,
                      size: 64, color: Colors.white24),
                  const SizedBox(height: 16),
                  Text(
                    'Your library is empty',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white38,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Search for music and add it to your collection',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineMedium,
    );
  }
}
