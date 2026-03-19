import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../widgets/album_grid.dart';
import '../widgets/track_list.dart';

class ArtistDetailScreen extends StatelessWidget {
  const ArtistDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final artist = state.selectedArtist;
    if (artist == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Artist header
        Row(
          children: [
            CircleAvatar(
              radius: 56,
              backgroundColor: Colors.white10,
              backgroundImage: artist.imageUrl.isNotEmpty
                  ? NetworkImage(artist.imageUrl)
                  : null,
              child: artist.imageUrl.isEmpty
                  ? const Icon(Icons.person, size: 48)
                  : null,
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Text(
                artist.name,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        if (state.contentLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          )
        else ...[
          // Top tracks
          if (state.selectedArtistTopTracks.isNotEmpty) ...[
            Text('Popular Tracks',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            TrackList(
              tracks: state.selectedArtistTopTracks.take(10).toList(),
              onTap: (track, index) => state.playTrack(
                track,
                trackList: state.selectedArtistTopTracks,
                index: index,
              ),
            ),
            const SizedBox(height: 32),
          ],

          // Albums
          if (state.selectedArtistAlbums.isNotEmpty) ...[
            Text('Albums',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            AlbumGrid(
              albums: state.selectedArtistAlbums,
              onTap: (album) => state.selectAlbum(album),
            ),
          ],
        ],
      ],
    );
  }
}
