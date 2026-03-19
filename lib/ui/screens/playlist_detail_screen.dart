import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../widgets/track_list.dart';

class PlaylistDetailScreen extends StatelessWidget {
  const PlaylistDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final playlist = state.selectedPlaylist;
    if (playlist == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: playlist.imageUrl.isNotEmpty
                  ? Image.network(
                      playlist.imageUrl,
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    playlist.title,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  if (playlist.description != null &&
                      playlist.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      playlist.description!,
                      style: Theme.of(context).textTheme.bodyLarge,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    '${playlist.numberOfTracks} tracks',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: state.selectedPlaylistTracks.isNotEmpty
                        ? () => state.playTrack(
                              state.selectedPlaylistTracks.first,
                              trackList: state.selectedPlaylistTracks,
                              index: 0,
                            )
                        : null,
                    icon: const Icon(Icons.play_arrow_rounded, size: 22),
                    label: const Text('Play'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
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
        else
          TrackList(
            tracks: state.selectedPlaylistTracks,
            showAlbum: true,
            onTap: (track, index) => state.playTrack(
              track,
              trackList: state.selectedPlaylistTracks,
              index: index,
            ),
          ),
      ],
    );
  }

  Widget _placeholder() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.playlist_play, size: 64, color: Colors.white24),
    );
  }
}
